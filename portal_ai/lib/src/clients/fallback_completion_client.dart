import 'dart:io';

import '../chat/ai_error_message.dart';
import '../models/ai_sampler_config.dart';
import 'ai_completion_client.dart';
import 'ai_completion_stats.dart';

/// Which client answered a [FallbackCompletionClient] call -- for a badge
/// that marks a reply "answered locally".
enum AiAnsweredBy { primary, fallback }

/// Routes a completion to [primary] first, falling back to [fallback] only
/// when [primary] could not be *reached* -- a 4xx (bad key, quota) is the
/// primary answering "no" and is surfaced, not retried elsewhere.
///
/// Built for server-first routing: `primary` is the Portal server, `fallback`
/// the user's local backend, but nothing here assumes that direction.
class FallbackCompletionClient
    with AiCompletionStatsSource
    implements AiCompletionClient {
  FallbackCompletionClient({
    required this.primary,
    required this.fallback,
    this.onFallback,
  });

  final AiCompletionClient primary;
  final AiCompletionClient fallback;

  /// Called with the transport error just before falling back, so a caller
  /// can log or surface "switched to local" without inspecting exceptions.
  final void Function(Object error)? onFallback;

  /// Which client answered the most recent call. Null before the first one.
  AiAnsweredBy? lastAnsweredBy;

  @override
  Future<bool> isAvailable() async {
    if (await primary.isAvailable()) return true;
    return fallback.isAvailable();
  }

  @override
  Future<String> complete({
    required String systemPrompt,
    required String userPrompt,
    AiSamplerConfig sampler = const AiSamplerConfig(),
    bool jsonMode = false,
  }) async {
    try {
      final text = await primary.complete(
        systemPrompt: systemPrompt,
        userPrompt: userPrompt,
        sampler: sampler,
        jsonMode: jsonMode,
      );
      lastAnsweredBy = AiAnsweredBy.primary;
      lastStats = aiStatsOf(primary);
      return text;
    } catch (e) {
      if (!isTransportFailure(e)) rethrow;
      onFallback?.call(e);
    }

    final text = await fallback.complete(
      systemPrompt: systemPrompt,
      userPrompt: userPrompt,
      sampler: sampler,
      jsonMode: jsonMode,
    );
    lastAnsweredBy = AiAnsweredBy.fallback;
    lastStats = aiStatsOf(fallback);
    return text;
  }

  @override
  Stream<String> completeStream({
    required String systemPrompt,
    required String userPrompt,
    AiSamplerConfig sampler = const AiSamplerConfig(),
  }) async* {
    var yielded = false;
    try {
      await for (final chunk in primary.completeStream(
        systemPrompt: systemPrompt,
        userPrompt: userPrompt,
        sampler: sampler,
      )) {
        yielded = true;
        lastAnsweredBy = AiAnsweredBy.primary;
        yield chunk;
      }
      lastStats = aiStatsOf(primary);
      return;
    } catch (e) {
      // A failure once tokens are already on screen is surfaced, not
      // papered over with a second answer mid-reply.
      if (yielded || !isTransportFailure(e)) rethrow;
      onFallback?.call(e);
    }

    await for (final chunk in fallback.completeStream(
      systemPrompt: systemPrompt,
      userPrompt: userPrompt,
      sampler: sampler,
    )) {
      lastAnsweredBy = AiAnsweredBy.fallback;
      yield chunk;
    }
    lastStats = aiStatsOf(fallback);
  }
}

/// Whether [error] means [FallbackCompletionClient.primary] was unreachable,
/// as opposed to reached and refusing (auth, quota, a bad request).
///
/// [isAiOfflineError] already covers the network-down cases (no host, no
/// socket, the http package's own `ClientException`); this adds the shapes a
/// *server* reports the far end being down through, read off `toString()` of
/// whatever the transport actually throws -- not just [AiCompletionException]:
/// portal_platform's `ApiClient.post`/`postStream` throw `ApiException`,
/// whose `toString()` is `ApiException: Service Unavailable (status: 503)`,
/// never wrapped in an [AiCompletionException] and with no offline phrase
/// [isAiOfflineError] would catch.
bool isTransportFailure(Object error) {
  if (isAiOfflineError(error)) return true;
  if (error is HandshakeException) return true;
  final text = error.toString().toLowerCase();
  return _serverErrorStatus.hasMatch(text) ||
      text.contains('unreachable') ||
      text.contains('timed out');
}

/// A 5xx embedded in an error's own text. Anchored on "status:", "http" or a
/// leading "[" before the digits -- a bare `\b5\d{2}\b` would also match
/// provider text like "512 token limit exceeded", which is a real reply (the
/// prompt is too long) and must be surfaced, not retried against the same
/// over-long prompt on another backend.
final _serverErrorStatus = RegExp(r'(status: 5\d{2})|(http 5\d{2})|(\[5\d{2} )');
