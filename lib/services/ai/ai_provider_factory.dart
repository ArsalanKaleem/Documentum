import '../../models/ai_provider_config.dart';
import 'ai_provider.dart';
import 'cerebras_provider.dart';
import 'gemini_provider.dart';
import 'groq_provider.dart';
import 'huggingface_provider.dart';
import 'nvidia_provider.dart';
import 'openrouter_provider.dart';
import 'sambanova_provider.dart';

/// Resolves an [AiProviderType] to a concrete [AiProvider]. Instances are
/// cached so the underlying Dio client is reused across calls.
class AiProviderFactory {
  final Map<AiProviderType, AiProvider> _cache = {};

  AiProvider resolve(AiProviderType type) =>
      _cache.putIfAbsent(type, () => _create(type));

  AiProvider _create(AiProviderType type) => switch (type) {
        AiProviderType.gemini => GeminiProvider(),
        AiProviderType.groq => GroqProvider(),
        AiProviderType.openrouter => OpenRouterProvider(),
        AiProviderType.nvidia => NvidiaProvider(),
        AiProviderType.cerebras => CerebrasProvider(),
        AiProviderType.sambanova => SambanovaProvider(),
        AiProviderType.huggingface => HuggingFaceProvider(),
      };
}
