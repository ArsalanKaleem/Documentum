import 'package:dio/dio.dart';

import '../../models/ai_provider_config.dart';
import 'openai_provider.dart';

/// NVIDIA NIM — 100+ open models, OpenAI-compatible, 40 RPM, 200K tokens/day.
/// No credit card required. Free tier is very generous for doc generation.
class NvidiaProvider extends OpenAiProvider {
  NvidiaProvider({Dio? dio})
      : super(
          dio: dio,
          baseUrl: 'https://integrate.api.nvidia.com/v1',
          type: AiProviderType.nvidia,
          displayName: 'NVIDIA NIM',
        );
}
