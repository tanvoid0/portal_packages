import 'package:flutter_test/flutter_test.dart';
import 'package:portal_ai/portal_ai.dart';

/// Replays a fixed script of model replies, one per turn.
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
  }) async =>
      // Pad rather than throw: a refused tool call costs an extra turn.
      _index < replies.length ? replies[_index++] : replies.last;

  @override
  Stream<String> completeStream({
    required String systemPrompt,
    required String userPrompt,
    AiSamplerConfig sampler = const AiSamplerConfig(),
  }) async* {
    yield await complete(systemPrompt: systemPrompt, userPrompt: userPrompt);
  }
}

AiTool _tool(String name) => AiTool(
  name: name,
  description: 'test tool',
  run: (call) async => 'ran ${call.name}',
);

void main() {
  test('namespacing qualifies names without touching the bare name', () {
    final tools = namespacedTools('shopping', [_tool('add_item')]);

    expect(tools.single.name, 'add_item');
    expect(tools.single.namespace, 'shopping');
    expect(tools.single.qualifiedName, 'shopping.add_item');
  });

  test('the prompt spec advertises the qualified name', () {
    final tool = _tool('add_item').withNamespace('lifestyle');

    expect(tool.spec, contains('lifestyle.add_item'));
  });

  test('two apps can define the same bare name without colliding', () {
    final combined = [
      ...namespacedTools('shopping', [_tool('add_item')]),
      ...namespacedTools('lifestyle', [_tool('add_item')]),
    ];

    final qualified = combined.map((t) => t.qualifiedName).toList();
    expect(qualified, ['shopping.add_item', 'lifestyle.add_item']);
    expect(qualified.toSet(), hasLength(2));
  });

  test('an un-namespaced tool keeps its bare name', () {
    final tool = _tool('list_items');

    expect(tool.namespace, isNull);
    expect(tool.qualifiedName, 'list_items');
    expect(tool.spec, contains('list_items'));
  });

  group('the agent resolving a namespaced tool', () {
    List<AiTool> twoApps() => [
      ...namespacedTools('shopping', [_tool('add_item')]),
      ...namespacedTools('lifestyle', [_tool('add_item')]),
    ];

    test('a qualified name picks exactly that one app tool', () async {
      final client = _ScriptedClient([
        '{"tool":"lifestyle.add_item","args":{}}',
        '{"message":"done"}',
      ]);

      final result = await AiAgent(
        client: client,
        tools: twoApps(),
      ).run('add a coat');

      expect(result.steps.single.failed, isFalse);
      expect(result.steps.single.result, 'ran lifestyle.add_item');
    });

    test('an ambiguous bare name is refused, not guessed', () async {
      final client = _ScriptedClient([
        '{"tool":"add_item","args":{}}',
        '{"message":"gave up"}',
      ]);

      final result = await AiAgent(
        client: client,
        tools: twoApps(),
      ).run('add something');

      // Nothing ran: picking either app would have been a coin flip. The
      // agent keeps asking rather than guessing, so only assert that.
      expect(result.steps, isEmpty);
    });

    test('an unambiguous bare name still resolves', () async {
      final client = _ScriptedClient([
        '{"tool":"add_item","args":{}}',
        '{"message":"done"}',
      ]);

      final result = await AiAgent(
        client: client,
        tools: namespacedTools('shopping', [_tool('add_item')]),
      ).run('add milk');

      // call.name is what the model emitted, so a bare call stays bare --
      // what matters is that it resolved to the shopping tool and ran.
      expect(result.steps.single.result, 'ran add_item');
      expect(result.steps.single.failed, isFalse);
    });
  });
}
