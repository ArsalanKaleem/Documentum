import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/utils/cancellation.dart';
import '../models/ai_provider_config.dart';
import '../models/generated_doc.dart';
import '../services/orchestrator/ai_orchestrator.dart';
import 'coordination_providers.dart';
import 'project_providers.dart';
import 'service_providers.dart';
import 'settings_providers.dart';

/// Holds the map of [DocType] → [GeneratedDoc] for the active project and
/// drives the parallel, multi-provider generation pipeline.
class DocumentationNotifier extends Notifier<Map<DocType, GeneratedDoc>> {
  CancellationToken? _cancel;

  @override
  Map<DocType, GeneratedDoc> build() {
    final project = ref.watch(projectControllerProvider).valueOrNull;
    final map = <DocType, GeneratedDoc>{};
    for (final type in DocType.values) {
      map[type] = GeneratedDoc(type: type);
    }
    if (project != null) {
      for (final d in project.docs) {
        map[d.type] = d;
      }
    }
    return map;
  }

  bool get isGenerating =>
      state.values.any((d) => d.status == DocStatus.generating);

  /// Builds a synchronous per-agent config resolver from the saved settings.
  /// Loads each used provider's config once up-front.
  Future<ConfigResolver> _buildResolver() async {
    final settings = ref.read(settingsProvider).valueOrNull;
    final repo = ref.read(settingsRepositoryProvider);
    final agentConfig = settings?.agentConfig;

    final byProvider = <AiProviderType, AiProviderConfig>{};
    for (final type in AiProviderType.values) {
      byProvider[type] = await repo.getConfig(type);
    }

    return (DocType docType) {
      final provider = agentConfig?.providerFor(docType) ??
          settings?.activeProvider ??
          AiProviderType.gemini;
      return byProvider[provider] ?? AiProviderConfig.defaults(provider);
    };
  }

  /// Runs every agent in parallel, each on its assigned provider.
  Future<void> generateAll() async {
    final project = ref.read(projectControllerProvider).valueOrNull;
    if (project == null) return;

    final resolver = await _buildResolver();
    final token = CancellationToken();
    _cancel = token;

    final stream = ref.read(orchestratorProvider).generateAll(
          context: project.context,
          files: project.files,
          configFor: resolver,
          cancel: token,
        );

    await for (final doc in stream) {
      state = {...state, doc.type: doc};
    }
    _cancel = null;
    _persist();
    await ref.read(coordinationProvider.notifier).recordCycle(state.values.toList());
  }

  /// Cancels an in-progress generation cycle (cooperative).
  void cancel() => _cancel?.cancel();

  /// Regenerates a single document on its assigned provider.
  Future<void> regenerate(DocType type) async {
    final project = ref.read(projectControllerProvider).valueOrNull;
    if (project == null) return;

    final resolver = await _buildResolver();
    state = {
      ...state,
      type: GeneratedDoc(
        type: type,
        status: DocStatus.generating,
        assignedProvider: resolver(type).type,
      ),
    };
    try {
      final doc = await ref.read(orchestratorProvider).generateOne(
            type: type,
            context: project.context,
            files: project.files,
            config: resolver(type),
          );
      state = {...state, type: doc};
    } catch (e) {
      state = {
        ...state,
        type: GeneratedDoc(
          type: type,
          status: DocStatus.failed,
          error: e.toString(),
        ),
      };
    }
    _persist();
  }

  /// Applies a manual edit to a document's content.
  void edit(DocType type, String content) {
    final existing = state[type]!;
    state = {
      ...state,
      type: existing.copyWith(content: content, status: DocStatus.completed),
    };
    _persist();
  }

  void _persist() {
    final controller = ref.read(projectControllerProvider.notifier);
    final project = ref.read(projectControllerProvider).valueOrNull;
    if (project == null) return;
    controller.setProject(
      project.copyWith(
        docs: state.values.toList(),
        updatedAt: DateTime.now(),
      ),
    );
  }
}

final documentationProvider =
    NotifierProvider<DocumentationNotifier, Map<DocType, GeneratedDoc>>(
  DocumentationNotifier.new,
);
