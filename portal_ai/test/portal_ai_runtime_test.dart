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
    test(
      'reports usage when the route sends it, and nothing when it does not',
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
      },
    );

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
        final client = ServerCompletionClient(
          post: (_, {body}) async => response,
        );
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

  group('route', () {
    const personas = [
      AiPersona(id: 'general', label: 'General', description: 'general'),
      AiPersona(
        id: 'gym',
        label: 'Gym',
        description: 'fitness',
        keywords: ['workout'],
      ),
    ];
    PortalAiRuntime runtimeWith(List<String> replies) =>
        PortalAiRuntime(client: _ScriptedClient(replies), personas: personas);

    test('a keyword hit wins without an LLM call', () async {
      // Empty reply list: _ScriptedClient.complete would throw on .last, so a
      // persona coming back at all proves the classifier was never called.
      final runtime = runtimeWith(const []);
      expect((await runtime.route('log my workout'))?.id, 'gym');
    });

    test('classifies when no keyword matches', () async {
      final runtime = runtimeWith(['{"agent":"gym","confidence":0.9}']);
      expect((await runtime.route('I went running'))?.id, 'gym');
    });

    test('low confidence falls back to null', () async {
      final runtime = runtimeWith(['{"agent":"gym","confidence":0.3}']);
      expect(await runtime.route('something vague'), isNull);
    });

    test('an unknown id is null, not a guess', () async {
      final runtime = runtimeWith(['{"agent":"nope","confidence":0.9}']);
      expect(await runtime.route('something'), isNull);
    });

    test('a broken reply is null, never a throw', () async {
      final runtime = runtimeWith(['not json at all']);
      expect(await runtime.route('something'), isNull);
    });

    test('no personas means nothing to route', () async {
      final runtime = PortalAiRuntime(client: _ScriptedClient(const []));
      expect(await runtime.route('log my workout'), isNull);
    });

    group('keywords', () {
      const roster = [
        AiPersona(id: 'general', label: 'General', description: 'general'),
        AiPersona(
          id: 'tasks',
          label: 'Tasks',
          description: 'to-dos',
          keywords: ['plan', 'schedule'],
        ),
        AiPersona(
          id: 'travel',
          label: 'Travel',
          description: 'trips',
          keywords: ['trip', 'hotel', 'itinerary'],
        ),
      ];
      PortalAiRuntime rosterRuntime(_ScriptedClient client) =>
          PortalAiRuntime(client: client, personas: roster);

      test(
        'the persona with the most hits wins, not the first listed',
        () async {
          // Tasks is listed first and has a hit ("plan"); Travel has three.
          final client = _ScriptedClient(const []);
          final persona = await rosterRuntime(
            client,
          ).route('Plan a hotel and itinerary for a weekend trip to Paris');
          expect(persona?.id, 'travel');
          expect(client.calls, 0);
        },
      );

      test(
        'a tie asks the classifier, and only about the tied personas',
        () async {
          // One Tasks word, one Travel word: roster order must not decide it.
          final client = _ScriptedClient([
            '{"agent":"travel","confidence":0.9}',
          ]);
          final persona = await rosterRuntime(
            client,
          ).route('Help me plan a two-day trip by train');
          expect(persona?.id, 'travel');
          expect(client.calls, 1);
          expect(client.lastSystemPrompt, contains('id=tasks'));
          expect(client.lastSystemPrompt, contains('id=travel'));
          expect(client.lastSystemPrompt, isNot(contains('id=general')));
        },
      );

      test('a tie never lands on a persona it was not offered', () async {
        final client = _ScriptedClient([
          '{"agent":"general","confidence":0.9}',
        ]);
        expect(
          await rosterRuntime(client).route('Help me plan a two-day trip'),
          isNull,
        );
      });

      test('a keyword is a whole word, with its inflections', () async {
        final noHit = _ScriptedClient(const []);
        // "airplane" holds "plan"; "strip" holds "trip": neither is a hit, so
        // the classifier is asked (and the empty script makes it throw -> null).
        expect(
          await rosterRuntime(noHit).route('my airplane has a strip of paint'),
          isNull,
        );
        expect(noHit.calls, 1);

        for (final prompt in [
          'I am planning dinner',
          'two hotels booked',
          'I am scheduling dinner',
        ]) {
          final client = _ScriptedClient(const []);
          final persona = await rosterRuntime(client).route(prompt);
          expect(persona, isNotNull, reason: prompt);
          expect(client.calls, 0, reason: prompt);
        }
      });
    });
  });
}

class _ScriptedClient implements AiCompletionClient {
  _ScriptedClient(this.replies);

  final List<String> replies;
  var _index = 0;

  /// How many completions were asked for, and the last system prompt sent.
  var calls = 0;
  String? lastSystemPrompt;

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<String> complete({
    required String systemPrompt,
    required String userPrompt,
    AiSamplerConfig sampler = const AiSamplerConfig(),
    bool jsonMode = false,
  }) async {
    calls++;
    lastSystemPrompt = systemPrompt;
    return _index < replies.length ? replies[_index++] : replies.last;
  }

  @override
  Stream<String> completeStream({
    required String systemPrompt,
    required String userPrompt,
    AiSamplerConfig sampler = const AiSamplerConfig(),
  }) async* {
    yield await complete(systemPrompt: systemPrompt, userPrompt: userPrompt);
  }
}
