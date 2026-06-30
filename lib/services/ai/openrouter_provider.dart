import 'package:dio/dio.dart';

import '../../models/ai_provider_config.dart';
import 'openai_provider.dart';

/// OpenRouter is an OpenAI-compatible gateway to many models. Model strings are
/// namespaced (e.g. `openai/gpt-4o-mini`, `anthropic/claude-3.5-sonnet`).
class OpenRouterProvider extends OpenAiProvider {
  OpenRouterProvider({Dio? dio})
      : super(
          dio: dio,
          baseUrl: 'https://openrouter.ai/api/v1',
          type: AiProviderType.openrouter,
          displayName: 'OpenRouter',
          extraHeaders: const {
            // Optional attribution headers recommended by OpenRouter.
            'HTTP-Referer': 'https://smart-docs-generator.app',
            'X-Title': 'Smart Documentation Generator',
          },
        );
}
