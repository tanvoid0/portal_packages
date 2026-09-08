import 'package:flutter_test/flutter_test.dart';
import 'package:portal_ai/portal_ai.dart';

void main() {
  test('SSE frames become text, in order', () async {
    final client = ServerCompletionClient(
      post: (path, {body}) async => {'text': 'unused'},
      postStream: (path, {body}) async* {
        expect(path, '/ai/complete/stream');
        expect((body as Map)['jsonMode'], isTrue);
        yield '{"text": "one "}';
        yield '{"text": "two"}';
        yield '[DONE]';
      },
    );

    expect(
      await client.completeStream(systemPrompt: 'sys', userPrompt: 'hi').join(),
      'one two',
    );
  });

  test('an error frame stops the stream loudly', () {
    final client = ServerCompletionClient(
      post: (path, {body}) async => {'text': 'unused'},
      postStream: (path, {body}) async* {
        yield '{"text": "half an ans"}';
        yield '{"error": "Gemini stream failed (503)."}';
      },
    );

    expect(
      client.completeStream(systemPrompt: 'sys', userPrompt: 'hi'),
      emitsInOrder(['half an ans', emitsError(isA<AiCompletionException>())]),
    );
  });

  test('without a streaming transport the whole reply comes as one chunk', () {
    final client = ServerCompletionClient(
      post: (path, {body}) async => {'text': 'all of it'},
    );

    expect(
      client.completeStream(systemPrompt: 'sys', userPrompt: 'hi'),
      emitsInOrder(['all of it', emitsDone]),
    );
  });
}
