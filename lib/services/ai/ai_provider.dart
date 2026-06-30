import '../../models/ai_provider_config.dart';

/// A single chat message sent to a provider.
class AiMessage {
  const AiMessage(this.role, this.content);
  const AiMessage.system(this.content) : role = 'system';
  const AiMessage.user(this.content) : role = 'user';
  const AiMessage.assistant(this.content) : role = 'assistant';

  final String role; // 'system' | 'user' | 'assistant'
  final String content;
}

/// Result of a non-streaming completion.
class AiCompletion {
  const AiCompletion({
    required this.text,
    required this.providerLabel,
    this.totalTokens,
  });
  final String text;
  final String providerLabel;

  /// Total tokens reported by the provider's usage block, when present.
  final int? totalTokens;
}

/// Provider-agnostic contract. Each concrete provider adapts the unified
/// request shape to its own HTTP API. Implementations must NOT hold the API key
/// — it is passed per-call so it can be read from secure storage on demand.
abstract interface class AiProvider {
  AiProviderType get type;

  /// One-shot completion.
  Future<AiCompletion> complete({
    required List<AiMessage> messages,
    required AiProviderConfig config,
    required String apiKey,
  });

  /// Streaming completion. Yields incremental text chunks.
  Stream<String> streamComplete({
    required List<AiMessage> messages,
    required AiProviderConfig config,
    required String apiKey,
  });

  /// Returns embedding vectors for [inputs]. Providers without embedding
  /// support should throw [UnsupportedError]; callers fall back to a local
  /// lexical index.
  Future<List<List<double>>> embed({
    required List<String> inputs,
    required AiProviderConfig config,
    required String apiKey,
  });
}
