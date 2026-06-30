import 'dart:convert';

import 'package:dio/dio.dart';

import '../../core/errors/failures.dart';
import '../../models/ai_provider_config.dart';
import 'ai_provider.dart';

/// Google Gemini (Generative Language API) adapter. Gemini uses a different
/// request shape than OpenAI: `contents` with `parts`, a separate
/// `systemInstruction`, and the API key passed as a query parameter.
class GeminiProvider implements AiProvider {
  GeminiProvider({
    Dio? dio,
    this.baseUrl = 'https://generativelanguage.googleapis.com/v1beta',
  }) : _dio = dio ?? Dio();

  final Dio _dio;
  final String baseUrl;

  @override
  AiProviderType get type => AiProviderType.gemini;

  ({String? system, List<Map<String, dynamic>> contents}) _toGemini(
    List<AiMessage> messages,
  ) {
    String? system;
    final contents = <Map<String, dynamic>>[];
    for (final m in messages) {
      if (m.role == 'system') {
        system = system == null ? m.content : '$system\n${m.content}';
        continue;
      }
      contents.add({
        'role': m.role == 'assistant' ? 'model' : 'user',
        'parts': [
          {'text': m.content},
        ],
      });
    }
    return (system: system, contents: contents);
  }

  @override
  Future<AiCompletion> complete({
    required List<AiMessage> messages,
    required AiProviderConfig config,
    required String apiKey,
  }) async {
    final mapped = _toGemini(messages);
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '$baseUrl/models/${config.model}:generateContent',
        queryParameters: {'key': apiKey},
        data: {
          'contents': mapped.contents,
          if (mapped.system != null)
            'systemInstruction': {
              'parts': [
                {'text': mapped.system},
              ],
            },
          'generationConfig': {
            'temperature': config.temperature,
            'maxOutputTokens': config.maxTokens,
          },
        },
      );
      final text = _extractText(res.data);
      final usage = res.data?['usageMetadata'] as Map<String, dynamic>?;
      return AiCompletion(
        text: text,
        providerLabel: 'Gemini ${config.model}',
        totalTokens: usage?['totalTokenCount'] as int?,
      );
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  @override
  Stream<String> streamComplete({
    required List<AiMessage> messages,
    required AiProviderConfig config,
    required String apiKey,
  }) async* {
    final mapped = _toGemini(messages);
    try {
      final res = await _dio.post<ResponseBody>(
        '$baseUrl/models/${config.model}:streamGenerateContent',
        queryParameters: {'key': apiKey, 'alt': 'sse'},
        options: Options(responseType: ResponseType.stream),
        data: {
          'contents': mapped.contents,
          if (mapped.system != null)
            'systemInstruction': {
              'parts': [
                {'text': mapped.system},
              ],
            },
          'generationConfig': {
            'temperature': config.temperature,
            'maxOutputTokens': config.maxTokens,
          },
        },
      );
      final lines = utf8.decoder
          .bind(res.data!.stream)
          .transform(const LineSplitter());
      await for (final line in lines) {
        if (!line.startsWith('data:')) continue;
        final payload = line.substring(5).trim();
        if (payload.isEmpty) continue;
        try {
          final json = jsonDecode(payload) as Map<String, dynamic>;
          final text = _extractText(json);
          if (text.isNotEmpty) yield text;
        } catch (_) {
          // ignore keep-alives
        }
      }
    } on DioException catch (e) {
      throw _mapError(e);
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
      throw UnsupportedError('No embedding model configured for Gemini.');
    }
    final results = <List<double>>[];
    try {
      for (final input in inputs) {
        final res = await _dio.post<Map<String, dynamic>>(
          '$baseUrl/models/$model:embedContent',
          queryParameters: {'key': apiKey},
          data: {
            'content': {
              'parts': [
                {'text': input},
              ],
            },
          },
        );
        final values = (res.data?['embedding']?['values'] as List?)
                ?.cast<num>()
                .map((n) => n.toDouble())
                .toList() ??
            <double>[];
        results.add(values);
      }
      return results;
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  String _extractText(Map<String, dynamic>? data) {
    final candidates = data?['candidates'] as List?;
    final parts =
        candidates?.firstOrNull?['content']?['parts'] as List? ?? const [];
    return parts.map((p) => p['text'] as String? ?? '').join();
  }

  AiFailure _mapError(DioException e) {
    final code = e.response?.statusCode;
    final isRate = code == 429;
    return AiFailure(
      isRate ? 'Gemini rate limit reached.' : 'Gemini request failed.',
      statusCode: code,
      isRateLimit: isRate,
      cause: e,
    );
  }
}
