import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/ai_sampler_config.dart';
import 'ai_completion_client.dart';

/// Talks to a local or remote Ollama daemon.
class OllamaCompletionClient implements AiCompletionClient {
  OllamaCompletionClient({
    required this.baseUrl,
    required this.model,
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String baseUrl;
  final String model;
  final http.Client _client;

  @override
  Future<bool> isAvailable() async {
    try {
      final response = await _client
          .get(Uri.parse(_normalizedBaseUrl))
          .timeout(const Duration(seconds: 2));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<String> complete({
    required String systemPrompt,
    required String userPrompt,
    AiSamplerConfig sampler = const AiSamplerConfig(),
    bool jsonMode = false,
  }) async {
    final body = <String, dynamic>{
      'model': model,
      'stream': false,
      'messages': [
        {'role': 'system', 'content': systemPrompt},
        {'role': 'user', 'content': userPrompt},
      ],
      'options': {
        'temperature': sampler.temperature,
        'top_p': sampler.topP,
        if (sampler.topK != null) 'top_k': sampler.topK,
      },
      if (jsonMode) 'format': 'json',
    };

    final response = await _client.post(
      Uri.parse('$_normalizedBaseUrl/api/chat'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode != 200) {
      throw AiCompletionException(
        'Ollama error (${response.statusCode}): ${response.body}',
      );
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final message = decoded['message'];
    if (message is Map) {
      final content = message['content'] as String?;
      if (content != null && content.isNotEmpty) return content;
    }
    throw const AiCompletionException('Ollama returned an empty response');
  }

  @override
  Stream<String> completeStream({
    required String systemPrompt,
    required String userPrompt,
    AiSamplerConfig sampler = const AiSamplerConfig(),
  }) async* {
    final body = <String, dynamic>{
      'model': model,
      'stream': true,
      'messages': [
        {'role': 'system', 'content': systemPrompt},
        {'role': 'user', 'content': userPrompt},
      ],
      'options': {
        'temperature': sampler.temperature,
        'top_p': sampler.topP,
        if (sampler.topK != null) 'top_k': sampler.topK,
      },
    };

    final request = http.Request(
      'POST',
      Uri.parse('$_normalizedBaseUrl/api/chat'),
    );
    request.headers['Content-Type'] = 'application/json';
    request.body = jsonEncode(body);

    final streamed = await _client.send(request);
    if (streamed.statusCode != 200) {
      final errorBody = await streamed.stream.bytesToString();
      throw AiCompletionException(
        'Ollama error (${streamed.statusCode}): $errorBody',
      );
    }

    await for (final chunk in streamed.stream.transform(utf8.decoder)) {
      for (final line in chunk.split('\n')) {
        final trimmed = line.trim();
        if (trimmed.isEmpty) continue;
        try {
          final decoded = jsonDecode(trimmed) as Map<String, dynamic>;
          final message = decoded['message'];
          if (message is Map) {
            final content = message['content'] as String?;
            if (content != null && content.isNotEmpty) {
              yield content;
            }
          }
        } catch (_) {
          // Ignore malformed NDJSON lines.
        }
      }
    }
  }

  String get _normalizedBaseUrl {
    var url = baseUrl.trim();
    if (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    return url;
  }
}

/// Placeholder for server-side Gemini — apps should route through their API.
class CloudGeminiCompletionClient implements AiCompletionClient {
  const CloudGeminiCompletionClient();

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<String> complete({
    required String systemPrompt,
    required String userPrompt,
    AiSamplerConfig sampler = const AiSamplerConfig(),
    bool jsonMode = false,
  }) {
    throw UnsupportedError(
      'Use your app server for cloud Gemini completions.',
    );
  }

  @override
  Stream<String> completeStream({
    required String systemPrompt,
    required String userPrompt,
    AiSamplerConfig sampler = const AiSamplerConfig(),
  }) {
    throw UnsupportedError(
      'Use your app server for cloud Gemini completions.',
    );
  }
}
