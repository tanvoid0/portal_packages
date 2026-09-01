import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portal_ai/portal_ai.dart';

/// Replays a fixed script of model replies, one per turn.
class _ScriptedClient implements AiCompletionClient {
  _ScriptedClient(List<String> replies) : replies = List.of(replies);

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
    if (_index >= replies.length) {
      throw const AiCompletionException('script exhausted');
    }
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
  /// Stands in for real app state a tool mutates.
  late List<String> basket;

  PortalAiRuntime runtimeWith(List<String> replies) => PortalAiRuntime(
        client: _ScriptedClient(replies),

        appDescription: 'A shopping list.',
        tools: [
          AiTool(
            name: 'add_item',
            description: 'Add an item to the list.',
            parameters: const {'name': 'item name'},
            mutates: true,
            run: (call) async {
              basket.add(call.argString('name')!);
              return 'added ${call.argString('name')}';
            },
          ),
          AiTool(
            name: 'list_items',
            description: 'List the items.',
            run: (_) async => basket.isEmpty ? 'empty' : basket.join(', '),
          ),
          AiTool(
            name: 'show_items',
            description: 'List the items with pictures.',
            runRich: (_) async => AiToolResult(
              forModel: basket.join(', '),
              blocks: [
                AiBlock.items(entity: 'basket_item', [
                  for (final item in basket)
                    AiItem(
                      id: 'id-$item',
                      title: item,
                      subtitle: 'in the basket',
                    ),
                ]),
              ],
            ),
          ),
          AiTool(
            name: 'show_totals',
            description: 'Totals, which are not records.',
            runRich: (_) async => AiToolResult(
              forModel: '${basket.length} items',
              blocks: [
                AiBlock.items([
                  AiItem(title: 'Total', trailing: '${basket.length}'),
                ]),
              ],
            ),
          ),
        ],
      );

