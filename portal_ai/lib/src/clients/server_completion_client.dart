import '../models/ai_sampler_config.dart';
import 'ai_completion_client.dart';
import 'ai_completion_stats.dart';

/// Posts a JSON body to the app's API and returns the decoded response.
///
/// Matches `ApiClient.post` in portal_platform, so apps pass that directly and
/// the assistant inherits their auth, retries and session handling.
typedef AiPostJson = Future<dynamic> Function(
  String path, {
  dynamic body,
});

/// Runs completions through the Portal server, which holds the API key, picks
/// the model and enforces the per-user AI quota.
///
/// Server route: `POST /ai/complete` -> `{ "text": "..." }`.
class ServerCompletionClient
    with AiCompletionStatsSource
    implements AiCompletionClient {
  ServerCompletionClient({
    required this.post,
    this.path = '/ai/complete',
    this.feature = 'assistant',
  });

  final AiPostJson post;
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
      promptTokens:
          usage is Map ? (usage['promptTokens'] ?? usage['prompt_tokens']) as int? : null,
      replyTokens: usage is Map
          ? (usage['completionTokens'] ?? usage['completion_tokens']) as int?
          : null,
    );
    return stats.isEmpty ? null : stats;
  }

  /// The server route is not streaming; this yields the whole reply at once.
  @override
  Stream<String> completeStream({
    required String systemPrompt,
    required String userPrompt,
    AiSamplerConfig sampler = const AiSamplerConfig(),
  }) async* {
    yield await complete(
      systemPrompt: systemPrompt,
      userPrompt: userPrompt,
      sampler: sampler,
    );
  }
}
