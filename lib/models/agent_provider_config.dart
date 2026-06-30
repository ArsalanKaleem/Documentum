import 'package:freezed_annotation/freezed_annotation.dart';

import 'ai_provider_config.dart';
import 'generated_doc.dart';

part 'agent_provider_config.freezed.dart';
part 'agent_provider_config.g.dart';

/// Per-agent provider assignment. Defaults spread load across Gemini, NVIDIA
/// NIM, and Cerebras — the three most generous free tiers — to avoid hitting
/// any single provider's rate limit during parallel generation.
@freezed
class AgentProviderConfig with _$AgentProviderConfig {
  const AgentProviderConfig._();

  const factory AgentProviderConfig({
    @Default(AiProviderType.gemini) AiProviderType readmeProvider,
    @Default(AiProviderType.nvidia) AiProviderType apiProvider,
    @Default(AiProviderType.cerebras) AiProviderType architectureProvider,
    @Default(AiProviderType.gemini) AiProviderType installationProvider,
    @Default(AiProviderType.nvidia) AiProviderType contributingProvider,
    @Default(AiProviderType.cerebras) AiProviderType changelogProvider,
    @Default(AiProviderType.gemini) AiProviderType recommendationsProvider,
    @Default(false) bool autoMode,
  }) = _AgentProviderConfig;

  factory AgentProviderConfig.fromJson(Map<String, dynamic> json) =>
      _$AgentProviderConfigFromJson(json);

  /// Auto-routing spreads load across the three most generous free providers.
  /// Gemini: 500 RPD, best quality. NVIDIA NIM: 200K TPD, very reliable.
  /// Cerebras: 1M TPD, fastest. Groq: fast but lower TPM limits.
  static const Map<DocType, AiProviderType> autoRoute = {
    DocType.readme: AiProviderType.gemini,
    DocType.api: AiProviderType.nvidia,
    DocType.architecture: AiProviderType.cerebras,
    DocType.installation: AiProviderType.gemini,
    DocType.contributing: AiProviderType.nvidia,
    DocType.changelog: AiProviderType.cerebras,
    DocType.recommendations: AiProviderType.gemini,
  };

  AiProviderType providerFor(DocType type) {
    if (autoMode) return autoRoute[type]!;
    return switch (type) {
      DocType.readme => readmeProvider,
      DocType.api => apiProvider,
      DocType.architecture => architectureProvider,
      DocType.installation => installationProvider,
      DocType.contributing => contributingProvider,
      DocType.changelog => changelogProvider,
      DocType.recommendations => recommendationsProvider,
    };
  }

  AgentProviderConfig assign(DocType type, AiProviderType provider) {
    return switch (type) {
      DocType.readme => copyWith(readmeProvider: provider),
      DocType.api => copyWith(apiProvider: provider),
      DocType.architecture => copyWith(architectureProvider: provider),
      DocType.installation => copyWith(installationProvider: provider),
      DocType.contributing => copyWith(contributingProvider: provider),
      DocType.changelog => copyWith(changelogProvider: provider),
      DocType.recommendations => copyWith(recommendationsProvider: provider),
    };
  }

  Set<AiProviderType> get usedProviders =>
      {for (final t in DocType.values) providerFor(t)};
}