  Future<void> pumpSheet(WidgetTester tester, PortalAiRuntime runtime) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AiAssistantPage(
            runtime: runtime,
            suggestions: const ['Add milk'],
          ),
        ),
      ),
    );
  }

  setUp(() => basket = <String>[]);

  testWidgets('suggestion chips show before the first run', (tester) async {
    await pumpSheet(tester, runtimeWith(const ['{"final":"done"}']));

    expect(find.text('Assistant'), findsOneWidget);
    expect(find.widgetWithText(ActionChip, 'Add milk'), findsOneWidget);
  });

  testWidgets('allowing a mutating tool runs it and logs the step',
      (tester) async {
    await pumpSheet(
      tester,
      runtimeWith(const [
        '{"tool":"add_item","args":{"name":"Milk"}}',
        '{"final":"Added milk to your list."}',
      ]),
    );

    await tester.enterText(find.byType(TextField), 'add milk');
    await tester.testTextInput.receiveAction(TextInputAction.send);
    await tester.pump();

    // A tool that changes data must ask before it runs.
    expect(find.text('add item'), findsOneWidget);
    expect(find.text('Allow'), findsOneWidget);
    expect(basket, isEmpty);

    await tester.tap(find.text('Allow'));
    await tester.pumpAndSettle();

    expect(basket, ['Milk']);
    expect(find.text('added Milk'), findsOneWidget);
    expect(find.text('Added milk to your list.'), findsOneWidget);
  });

  testWidgets('skipping a mutating tool leaves state untouched',
      (tester) async {
    await pumpSheet(
      tester,
      runtimeWith(const [
        '{"tool":"add_item","args":{"name":"Milk"}}',
        '{"final":"Left it out."}',
      ]),
    );

    await tester.enterText(find.byType(TextField), 'add milk');
    await tester.testTextInput.receiveAction(TextInputAction.send);
    await tester.pump();

    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();

    expect(basket, isEmpty);
    expect(find.text('user declined this action'), findsOneWidget);
    expect(find.text('Left it out.'), findsOneWidget);
  });

  testWidgets('a read-only tool runs without asking', (tester) async {
    basket.add('Bread');
    await pumpSheet(
      tester,
      runtimeWith(const [
        '{"tool":"list_items","args":{}}',
        '{"final":"You have bread."}',
      ]),
    );

    await tester.enterText(find.byType(TextField), 'what is on my list');
    await tester.testTextInput.receiveAction(TextInputAction.send);
    await tester.pumpAndSettle();

    expect(find.text('Allow'), findsNothing);
    expect(find.text('Bread'), findsOneWidget);
    expect(find.text('You have bread.'), findsOneWidget);
  });

  testWidgets('a rich result renders as rows, not as its raw text',
      (tester) async {
    basket.add('Bread');
    await pumpSheet(
      tester,
      runtimeWith(const [
        '{"tool":"show_items","args":{}}',
        '{"final":"You have bread."}',
      ]),
    );

    await tester.enterText(find.byType(TextField), 'show my list');
    await tester.testTextInput.receiveAction(TextInputAction.send);
    await tester.pumpAndSettle();

    expect(find.byType(AiItemList), findsOneWidget);
    expect(find.text('in the basket'), findsOneWidget);
    // The block replaces the result dump rather than sitting under it.
    expect(find.text('Bread'), findsOneWidget);
  });

  testWidgets('a confirmation shows the arguments in words, not as JSON',
      (tester) async {
    await pumpSheet(
      tester,
      runtimeWith(const [
        '{"tool":"add_item","args":{"name":"Milk"}}',
        '{"final":"done"}',
      ]),
    );

    await tester.enterText(find.byType(TextField), 'add milk');
    await tester.testTextInput.receiveAction(TextInputAction.send);
    await tester.pump();

    expect(find.text('name'), findsOneWidget);
    expect(find.text('Milk'), findsOneWidget);
    expect(find.textContaining('{'), findsNothing);
  });

  testWidgets('tapping a row hands the host the entity and the record',
      (tester) async {
    basket.add('Bread');
    final tapped = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AiAssistantPage(
            runtime: runtimeWith(const [
              '{"tool":"show_items","args":{}}',
              '{"final":"There it is."}',
            ]),
            onItemTap: (entity, item) => tapped.add('$entity/${item.id}'),
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), 'show my list');
    await tester.testTextInput.receiveAction(TextInputAction.send);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Bread'));
    await tester.pumpAndSettle();

    expect(tapped, ['basket_item/id-Bread']);
  });

  testWidgets('rows with no entity stay inert even with a handler',
      (tester) async {
    basket.add('Bread');
    final tapped = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AiAssistantPage(
            runtime: runtimeWith(const [
              '{"tool":"show_totals","args":{}}',
              '{"final":"One item."}',
            ]),
            onItemTap: (entity, item) => tapped.add(entity),
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), 'how many');
    await tester.testTextInput.receiveAction(TextInputAction.send);
    await tester.pumpAndSettle();

    // An aggregate has nothing to open, so it offers no chevron and no tap.
    expect(find.byType(AiItemList), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right), findsNothing);
    await tester.tap(find.text('Total'));
    await tester.pumpAndSettle();
    expect(tapped, isEmpty);
  });

  testWidgets('reasoning is folded away, not shown as the answer',
      (tester) async {
    await pumpSheet(
      tester,
      runtimeWith(const [
        '<think>The user wants the list. I should call list_items.</think>'
            '{"final":"You have nothing."}',
      ]),
    );

    await tester.enterText(find.byType(TextField), 'what is on my list');
    await tester.testTextInput.receiveAction(TextInputAction.send);
    await tester.pumpAndSettle();

    // The tag never reaches the JSON parser, so the run finishes normally.
    expect(find.text('You have nothing.'), findsOneWidget);
    expect(find.byType(AiThinkingTile), findsOneWidget);
    // Collapsed by default: the reasoning is there to check, not to read.
    expect(find.textContaining('call list_items'), findsNothing);

    await tester.tap(find.text('Thought process'));
    await tester.pumpAndSettle();
    expect(find.textContaining('call list_items'), findsOneWidget);
  });

  testWidgets('a backend failure surfaces instead of hanging', (tester) async {
    await pumpSheet(tester, runtimeWith(const []));

    await tester.enterText(find.byType(TextField), 'anything');
    await tester.testTextInput.receiveAction(TextInputAction.send);
    await tester.pumpAndSettle();

    expect(find.textContaining('script exhausted'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('a failed question can be retried, and succeeds the second time',
      (tester) async {
    // The first attempt has nothing to reply with; the retry does.
    final client = _ScriptedClient(const []);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AiAssistantPage(
            runtime: PortalAiRuntime(client: client),
            store: _MemoryStore(),
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), 'plan dinners');
    await tester.testTextInput.receiveAction(TextInputAction.send);
    await tester.pumpAndSettle();
    expect(find.textContaining('script exhausted'), findsOneWidget);

    client.replies.add('{"final":"Here is a plan."}');
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(find.text('Here is a plan.'), findsOneWidget);
    expect(find.textContaining('script exhausted'), findsNothing);
    // The question is asked once, not left behind twice.
    expect(find.text('plan dinners'), findsOneWidget);
  });

  testWidgets('editing the last question puts it back in the composer',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AiAssistantPage(
            runtime: PortalAiRuntime(
              client: _ScriptedClient(['{"final":"Sure."}']),
            ),
            store: _MemoryStore(),
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), 'plan dinners');
    await tester.testTextInput.receiveAction(TextInputAction.send);
    await tester.pumpAndSettle();
    expect(find.text('Sure.'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.edit_outlined));
    await tester.pumpAndSettle();

    expect(
      tester.widget<TextField>(find.byType(TextField)).controller?.text,
      'plan dinners',
    );
    // The turn and its answer are gone, not duplicated below the edit.
    expect(find.text('Sure.'), findsNothing);
  });

  testWidgets('fresh ideas replace the chips, and a failure keeps the old ones',
      (tester) async {
    final client = _ScriptedClient(const [
      '{"prompts":["Plan a roast","Use up leftovers"]}',
    ]);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AiAssistantPage(
            runtime: PortalAiRuntime(client: client),
            suggestions: const ['Add milk'],
          ),
        ),
      ),
    );

    await tester.tap(find.widgetWithText(ActionChip, 'More ideas'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(ActionChip, 'Plan a roast'), findsOneWidget);
    expect(find.widgetWithText(ActionChip, 'Add milk'), findsNothing);

    // Script exhausted: the chips already on screen survive.
    await tester.tap(find.widgetWithText(ActionChip, 'More ideas'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(ActionChip, 'Plan a roast'), findsOneWidget);
  });
}

/// A store that keeps threads in memory, so the page records turns without
/// dragging shared_preferences into a widget test.
class _MemoryStore implements AiChatStore {
  final _sessions = <String, AiChatSession>{};

  @override
  List<AiChatSessionSummary> listSummaries() => [
        for (final s in _sessions.values)
          AiChatSessionSummary(
            id: s.id,
            title: s.title,
            updatedAt: s.updatedAt,
            turnCount: s.turns.length,
          ),
      ];

  @override
  AiChatSession? load(String id) => _sessions[id];

  @override
  Future<void> save(AiChatSession session) async =>
      _sessions[session.id] = session;

  @override
  Future<void> delete(String id) async => _sessions.remove(id);
}
