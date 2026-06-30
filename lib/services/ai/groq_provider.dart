import 'package:dio/dio.dart';

import '../../models/ai_provider_config.dart';
import 'ai_provider.dart';
import 'openai_provider.dart';

/// Groq exposes an OpenAI-compatible API, but its newer models need special
/// handling:
///  - qwen3 / gpt-oss models require `max_completion_tokens` (not `max_tokens`).
///  - gpt-oss models are REASONING models: they spend output tokens "thinking"
///    before answering. With a small token budget and a large prompt, all the
///    budget is consumed by reasoning and `content` comes back empty. We send
///    `reasoning_effort: low` to minimize that, and fall back to the `reasoning`
///    field (with any <think> wrapper stripped) if `content` is still empty.
class GroqProvider extends OpenAiProvider {
  GroqProvider({Dio? dio})
      : super(
          dio: dio,
          baseUrl: 'https://api.groq.com/openai/v1',
          type: AiProviderType.groq,
          displayName: 'Groq',
        );

  static bool _needsCompletionTokens(String model) =>
      model.startsWith('qwen/') ||
      model.startsWith('openai/') ||
      model.contains('qwen3') ||
      model.contains('gpt-oss');

  static bool _isReasoning(String model) =>
      model.contains('gpt-oss') ||
      model.contains('qwen3') ||
      model.contains('deepseek-r1') ||
      model.contains('reasoning');

  Map<String, dynamic> _body(AiProviderConfig config, List<AiMessage> messages,
      {bool stream = false}) {
    final tokenKey = _needsCompletionTokens(config.model)
        ? 'max_completion_tokens'
        : 'max_tokens';
    return {
      'model': config.model,
      'temperature': config.temperature,
      tokenKey: config.maxTokens,
      // Keep reasoning short so the token budget is spent on the answer, and
      // ask Groq to separate reasoning from the final content.
      if (_isReasoning(config.model)) ...{
        'reasoning_effort': 'low',
        'reasoning_format': 'parsed',
      },
      'messages':
          messages.map((m) => {'role': m.role, 'content': m.content}).toList(),
      if (stream) 'stream': true,
    };
  }

  /// Removes a leading <think>...</think> block if a model embeds reasoning in
  /// the content despite our request to separate it.
  static String _stripThink(String text) {
    final cleaned = text.replaceAll(
      RegExp(r'<think>[\s\S]*?</think>', caseSensitive: false),
      '',
    );
    return cleaned.trim();
  }

  @override
  Future<AiCompletion> complete({
    required List<AiMessage> messages,
    required AiProviderConfig config,
    required String apiKey,
  }) async {
    try {
      final res = await dio.post<Map<String, dynamic>>(
        '$baseUrl/chat/completions',
        options: authOptions(apiKey),
        data: _body(config, messages),
      );
      final msg = (res.data?['choices'] as List?)?.firstOrNull?['message']
          as Map<String, dynamic>?;
      var text = _stripThink((msg?['content'] as String?) ?? '');
      // Fallback: if the answer is empty (reasoning ate the budget), use the
      // separated reasoning text so the user still gets output.
      if (text.isEmpty) {
        text = _stripThink((msg?['reasoning'] as String?) ?? '');
      }
      final usage = res.data?['usage'] as Map<String, dynamic>?;
      return AiCompletion(
        text: text,
        providerLabel: 'Groq ${config.model}',
        totalTokens: usage?['total_tokens'] as int?,
      );
    } on DioException catch (e) {
      throw mapDioError(e, 'Groq');
    }
  }

  @override
  Stream<String> streamComplete({
    required List<AiMessage> messages,
    required AiProviderConfig config,
    required String apiKey,
  }) async* {
    try {
      final res = await dio.post<ResponseBody>(
        '$baseUrl/chat/completions',
        options: authOptions(apiKey).copyWith(responseType: ResponseType.stream),
        data: _body(config, messages, stream: true),
      );
      yield* parseSse(res.data!);
    } on DioException catch (e) {
      throw mapDioError(e, 'Groq');
    }
  }
}
