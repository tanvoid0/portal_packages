import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/ai_sampler_config.dart';
import 'ai_completion_client.dart';
import 'ai_completion_stats.dart';

/// One client for any provider that speaks the OpenAI chat-completions API --
/// OpenAI, Groq, OpenRouter, DeepSeek, Mistral, xAI, Together, LM Studio, or
/// Ollama's own `/v1` shim -- with a user- or developer-supplied key.
///
/// [baseUrl] is the API root, without `/chat/completions`: e.g.
/// `https://api.openai.com/v1` or `http://10.0.2.2:11434/v1` for Ollama on
/// the Android emulator.
class OpenAiCompatibleCompletionClient
    with AiCompletionStatsSource
    implements AiCompletionClient {
  OpenAiCompatibleCompletionClient({
    required String baseUrl,
    required this.model,
    this.apiKey = '',
    http.Client? httpClient,
    this.extraHeaders = const {},
  }) : baseUrl = _stripTrailingSlash(baseUrl),
       _client = httpClient ?? http.Client();

  final String baseUrl;
  final String model;
  final String apiKey;
  final Map<String, String> extraHeaders;
  final http.Client _client;

  static String _stripTrailingSlash(String url) {
    final trimmed = url.trim();
    return trimmed.endsWith('/')
        ? trimmed.substring(0, trimmed.length - 1)
        : trimmed;
  }

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (apiKey.isNotEmpty) 'Authorization': 'Bearer $apiKey',
    ...extraHeaders,
  };

  @override
  Future<bool> isAvailable() async {
    try {
      final response = await _client
          .get(Uri.parse('$baseUrl/models'), headers: _headers)
          .timeout(const Duration(seconds: 3));
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (_) {
      return false;
    }
  }

  Map<String, dynamic> _body({
    required String systemPrompt,
    required String userPrompt,
    required AiSamplerConfig sampler,
    required bool jsonMode,
    required bool stream,
  }) => {
    'model': model,
    'stream': stream,
    'temperature': sampler.temperature,
    'top_p': sampler.topP,
    if (sampler.topK != null) 'top_k': sampler.topK,
    'messages': [
      if (systemPrompt.isNotEmpty) {'role': 'system', 'content': systemPrompt},
      {'role': 'user', 'content': userPrompt},
    ],
    if (jsonMode) 'response_format': {'type': 'json_object'},
  };

  @override
  Future<String> complete({
    required String systemPrompt,
    required String userPrompt,
    AiSamplerConfig sampler = const AiSamplerConfig(),
    bool jsonMode = false,
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/chat/completions'),
      headers: _headers,
      body: jsonEncode(
        _body(
          systemPrompt: systemPrompt,
          userPrompt: userPrompt,
          sampler: sampler,
          jsonMode: jsonMode,
          stream: false,
        ),
      ),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AiCompletionException(_errorMessage(response.statusCode, response.body));
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final usage = decoded['usage'];
    lastStats = AiCompletionStats(
      model: decoded['model'] as String? ?? model,
      promptTokens: usage is Map ? usage['prompt_tokens'] as int? : null,
      replyTokens: usage is Map ? usage['completion_tokens'] as int? : null,
    );

    final choices = decoded['choices'];
    if (choices is List && choices.isNotEmpty && choices.first is Map) {
      final message = (choices.first as Map)['message'];
      if (message is Map) {
        final content = message['content'] as String?;
        if (content != null && content.isNotEmpty) return content;
      }
    }
    throw const AiCompletionException(
      'OpenAI-compatible backend returned an empty response',
    );
  }

  @override
  Stream<String> completeStream({
    required String systemPrompt,
    required String userPrompt,
    AiSamplerConfig sampler = const AiSamplerConfig(),
  }) async* {
    final request = http.Request('POST', Uri.parse('$baseUrl/chat/completions'));
    request.headers.addAll(_headers);
    request.body = jsonEncode(
      _body(
        systemPrompt: systemPrompt,
        userPrompt: userPrompt,
        sampler: sampler,
        jsonMode: false,
        stream: true,
      ),
    );

    final streamed = await _client.send(request);
    if (streamed.statusCode < 200 || streamed.statusCode >= 300) {
      final errorBody = await streamed.stream.bytesToString();
      throw AiCompletionException(_errorMessage(streamed.statusCode, errorBody));
    }

    // LineSplitter, not a per-chunk split: a network read can end mid-line,
    // and a `data:` frame split across two reads would otherwise lose
    // whichever half arrived in the second chunk. It also folds CRLF for us.
    final lines = streamed.stream.transform(utf8.decoder).transform(
      const LineSplitter(),
    );
    await for (final line in lines) {
      final trimmed = line.trim();
      if (!trimmed.startsWith('data:')) continue;
      final payload = trimmed.substring(5).trim();
      if (payload.isEmpty || payload == '[DONE]') continue;
      Map<String, dynamic> frame;
      try {
        frame = jsonDecode(payload) as Map<String, dynamic>;
      } catch (_) {
        continue; // Ignore malformed SSE frames.
      }
      final error = frame['error'];
      if (error != null) {
        final message = error is Map ? error['message'] as String? : null;
        throw AiCompletionException(
          message ?? 'OpenAI-compatible backend error',
        );
      }
      final choices = frame['choices'];
      if (choices is List && choices.isNotEmpty && choices.first is Map) {
        final delta = (choices.first as Map)['delta'];
        final content = delta is Map ? delta['content'] as String? : null;
        if (content != null && content.isNotEmpty) yield content;
      }
    }
  }

  /// The provider's own `error.message` when the body is their JSON error
  /// envelope, else a plain status line.
  static String _errorMessage(int statusCode, String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map) {
        final error = decoded['error'];
        final message = error is Map ? error['message'] : null;
        if (message is String && message.trim().isNotEmpty) {
          return message.trim();
        }
      }
    } catch (_) {
      // Not JSON -- fall through to the status line.
    }
    return 'HTTP $statusCode';
  }
}

