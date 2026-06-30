import 'package:dio/dio.dart';

import '../../models/ai_provider_config.dart';
import 'openai_provider.dart';

/// SambaNova — permanent free tier + $5 starter credits. 20 RPM, 200K TPD.
/// Reliable and stable, good fallback provider. No credit card required.
class SambanovaProvider extends OpenAiProvider {
  SambanovaProvider({Dio? dio})
      : super(
          dio: dio,
          baseUrl: 'https://api.sambanova.ai/v1',
          type: AiProviderType.sambanova,
          displayName: 'SambaNova',
        );
}
