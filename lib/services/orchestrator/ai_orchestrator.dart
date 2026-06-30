import 'dart:async';

import '../../core/errors/failures.dart';
import '../../core/utils/cancellation.dart';
import '../../models/agent_provider_config.dart';
import '../../models/ai_provider_config.dart';
import '../../models/generated_doc.dart';
import '../../models/project_context.dart';
import '../../models/source_file.dart';
import '../ai/ai_provider.dart';
import '../ai/ai_provider_factory.dart';
import 'agents/doc_agent.dart';
import 'agents/process_agents.dart';
import 'agents/recommendations_agent.dart';
import 'agents/structure_agents.dart';

/// Reads the API key for a provider from secure storage. Injected so the
/// orchestrator never touches storage directly.
typedef ApiKeyReader = Future<String?> Function(AiProviderType type);

/// Resolves the [AiProviderConfig] to use for a given [DocType]. Lets each
/// agent run on a different provider/model.
typedef ConfigResolver = AiProviderConfig Function(DocType type);

/// The central coordinator of the multi-agent pipeline.
///
/// Context creation is done upstream by the analyzer; the orchestrator handles
/// agent routing, per-agent provider selection, prompt building (delegated to
/// agents), result aggregation, independent retry/error handling, and
/// cancellation. Every agent reads the single shared [ProjectContext]; the
/// project is never re-analyzed.
class AiOrchestrator {
  AiOrchestrator({
    required AiProviderFactory factory,
    required ApiKeyReader apiKeyReader,
    List<DocAgent>? agents,
    this.maxRetries = 5,
    this.staggerMs = 350,
  })  : _factory = factory,
        _readKey = apiKeyReader,
        _agents = agents ?? defaultAgents();

  final AiProviderFactory _factory;
  final ApiKeyReader _readKey;
  final List<DocAgent> _agents;
  final int maxRetries;

  /// Delay between launching each agent, to smooth bursts against free-tier
  /// per-minute/per-second limits while still running concurrently.
  final int staggerMs;

  static List<DocAgent> defaultAgents() => [
        ReadmeAgent(),
        ApiAgent(),
        ArchitectureAgent(),
        InstallationAgent(),
        ContributingAgent(),
        ChangelogAgent(),
        RecommendationsAgent(),
      ];

  List<DocType> get availableDocTypes =>
      _agents.map((a) => a.docType).toList();

  /// Runs every agent **in parallel**, each on its own provider, and yields a
  /// [GeneratedDoc] update as each transitions state. A "generating" event is
  /// emitted up-front for all agents, then a completed/failed/cancelled event
  /// as each finishes. One agent failing never affects the others.
  Stream<GeneratedDoc> generateAll({
    required ProjectContext context,
    required List<SourceFile> files,
    required ConfigResolver configFor,
    CancellationToken? cancel,
  }) {
    final controller = StreamController<GeneratedDoc>();
    final token = cancel ?? CancellationToken();

    // Emit an initial "generating" event for each agent with its assigned
    // provider so the UI can render the full roster immediately.
    for (final agent in _agents) {
      controller.add(GeneratedDoc(
        type: agent.docType,
        status: DocStatus.generating,
        assignedProvider: configFor(agent.docType).type,
      ));
    }

    final futures = _agents.indexed.map((entry) async {
      final (index, agent) = entry;
      final config = configFor(agent.docType);
      // Stagger launches so we don't hit a provider with N simultaneous calls.
      if (staggerMs > 0 && index > 0) {
        await Future<void>.delayed(Duration(milliseconds: staggerMs * index));
      }
      if (token.isCancelled) {
        controller.add(GeneratedDoc(
          type: agent.docType,
          status: DocStatus.cancelled,
          assignedProvider: config.type,
        ));
        return;
      }
      try {
        final doc = await _runAgent(agent, context, files, config, token);
        controller.add(doc);
      } on CancelledException {
        controller.add(GeneratedDoc(
          type: agent.docType,
          status: DocStatus.cancelled,
          assignedProvider: config.type,
        ));
      } on AppFailure catch (e) {
        controller.add(GeneratedDoc(
          type: agent.docType,
          status: DocStatus.failed,
          error: e.message,
          assignedProvider: config.type,
        ));
      } catch (e) {
        controller.add(GeneratedDoc(
          type: agent.docType,
          status: DocStatus.failed,
          error: e.toString(),
          assignedProvider: config.type,
        ));
      }
    }).toList();

    // Close the stream once every agent settles.
    unawaited(Future.wait(futures).whenComplete(controller.close));

    return controller.stream;
  }

  /// Generates a single document by [DocType] on the given provider config.
  Future<GeneratedDoc> generateOne({
    required DocType type,
    required ProjectContext context,
    required List<SourceFile> files,
    required AiProviderConfig config,
    CancellationToken? cancel,
  }) {
    final agent = _agents.firstWhere(
      (a) => a.docType == type,
      orElse: () => throw AnalysisFailure('No agent for $type'),
    );
    return _runAgent(agent, context, files, config, cancel ?? CancellationToken());
  }

  Future<GeneratedDoc> _runAgent(
    DocAgent agent,
    ProjectContext context,
    List<SourceFile> files,
    AiProviderConfig config,
    CancellationToken token,
  ) async {
    final sw = Stopwatch()..start();
    final messages = agent.buildMessages(context, files);
    final result = await _completeWithRetry(messages, config, token);
    sw.stop();
    return GeneratedDoc(
      type: agent.docType,
      content: result.completion.text,
      status: DocStatus.completed,
      providerUsed: result.completion.providerLabel,
      assignedProvider: config.type,
      tokensUsed: result.completion.totalTokens,
      elapsedMs: sw.elapsedMilliseconds,
      retries: result.retries,
      generatedAt: DateTime.now(),
    );
  }

  /// Calls the provider with exponential backoff on rate limits and transient
  /// 5xx errors. Retries are independent per agent. Returns the completion plus
  /// the number of retries performed.
  Future<({AiCompletion completion, int retries})> _completeWithRetry(
    List<AiMessage> messages,
    AiProviderConfig config,
    CancellationToken token,
  ) async {
    if (token.isCancelled) throw const CancelledException();
    final key = await _readKey(config.type);
    if (key == null || key.isEmpty) {
      throw ConfigFailure('No API key set for ${config.type.label}.');
    }
    final provider = _factory.resolve(config.type);

    var attempt = 0;
    while (true) {
      if (token.isCancelled) throw const CancelledException();
      attempt++;
      try {
        final completion = await provider.complete(
          messages: messages,
          config: config,
          apiKey: key,
        );
        return (completion: completion, retries: attempt - 1);
      } on AiFailure catch (e) {
        final retriable = e.isRateLimit || (e.statusCode ?? 0) >= 500;
        if (!retriable || attempt > maxRetries) rethrow;
        // Honor Retry-After when present (capped), else exponential backoff.
        final backoffMs = 600 * (1 << (attempt - 1)); // 0.6s,1.2s,2.4s,4.8s…
        final serverMs = (e.retryAfterSeconds ?? 0) * 1000;
        final waitMs = serverMs > 0
            ? (serverMs.clamp(0, 30000))
            : backoffMs.clamp(0, 15000);
        await Future<void>.delayed(Duration(milliseconds: waitMs));
      }
    }
  }
}
