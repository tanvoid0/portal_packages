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

  test('runs a tool then finishes, coercing string args', () async {
    final client = _ScriptedClient([
      '{"tool":"add_item","args":{"name":"Milk","quantity":"2"}}',
      '{"final":"Added milk."}',
    ]);
    final result = await AiAgent(client: client, tools: [addItem()]).run('buy milk');

    expect(added, ['Milk x2']);
    expect(result.message, 'Added milk.');
    expect(result.steps.single.failed, isFalse);
    // Second turn must carry the tool result back to the model.
    expect(client.prompts[1], contains('added Milk'));
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