/// One well-known OpenAI-compatible endpoint, for the settings dropdown.
class OpenAiCompatiblePreset {
  const OpenAiCompatiblePreset({required this.label, required this.baseUrl});

  final String label;
  final String baseUrl;
}

/// Presets offered in AI settings. "Custom" (a free-typed URL) is the absence
/// of a match here, not an entry in this list.
const openAiCompatiblePresets = <OpenAiCompatiblePreset>[
  OpenAiCompatiblePreset(label: 'OpenAI', baseUrl: 'https://api.openai.com/v1'),
  OpenAiCompatiblePreset(
    label: 'Groq',
    baseUrl: 'https://api.groq.com/openai/v1',
  ),
  OpenAiCompatiblePreset(
    label: 'OpenRouter',
    baseUrl: 'https://openrouter.ai/api/v1',
  ),
  OpenAiCompatiblePreset(
    label: 'DeepSeek',
    baseUrl: 'https://api.deepseek.com/v1',
  ),
  OpenAiCompatiblePreset(label: 'Mistral', baseUrl: 'https://api.mistral.ai/v1'),
  OpenAiCompatiblePreset(label: 'xAI', baseUrl: 'https://api.x.ai/v1'),
  OpenAiCompatiblePreset(
    label: 'Together',
    baseUrl: 'https://api.together.xyz/v1',
  ),
  OpenAiCompatiblePreset(
    label: 'Gemini',
    baseUrl: 'https://generativelanguage.googleapis.com/v1beta/openai',
  ),
  OpenAiCompatiblePreset(label: 'LM Studio', baseUrl: 'http://localhost:1234/v1'),
  OpenAiCompatiblePreset(label: 'Ollama', baseUrl: 'http://localhost:11434/v1'),
];
