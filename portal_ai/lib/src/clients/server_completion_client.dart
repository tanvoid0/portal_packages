import 'dart:convert';

import '../models/ai_sampler_config.dart';
import 'ai_completion_client.dart';
import 'ai_completion_stats.dart';

/// Posts a JSON body to the app's API and returns the decoded response.
///
/// Matches `ApiClient.post` in portal_platform, so apps pass that directly and
/// the assistant inherits their auth, retries and session handling.
typedef AiPostJson = Future<dynamic> Function(String path, {dynamic body});

/// Streams a reply from the app's API, one server-sent event payload at a
/// time.
///
/// Matches `ApiClient.postStream` in portal_platform, the same way
/// [AiPostJson] matches `post`.
typedef AiPostStream = Stream<String> Function(String path, {dynamic body});

/// Runs completions through the Portal server, which holds the API key, picks
/// the model and enforces the per-user AI quota.
///
/// Server route: `POST /ai/complete` -> `{ "text": "..." }`.
class ServerCompletionClient
    with AiCompletionStatsSource
    implements AiCompletionClient {
  ServerCompletionClient({
    required this.post,
    this.postStream,
    this.path = '/ai/complete',
    this.feature = 'assistant',
  });

  final AiPostJson post;

  /// Streaming transport. Without one the client still answers -- in a single
  /// chunk, which is what it did before the route existed.
  final AiPostStream? postStream;

  final String path;

  /// Groups server-side usage stats. Lowercase, digits and dashes only.
  final String feature;

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<String> complete({
    required String systemPrompt,
    required String userPrompt,
    AiSamplerConfig sampler = const AiSamplerConfig(),
    bool jsonMode = false,
  }) async {
    final dynamic response = await post(
      path,
      body: <String, dynamic>{
        'systemPrompt': systemPrompt,
        'prompt': userPrompt,
        'jsonMode': jsonMode,
        'temperature': sampler.temperature,
        'feature': feature,
      },
    );

    // The route may or may not report usage; read it when it does rather
    // than requiring a server change to land first.
    lastStats = response is Map ? _statsOf(response) : null;
    final text = response is Map ? response['text'] as String? : null;
    if (text == null || text.trim().isEmpty) {
      throw const AiCompletionException('Server returned an empty response');
    }
    return text;
  }

  static AiCompletionStats? _statsOf(Map<dynamic, dynamic> response) {
    final usage = response['usage'];
    final stats = AiCompletionStats(
      model: response['model'] as String?,
      promptTokens: usage is Map
          ? (usage['promptTokens'] ?? usage['prompt_tokens']) as int?
          : null,
      replyTokens: usage is Map
          ? (usage['completionTokens'] ?? usage['completion_tokens']) as int?
          : null,
    );
    return stats.isEmpty ? null : stats;
  }

  /// `POST /ai/complete/stream` -> `data: {"text": "..."}` frames, then
  /// `data: [DONE]`.
  ///
  /// An error arrives as a frame rather than a status code: by the time the
  /// provider fails the headers are long since sent. Falls back to one chunk
  /// when the host wired no streaming transport.
  @override
  Stream<String> completeStream({
    required String systemPrompt,
    required String userPrompt,
    AiSamplerConfig sampler = const AiSamplerConfig(),
  }) async* {
    final stream = postStream;
    if (stream == null) {
      yield await complete(
        systemPrompt: systemPrompt,
        userPrompt: userPrompt,
        sampler: sampler,
      );
      return;
    }

    await for (final payload in stream(
      '$path/stream',
      body: <String, dynamic>{
        'systemPrompt': systemPrompt,
        'prompt': userPrompt,
        'temperature': sampler.temperature,
        'jsonMode': true,
        'feature': feature,
      },
    )) {
      if (payload.isEmpty || payload == '[DONE]') continue;
      final frame = jsonDecode(payload);
      if (frame is! Map) continue;
      if (frame['error'] case final String error when error.isNotEmpty) {
        throw AiCompletionException(error);
      }
      if (frame['text'] case final String text when text.isNotEmpty) {
        yield text;
      }
    }
  }
}
