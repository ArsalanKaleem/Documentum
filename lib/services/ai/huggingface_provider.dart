import 'package:dio/dio.dart';

import '../../models/ai_provider_config.dart';
import 'openai_provider.dart';

/// Hugging Face Inference Providers — a single OpenAI-compatible router that
/// fans out to many backends (Cerebras, Together, Fireworks, etc.). One token
/// gives access to DeepSeek, Llama, Qwen, GPT-OSS, and more. Model IDs use the
/// `org/model` form and may carry a `:provider` suffix (e.g. `:cerebras`) or a
/// routing policy (`:fastest`, `:cheapest`).
class HuggingFaceProvider extends OpenAiProvider {
  HuggingFaceProvider({Dio? dio})
      : super(
          dio: dio,
          baseUrl: 'https://router.huggingface.co/v1',
          type: AiProviderType.huggingface,
          displayName: 'Hugging Face',
        );
}
