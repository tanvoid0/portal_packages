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

  test('suggestTitle names a thread, and shrugs off a bad reply', () async {
    final replies = <String>[
      '{"title": "Weekly shop"}',
      'sorry, I cannot do that',
    ];
    final runtime = PortalAiRuntime(
      client: _ScriptedClient(replies),
      tools: const [],
      appDescription: 'A test app.',
    );
    const turns = [
      AiChatTurn(role: 'user', content: 'what is on my list'),
      AiChatTurn(role: 'assistant', content: 'milk and eggs'),
    ];

    expect(await runtime.suggestTitle(turns), 'Weekly shop');
    // Not JSON: the caller keeps the title it had.
    expect(await runtime.suggestTitle(turns), '');
    // Nothing said yet, nothing to name -- and no call made.
    expect(await runtime.suggestTitle(const []), '');
  });

}
class _ScriptedClient implements AiCompletionClient {
  _ScriptedClient(this.replies);

  final List<String> replies;
  var _index = 0;

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<String> complete({
    required String systemPrompt,
    required String userPrompt,
    AiSamplerConfig sampler = const AiSamplerConfig(),
    bool jsonMode = false,
  }) async => _index < replies.length ? replies[_index++] : replies.last;

  @override
  Stream<String> completeStream({
    required String systemPrompt,
    required String userPrompt,
    AiSamplerConfig sampler = const AiSamplerConfig(),
  }) async* {
    yield await complete(systemPrompt: systemPrompt, userPrompt: userPrompt);
  }
}
