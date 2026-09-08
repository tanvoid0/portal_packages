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

void main() {
  group('blocks survive persistence', () {
    test('a block round-trips through JSON with its actions', () {
      const block = AiBlock(
        kind: 'finance.spending_chart',
        data: {'total': 42},
        actions: [
          AiAction(
            label: 'Add to list',
            tool: 'shopping.add_item',
            args: {'name': 'milk'},
          ),
        ],
      );

      final restored = AiBlock.fromJson(block.toJson());

      expect(restored.kind, 'finance.spending_chart');
      expect(restored.data['total'], 42);
      expect(restored.actions.single.tool, 'shopping.add_item');
      expect(restored.actions.single.args['name'], 'milk');
    });

    test('a malformed block decodes to empty rather than throwing', () {
      // An old thread can hold anything; a reload must not crash on it.
      final restored = AiBlock.fromJson(const {});

      expect(restored.kind, '');
      expect(restored.data, isEmpty);
      expect(restored.actions, isEmpty);
    });
  });

  _resolutionTests();

  group('the agent surfacing blocks', () {
    AiTool richTool() => AiTool(
      name: 'spending',
      description: 'shows spending',
      run: (_) async => 'unused',
      runRich: (_) async => const AiToolResult(
        forModel: 'spent 42',
        blocks: [AiBlock(kind: 'finance.spending_chart')],
      ),
    );

    test('runRich supplies both the model text and the blocks', () async {
      final client = _ScriptedClient([
        '{"tool":"spending","args":{}}',
        '{"message":"done"}',
      ]);

      final result = await AiAgent(
        client: client,
        tools: [richTool()],
      ).run('spending?');

      // The model sees the text, the user sees the block.
      expect(result.steps.single.result, 'spent 42');
      expect(result.steps.single.blocks.single.kind, 'finance.spending_chart');
    });

    test('a plain tool still works and yields no blocks', () async {
      final client = _ScriptedClient([
        '{"tool":"plain","args":{}}',
        '{"message":"done"}',
      ]);
      final plain = AiTool(
        name: 'plain',
        description: 'plain',
        run: (_) async => 'ok',
      );

      final result = await AiAgent(client: client, tools: [plain]).run('go');

      expect(result.steps.single.result, 'ok');
      expect(result.steps.single.blocks, isEmpty);
    });

    test('namespacing carries runRich across with it', () async {
      final tool = namespacedTools('finance', [richTool()]).single;

      expect(tool.qualifiedName, 'finance.spending');
      expect(tool.runRich, isNotNull);
    });
  });
}

// Resolution is shared by the agent and by action buttons; if these two drift
// apart a button can write a different app's data than the model would have.
void _resolutionTests() {
  group('resolveTool', () {
    final tools = [
      ...namespacedTools('shopping', [
        AiTool(name: 'add_item', description: 'x', run: (_) async => 'a'),
      ]),
      ...namespacedTools('lifestyle', [
        AiTool(name: 'add_item', description: 'x', run: (_) async => 'b'),
      ]),
    ];

    test('a qualified name resolves to that app', () {
      expect(resolveTool(tools, 'lifestyle.add_item')?.namespace, 'lifestyle');
    });

    test('an ambiguous bare name resolves to nothing', () {
      expect(resolveTool(tools, 'add_item'), isNull);
    });

    test('an unknown name resolves to nothing', () {
      expect(resolveTool(tools, 'nope'), isNull);
    });
  });
}
