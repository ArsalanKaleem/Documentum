import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../models/chat_message.dart';
import '../services/ai/ai_provider.dart';
import 'documentation_providers.dart';
import 'project_providers.dart';
import 'service_providers.dart';
import 'settings_providers.dart';

class ChatState {
  const ChatState({
    this.messages = const [],
    this.isIndexing = false,
    this.isResponding = false,
    this.indexed = false,
  });

  final List<ChatMessage> messages;
  final bool isIndexing;
  final bool isResponding;
  final bool indexed;

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isIndexing,
    bool? isResponding,
    bool? indexed,
  }) =>
      ChatState(
        messages: messages ?? this.messages,
        isIndexing: isIndexing ?? this.isIndexing,
        isResponding: isResponding ?? this.isResponding,
        indexed: indexed ?? this.indexed,
      );
}

/// Drives the Retrieval-Augmented Generation chat over the codebase + docs.
class ChatNotifier extends Notifier<ChatState> {
  final _uuid = const Uuid();

  @override
  ChatState build() => const ChatState();

  /// Builds the RAG index from source files and generated docs. Safe to call
  /// repeatedly; only indexes once unless [force] is set.
  Future<void> ensureIndexed({bool force = false}) async {
    if (state.indexed && !force) return;
    final project = ref.read(projectControllerProvider).valueOrNull;
    final settings = ref.read(settingsProvider).valueOrNull;
    if (project == null || settings == null) return;

    state = state.copyWith(isIndexing: true);
    final embedding = ref.read(embeddingServiceProvider);
    final docs =
        ref.read(documentationProvider).values.toList();
    final apiKey = await ref
        .read(settingsRepositoryProvider)
        .getApiKey(settings.config.type);

    await embedding.indexProject(
      files: project.files,
      docs: docs,
      config: settings.config,
      apiKey: apiKey,
    );
    state = state.copyWith(isIndexing: false, indexed: true);
  }

  Future<void> send(String question) async {
    final trimmed = question.trim();
    if (trimmed.isEmpty || state.isResponding) return;

    final settings = ref.read(settingsProvider).valueOrNull;
    final project = ref.read(projectControllerProvider).valueOrNull;
    if (settings == null || project == null) return;

    await ensureIndexed();

    final userMsg = ChatMessage(
      id: _uuid.v4(),
      role: ChatRole.user,
      content: trimmed,
      createdAt: DateTime.now(),
    );
    final assistantId = _uuid.v4();
    state = state.copyWith(
      messages: [
        ...state.messages,
        userMsg,
        ChatMessage(
          id: assistantId,
          role: ChatRole.assistant,
          content: '',
          isStreaming: true,
          createdAt: DateTime.now(),
        ),
      ],
      isResponding: true,
    );

    try {
      final apiKey = await ref
          .read(settingsRepositoryProvider)
          .getApiKey(settings.config.type);
      final retrieved = await ref.read(embeddingServiceProvider).search(
            trimmed,
            k: 6,
            config: settings.config,
            apiKey: apiKey,
          );
      final sources =
          retrieved.map((r) => r.chunk.source).toSet().toList();

      final contextBlock = retrieved
          .map((r) => 'FILE: ${r.chunk.source}\n${r.chunk.text}')
          .join('\n\n---\n\n');

      final messages = <AiMessage>[
        AiMessage.system(
          'You are a senior engineer answering questions about a specific '
          'codebase. Use ONLY the provided snippets and project context. If the '
          'answer is not in them, say so. Cite file paths when relevant.\n\n'
          '${project.context.summary}',
        ),
        AiMessage.user(
          'Project context snippets:\n$contextBlock\n\nQuestion: $trimmed',
        ),
      ];

      final provider =
          ref.read(aiProviderFactoryProvider).resolve(settings.config.type);
      final buffer = StringBuffer();

      if (apiKey != null && apiKey.isNotEmpty) {
        await for (final chunk in provider.streamComplete(
          messages: messages,
          config: settings.config,
          apiKey: apiKey,
        )) {
          buffer.write(chunk);
          _updateAssistant(assistantId, buffer.toString(), sources, true);
        }
      } else {
        buffer.write('No API key configured. Add one in Settings to chat.');
      }
      _updateAssistant(assistantId, buffer.toString(), sources, false);
    } catch (e) {
      _updateAssistant(assistantId, 'Error: $e', const [], false);
    } finally {
      state = state.copyWith(isResponding: false);
    }
  }

  void _updateAssistant(
    String id,
    String content,
    List<String> sources,
    bool streaming,
  ) {
    state = state.copyWith(
      messages: [
        for (final m in state.messages)
          if (m.id == id)
            m.copyWith(
              content: content,
              sources: sources,
              isStreaming: streaming,
            )
          else
            m,
      ],
    );
  }

  void clear() => state = const ChatState();
}

final chatProvider =
    NotifierProvider<ChatNotifier, ChatState>(ChatNotifier.new);
