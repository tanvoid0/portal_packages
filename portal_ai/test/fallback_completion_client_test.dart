import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:portal_ai/portal_ai.dart';

/// Mirrors portal_platform's `ApiException` shape -- the real class isn't a
/// dependency here, but `ApiClient.post`/`postStream` throw exactly this
/// `toString()` on a 5xx, and that is what [isTransportFailure] has to see.
class _FakeApiException implements Exception {
  const _FakeApiException(this.message, this.status);

  final String message;
  final int status;

  @override
  String toString() => 'ApiException: $message (status: $status)';
}

class _FakeClient implements AiCompletionClient {
  _FakeClient({
    this.answer = 'ok',
    this.completeError,
    List<String>? streamChunks,
    this.streamError,
  }) : streamChunks = streamChunks ?? const [];

  final String answer;
  final Object? completeError;
  final List<String> streamChunks;
  final Object? streamError;
  int completeCalls = 0;
  int streamCalls = 0;

  @override
  Future<bool> isAvailable() async => completeError == null;

  @override
  Future<String> complete({
    required String systemPrompt,
    required String userPrompt,
    AiSamplerConfig sampler = const AiSamplerConfig(),
    bool jsonMode = false,
  }) async {
    completeCalls++;
    if (completeError != null) throw completeError!;
    return answer;
  }

  @override
  Stream<String> completeStream({
    required String systemPrompt,
    required String userPrompt,
    AiSamplerConfig sampler = const AiSamplerConfig(),
  }) async* {
    streamCalls++;
    for (final chunk in streamChunks) {
      yield chunk;
    }
    if (streamError != null) throw streamError!;
  }
}

void main() {
  group('isTransportFailure', () {
    test('network-down shapes are transport failures', () {
      expect(isTransportFailure(const SocketException('nope')), isTrue);
      expect(isTransportFailure(const HandshakeException('tls')), isTrue);
      expect(
        isTransportFailure(const AiCompletionException('HTTP 503: boom')),
        isTrue,
      );
      expect(
        isTransportFailure(const AiCompletionException('upstream unreachable')),
        isTrue,
      );
      expect(
        isTransportFailure(const AiCompletionException('request timed out')),
        isTrue,
      );
    });

    test('a portal_platform ApiException 5xx is a transport failure', () {
      // The shape ApiClient.post/postStream actually throw -- not an
      // AiCompletionException at all, and no offline phrase in it either.
      expect(
        isTransportFailure(const _FakeApiException('Service Unavailable', 503)),
        isTrue,
      );
    });

    test('the primary answering "no" is not a transport failure', () {
      expect(
        isTransportFailure(const AiCompletionException('HTTP 401')),
        isFalse,
      );
      expect(
        isTransportFailure(const AiCompletionException('Invalid API key')),
        isFalse,
      );
    });

    test('a bare 5xx-shaped number in provider text is not a transport failure', () {
      // "512 token limit exceeded" is the model answering, not the server
      // being down -- retrying it against another backend would just re-run
      // the same over-long prompt.
      expect(
        isTransportFailure(
          const AiCompletionException('512 token limit exceeded'),
        ),
        isFalse,
      );
      expect(
        isTransportFailure(const _FakeApiException('500 things in stock', 400)),
        isFalse,
      );
    });
  });

  group('FallbackCompletionClient.complete', () {
    test('a transport failure on primary falls back', () async {
      final primary = _FakeClient(
        completeError: const SocketException('down'),
      );
      final fallback = _FakeClient(answer: 'from fallback');
      Object? seenError;
      final client = FallbackCompletionClient(
        primary: primary,
        fallback: fallback,
        onFallback: (e) => seenError = e,
      );

      final reply = await client.complete(systemPrompt: 'sys', userPrompt: 'hi');

      expect(reply, 'from fallback');
      expect(client.lastAnsweredBy, AiAnsweredBy.fallback);
      expect(seenError, isA<SocketException>());
      expect(fallback.completeCalls, 1);
    });

    test('a 4xx from primary is surfaced, fallback never called', () async {
      final primary = _FakeClient(
        completeError: const AiCompletionException('HTTP 401'),
      );
      final fallback = _FakeClient(answer: 'from fallback');
      final client = FallbackCompletionClient(primary: primary, fallback: fallback);

      await expectLater(
        client.complete(systemPrompt: 'sys', userPrompt: 'hi'),
        throwsA(isA<AiCompletionException>()),
      );
      expect(fallback.completeCalls, 0);
    });

    test('primary answering sets lastAnsweredBy to primary', () async {
      final client = FallbackCompletionClient(
        primary: _FakeClient(answer: 'from primary'),
        fallback: _FakeClient(answer: 'unused'),
      );

      final reply = await client.complete(systemPrompt: 'sys', userPrompt: 'hi');

      expect(reply, 'from primary');
      expect(client.lastAnsweredBy, AiAnsweredBy.primary);
    });
  });

  group('FallbackCompletionClient.completeStream', () {
    test('falls back when nothing has been yielded yet', () async {
      final primary = _FakeClient(streamError: const SocketException('down'));
      final fallback = _FakeClient(streamChunks: ['local ', 'reply']);
      final client = FallbackCompletionClient(primary: primary, fallback: fallback);

      final text = await client
          .completeStream(systemPrompt: 'sys', userPrompt: 'hi')
          .join();

      expect(text, 'local reply');
      expect(client.lastAnsweredBy, AiAnsweredBy.fallback);
    });

    test('a mid-stream failure is surfaced, not retried on the fallback', () async {
      final primary = _FakeClient(
        streamChunks: ['partial'],
        streamError: const SocketException('dropped'),
      );
      final fallback = _FakeClient(streamChunks: ['should not run']);
      final client = FallbackCompletionClient(primary: primary, fallback: fallback);

      final emitted = <String>[];
      Object? caught;
      try {
        await for (final chunk in client.completeStream(
          systemPrompt: 'sys',
          userPrompt: 'hi',
        )) {
          emitted.add(chunk);
        }
      } catch (e) {
        caught = e;
      }

      expect(caught, isA<SocketException>());
      expect(emitted, ['partial']);
      expect(fallback.streamCalls, 0);
    });
  });
}
