import 'package:dio/dio.dart';

import '../../models/ai_provider_config.dart';
import 'openai_provider.dart';

/// Cerebras — ultra-fast WSE chip inference, 1M tokens/day free.
/// The most generous token budget of any free provider. No credit card.
class CerebrasProvider extends OpenAiProvider {
  CerebrasProvider({Dio? dio})
      : super(
          dio: dio,
          baseUrl: 'https://api.cerebras.ai/v1',
          type: AiProviderType.cerebras,
          displayName: 'Cerebras',
        );
}
