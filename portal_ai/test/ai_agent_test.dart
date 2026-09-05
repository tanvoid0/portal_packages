import 'package:flutter_test/flutter_test.dart';
import 'package:portal_ai/portal_ai.dart';

/// Replays a fixed script of model replies, one per turn.
class _ScriptedClient implements AiCompletionClient {
  _ScriptedClient(this.replies);

  final List<String> replies;
  final prompts = <String>[];
  var _index = 0;

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<String> complete({
    required String systemPrompt,
    required String userPrompt,
    AiSamplerConfig sampler = const AiSamplerConfig(),
    bool jsonMode = false,
  }) async {
    prompts.add(userPrompt);
    return replies[_index++];
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

void main() {
  _statsTests();

  final added = <String>[];

  AiTool addItem() => AiTool(
        name: 'add_item',
        description: 'Add an item.',
        parameters: const {'name': 'item name', 'quantity': 'how many'},
        mutates: true,
        run: (call) async {
          added.add('${call.argString('name')} x${call.argInt('quantity') ?? 1}');
          return 'added ${call.argString('name')}';
        },
      );

  AiTool listItems() => AiTool(
        name: 'list_items',
        description: 'List the items.',
        run: (_) async => added.isEmpty ? 'empty' : added.join(', '),
      );

  setUp(added.clear);

  test('extracts JSON from fenced or chatty replies', () {
    expect(extractJsonObject('```json\n{"final":"hi"}\n```'), {'final': 'hi'});
    expect(extractJsonObject('Sure! {"tool":"a","args":{}} done'),
        {'tool': 'a', 'args': <String, dynamic>{}});
    expect(
      extractJsonObject(
          '[{"tool":"a","args":{"name":"pasta"}},{"tool":"a","args":{}}]'),
      {
        'tool': 'a',
        'args': {'name': 'pasta'}
      },
    );
    expect(extractJsonObject('no json here'), isNull);
    expect(extractJsonObject('{broken'), isNull);
  });

  test('ignores a reasoning block that quotes JSON of its own', () {
    expect(
      extractJsonObject(
        '<think>They want {"exercise_ids": [...]}, so I will pick four.</think>'
        '{"exercise_ids":["a","b"]}',
      ),
      {
        'exercise_ids': ['a', 'b']
      },
    );
  });

  test('runs a tool then finishes, coercing string args', () async {
    final client = _ScriptedClient([
      '{"tool":"add_item","args":{"name":"Milk","quantity":"2"}}',
      '{"final":"Added milk."}',
    ]);
    final result = await AiAgent(client: client, tools: [addItem()])
        .run('buy milk', confirm: (_, _) async => true);

    expect(added, ['Milk x2']);
    expect(result.message, 'Added milk.');
    expect(result.steps.single.failed, isFalse);
    // Second turn must carry the tool result back to the model.
    expect(client.prompts[1], contains('added Milk'));
  });

  test('a mutating tool is refused when there is nobody to approve it',
      () async {
    final client = _ScriptedClient([
      '{"tool":"add_item","args":{"name":"Milk"}}',
      '{"final":"Could not add it."}',
    ]);
    // No confirm callback: a caller with no UI must not write user data.
    final result = await AiAgent(client: client, tools: [addItem()])
        .run('buy milk');

    expect(added, isEmpty);
    expect(result.steps.single.failed, isTrue);
    expect(client.prompts[1], contains('refused'));
  });

  test('tool results reach the model fenced as data, not instructions',
      () async {
    final client = _ScriptedClient([
      '{"tool":"list_items","args":{}}',
      '{"final":"done"}',
    ]);
    await AiAgent(client: client, tools: [addItem(), listItems()])
        .run('what is on my list');

    expect(client.prompts[1], contains('BEGIN TOOL RESULTS'));
    expect(client.prompts[1], contains('END TOOL RESULTS'));
  });

  test('declining a mutating tool skips it and tells the model', () async {
    final client = _ScriptedClient([
      '{"tool":"add_item","args":{"name":"Milk"}}',
      '{"final":"Left it out."}',
    ]);
    final result = await AiAgent(client: client, tools: [addItem()])
        .run('buy milk', confirm: (_, _) async => false);

    expect(added, isEmpty);
    expect(result.steps.single.failed, isTrue);
    expect(client.prompts[1], contains('declined'));
  });

  test('unknown tool and tool errors are fed back, not thrown', () async {
    final client = _ScriptedClient([
      '{"tool":"nope","args":{}}',
      '{"tool":"boom","args":{}}',
      '{"final":"Could not do it."}',
    ]);
    final result = await AiAgent(
      client: client,
      tools: [
        AiTool(
          name: 'boom',
          description: 'Always fails.',
          run: (_) async => throw StateError('offline'),
        ),
      ],
    ).run('do it');

    expect(result.message, 'Could not do it.');
    expect(result.steps.single.failed, isTrue);
    expect(client.prompts[1], contains('unknown tool'));
    expect(client.prompts[2], contains('offline'));
  });

  test('stops at maxSteps instead of looping forever', () async {
    final client = _ScriptedClient(
      List.filled(3, '{"tool":"add_item","args":{"name":"Milk"}}'),
    );
    final result =
        await AiAgent(client: client, tools: [addItem()], maxSteps: 3).run('spam');

    expect(result.steps, hasLength(3));
    expect(result.message, contains('Stopped after 3 steps'));
  });
}

/// A client that reports usage, to prove a multi-call run sums it.
class _CountingClient with AiCompletionStatsSource implements AiCompletionClient {
  _CountingClient(this.replies);

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
  }) async {
    lastStats = const AiCompletionStats(
      model: 'gemma4',
      promptTokens: 10,
      replyTokens: 5,
    );
    return replies[_index++];
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

void _statsTests() {
  test('usage is summed over every call a run makes', () async {
    final client = _CountingClient([
      '{"tool": "echo", "args": {}}',
      '{"final": "done"}',
    ]);
    final agent = AiAgent(
      client: client,
      tools: [
        AiTool(
          name: 'echo',
          description: 'echo',
          run: (_) async => 'ok',
        ),
      ],
    );
    final result = await agent.run('go');
    expect(result.stats?.totalTokens, 30);
    expect(result.stats?.model, 'gemma4');
  });

  test('a backend that reports nothing leaves the stats null', () async {
    final agent = AiAgent(
      client: _ScriptedClient(['{"final": "done"}']),
      tools: const [],
    );
    expect((await agent.run('go')).stats, isNull);
  });
}
