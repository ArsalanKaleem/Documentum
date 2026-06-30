import 'package:flutter_test/flutter_test.dart';
import 'package:smart_docs_generator/models/agent_provider_config.dart';
import 'package:smart_docs_generator/models/ai_provider_config.dart';
import 'package:smart_docs_generator/models/generated_doc.dart';

void main() {
  group('AgentProviderConfig', () {
    test('explicit assignments are returned by providerFor', () {
      const cfg = AgentProviderConfig(
        readmeProvider: AiProviderType.gemini,
        apiProvider: AiProviderType.gemini,
        architectureProvider: AiProviderType.groq,
      );
      expect(cfg.providerFor(DocType.readme), AiProviderType.gemini);
      expect(cfg.providerFor(DocType.api), AiProviderType.gemini);
      expect(cfg.providerFor(DocType.architecture), AiProviderType.groq);
    });

    test('auto mode overrides explicit assignments with the auto route', () {
      const cfg = AgentProviderConfig(
        readmeProvider: AiProviderType.groq, // would be gemini in auto
        autoMode: true,
      );
      expect(cfg.providerFor(DocType.readme),
          AgentProviderConfig.autoRoute[DocType.readme]);
      expect(cfg.providerFor(DocType.api), AiProviderType.nvidia);
      expect(cfg.providerFor(DocType.changelog), AiProviderType.cerebras);
    });

    test('assign returns a copy with only the targeted agent changed', () {
      const cfg = AgentProviderConfig();
      final updated = cfg.assign(DocType.changelog, AiProviderType.openrouter);
      expect(updated.changelogProvider, AiProviderType.openrouter);
      expect(updated.readmeProvider, cfg.readmeProvider);
    });

    test('usedProviders collects the distinct providers in use', () {
      const cfg = AgentProviderConfig(
        readmeProvider: AiProviderType.gemini,
        apiProvider: AiProviderType.gemini,
        architectureProvider: AiProviderType.gemini,
        installationProvider: AiProviderType.gemini,
        contributingProvider: AiProviderType.gemini,
        changelogProvider: AiProviderType.groq,
      );
      expect(cfg.usedProviders, {
        AiProviderType.gemini,
        AiProviderType.gemini,
        AiProviderType.groq,
      });
    });
  });
}
