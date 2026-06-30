import 'package:freezed_annotation/freezed_annotation.dart';

part 'ai_provider_config.freezed.dart';
part 'ai_provider_config.g.dart';

/// Supported AI back ends. OpenAI and DeepSeek removed (paid only);
/// NVIDIA NIM, Cerebras, and SambaNova added as genuinely free alternatives.
enum AiProviderType {
  gemini('Gemini'),
  groq('Groq'),
  openrouter('OpenRouter'),
  nvidia('NVIDIA NIM'),
  cerebras('Cerebras'),
  sambanova('SambaNova'),
  huggingface('Hugging Face');

  const AiProviderType(this.label);
  final String label;
}

/// Runtime configuration for a provider. The API key itself is NOT stored here
/// — it lives only in secure storage and is fetched at call time.
@freezed
class AiProviderConfig with _$AiProviderConfig {
  const factory AiProviderConfig({
    required AiProviderType type,
    required String model,
    String? embeddingModel,
    @Default(0.4) double temperature,
    @Default(4096) int maxTokens,
    @Default(true) bool enabled,
  }) = _AiProviderConfig;

  factory AiProviderConfig.fromJson(Map<String, dynamic> json) =>
      _$AiProviderConfigFromJson(json);

  /// Sensible, tested defaults per provider — all free tier.
  static AiProviderConfig defaults(AiProviderType type) => switch (type) {
        AiProviderType.gemini => const AiProviderConfig(
            type: AiProviderType.gemini,
            model: 'gemini-2.5-flash',
            embeddingModel: 'text-embedding-004',
            temperature: 0.35,
            maxTokens: 8192,
          ),
        AiProviderType.groq => const AiProviderConfig(
            type: AiProviderType.groq,
            model: 'openai/gpt-oss-20b',
            temperature: 0.60,
            maxTokens: 4096,
          ),
        AiProviderType.openrouter => const AiProviderConfig(
            type: AiProviderType.openrouter,
            model: 'deepseek/deepseek-r1:free',
            temperature: 0.35,
            maxTokens: 4096,
          ),
        AiProviderType.nvidia => const AiProviderConfig(
            type: AiProviderType.nvidia,
            model: 'meta/llama-3.3-70b-instruct',
            temperature: 0.35,
            maxTokens: 4096,
          ),
        AiProviderType.cerebras => const AiProviderConfig(
            type: AiProviderType.cerebras,
            model: 'llama-3.3-70b',
            temperature: 0.35,
            maxTokens: 4096,
          ),
        AiProviderType.sambanova => const AiProviderConfig(
            type: AiProviderType.sambanova,
            model: 'Meta-Llama-3.3-70B-Instruct',
            temperature: 0.35,
            maxTokens: 4096,
          ),
        AiProviderType.huggingface => const AiProviderConfig(
            type: AiProviderType.huggingface,
            model: 'meta-llama/Llama-3.3-70B-Instruct',
            temperature: 0.35,
            maxTokens: 4096,
          ),
      };
}
