import 'package:flutter_test/flutter_test.dart';
import 'package:portal_ai/portal_ai.dart';

void main() {
  test('defaults to the server transport', () {
    final runtime = PortalAiRuntime.create(post: (_, {body}) async => {});

    expect(runtime.usesLocalModel, isFalse);
    expect(runtime.client, isA<ServerCompletionClient>());
  });

  test('AI_OLLAMA_MODEL swaps in a local model for dev testing', () {
    final runtime = PortalAiRuntime.create(
      post: (_, {body}) async => {},
      env: const {'AI_OLLAMA_MODEL': 'gemma4'},
    );

    expect(runtime.usesLocalModel, isTrue);
    final client = runtime.client as OllamaCompletionClient;
    expect(client.model, 'gemma4');
    expect(client.baseUrl, defaultOllamaBaseUrl);
  });

  test('AI_OLLAMA_HOST overrides the default host', () {
    final runtime = PortalAiRuntime.create(
      env: const {
        'AI_OLLAMA_MODEL': 'gemma4',
        'AI_OLLAMA_HOST': 'http://10.0.2.2:11434',
      },
    );

    expect(
      (runtime.client as OllamaCompletionClient).baseUrl,
      'http://10.0.2.2:11434',
    );
  });

  test('no transport and no local model is a wiring error', () {
    expect(() => PortalAiRuntime.create(), throwsArgumentError);
  });

  group('ServerCompletionClient', () {
    test('reports usage when the route sends it, and nothing when it does not',
        () async {
      final withUsage = ServerCompletionClient(
        post: (_, {body}) async => {
          'text': 'hello',
          'model': 'gemini-2.5-flash',
          'usage': {'promptTokens': 120, 'completionTokens': 30},
        },
      );
      await withUsage.complete(systemPrompt: 's', userPrompt: 'u');
      expect(withUsage.lastStats?.model, 'gemini-2.5-flash');
      expect(withUsage.lastStats?.totalTokens, 150);

      // The live route only returns {text}; that must stay silent, not zero.
      final plain = ServerCompletionClient(
        post: (_, {body}) async => {'text': 'hello'},
      );
      await plain.complete(systemPrompt: 's', userPrompt: 'u');
      expect(plain.lastStats, isNull);
    });

    test('posts the prompt and returns the reply text', () async {
      Map<String, dynamic>? sent;
      final client = ServerCompletionClient(
        feature: 'gym-assistant',
        post: (path, {body}) async {
          expect(path, '/ai/complete');
          sent = Map<String, dynamic>.from(body as Map);
          return {'text': '{"final":"done"}'};
        },
      );

      final reply = await client.complete(
        systemPrompt: 'sys',
        userPrompt: 'hi',
        jsonMode: true,
      );

      expect(reply, '{"final":"done"}');
      expect(sent, containsPair('systemPrompt', 'sys'));
      expect(sent, containsPair('prompt', 'hi'));
      expect(sent, containsPair('jsonMode', true));
      expect(sent, containsPair('feature', 'gym-assistant'));
    });

    test('an empty or malformed reply is an AiCompletionException', () async {
      for (final response in <dynamic>[
        <String, dynamic>{},
        {'text': '  '},
        'not a map',
      ]) {
        final client = ServerCompletionClient(post: (_, {body}) async => response);
        await expectLater(
          client.complete(systemPrompt: 's', userPrompt: 'u'),
          throwsA(isA<AiCompletionException>()),
        );
      }
    });
  });
}
