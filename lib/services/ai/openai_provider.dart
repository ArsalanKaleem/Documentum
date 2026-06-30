import 'dart:convert';

import 'package:dio/dio.dart';

import '../../core/errors/failures.dart';
import '../../models/ai_provider_config.dart';
import 'ai_provider.dart';

/// OpenAI Chat Completions + Embeddings adapter. Subclassed by Groq,
/// OpenRouter, NVIDIA NIM, Cerebras, and SambaNova — all of which use the same
/// wire format. Exposes protected helpers so subclasses can override request
/// bodies while reusing auth and SSE parsing.
class OpenAiProvider implements AiProvider {
  OpenAiProvider({
    Dio? dio,
    this.baseUrl = 'https://api.openai.com/v1',
    this.type = AiProviderType.gemini, // unused directly; kept for factory
    this.displayName = 'OpenAI',
    this.extraHeaders = const {},
  }) : dio = dio ?? Dio();

  /// Exposed to subclasses.
  final Dio dio;
  final String baseUrl;
  final Map<String, String> extraHeaders;

  @override
  final AiProviderType type;

  final String displayName;

  /// Auth + content-type headers. Protected for subclass use.
  Options authOptions(String apiKey) => Options(
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
          ...extraHeaders,
        },
      );

  /// Maps a DioException to an [AiFailure], reading Retry-After when present.
  AiFailure mapDioError(DioException e, String label) {
    final code = e.response?.statusCode;
    final isRate = code == 429;
    int? retryAfter;
    final header = e.response?.headers.value('retry-after');
    if (header != null) retryAfter = int.tryParse(header.trim());

    // Surface the actual error message from the provider JSON body.
    String? providerMsg;
    try {
      final body = e.response?.data;
      if (body is Map) {
        providerMsg = body['error']?['message'] as String?;
      }
    } catch (_) {}

    final message = providerMsg ??
        (isRate ? '$label rate limit reached.' : '$label request failed.');
    return AiFailure(
      message,
      statusCode: code,
      isRateLimit: isRate,
      retryAfterSeconds: retryAfter,
      cause: e,
    );
  }

  /// Parses an OpenAI-style SSE stream. Protected for subclass use.
  Stream<String> parseSse(ResponseBody body) async* {
    final lines = utf8.decoder
        .bind(body.stream)
        .transform(const LineSplitter());
    await for (final line in lines) {
      if (!line.startsWith('data:')) continue;
      final payload = line.substring(5).trim();
      if (payload.isEmpty || payload == '[DONE]') continue;
      try {
        final json = jsonDecode(payload) as Map<String, dynamic>;
        final delta = (json['choices'] as List?)
            ?.firstOrNull?['delta']?['content'] as String?;
        if (delta != null && delta.isNotEmpty) yield delta;
      } catch (_) {}
    }
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
        data: {
          'model': config.model,
          'temperature': config.temperature,
          'max_tokens': config.maxTokens,
          'messages': messages
              .map((m) => {'role': m.role, 'content': m.content})
              .toList(),
        },
      );
      final text = (res.data?['choices'] as List?)
              ?.firstOrNull?['message']?['content'] as String? ??
          '';
      final usage = res.data?['usage'] as Map<String, dynamic>?;
      return AiCompletion(
        text: text,
        providerLabel: '$displayName ${config.model}',
        totalTokens: usage?['total_tokens'] as int?,
      );
    } on DioException catch (e) {
      throw mapDioError(e, displayName);
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
        options:
            authOptions(apiKey).copyWith(responseType: ResponseType.stream),
        data: {
          'model': config.model,
          'temperature': config.temperature,
          'max_tokens': config.maxTokens,
          'stream': true,
          'messages': messages
              .map((m) => {'role': m.role, 'content': m.content})
              .toList(),
        },
      );
      yield* parseSse(res.data!);
    } on DioException catch (e) {
      throw mapDioError(e, displayName);
    }
  }

  @override
  Future<List<List<double>>> embed({
    required List<String> inputs,
    required AiProviderConfig config,
    required String apiKey,
  }) async {
    final model = config.embeddingModel;
    if (model == null) {
      throw UnsupportedError('No embedding model configured for $displayName.');
    }
    try {
      final res = await dio.post<Map<String, dynamic>>(
        '$baseUrl/embeddings',
        options: authOptions(apiKey),
        data: {'model': model, 'input': inputs},
      );
      final data = res.data?['data'] as List? ?? [];
      return data
          .map((e) => (e['embedding'] as List)
              .cast<num>()
              .map((n) => n.toDouble())
              .toList())
          .toList();
    } on DioException catch (e) {
      throw mapDioError(e, displayName);
    }
  }
}
