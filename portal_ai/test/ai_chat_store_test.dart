import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portal_ai/portal_ai.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

void main() {
  _turnMetadataTests();

  TestWidgetsFlutterBinding.ensureInitialized();

  Future<PrefsAiChatStore> freshStore() async {
    SharedPreferences.setMockInitialValues({});
    return PrefsAiChatStore.open('portal_test_ai_chat');
  }

  test('a session round-trips, host payload untouched', () async {
    final store = await freshStore();
    await store.save(
      AiChatSession(
        id: 's1',
        title: 'Leg day',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 2),
        turns: const [
          AiChatTurn(role: 'user', content: 'plan legs'),
          AiChatTurn(
            role: 'assistant',
            content: 'done',
            payload: {'anything': 42},
          ),
        ],
        payload: const {'plan_date': '2026-01-02'},
      ),
    );

    final loaded = store.load('s1')!;
    expect(loaded.title, 'Leg day');
    expect(loaded.turns.last.payload, {'anything': 42});
    expect(loaded.payload['plan_date'], '2026-01-02');
    expect(store.listSummaries().single.turnCount, 2);
  });

  testWidgets('the sheet keeps the thread and refines against it', (
    tester,
  ) async {
    final store = await freshStore();
    final client = _ScriptedClient([
      '{"tool": "list_items", "args": {}}',
      '{"final": "milk and eggs"}',
      '{"final": "just milk then"}',
    ]);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AiAssistantPage(
            store: store,
            runtime: PortalAiRuntime(
              client: client,

              appDescription: 'A shopping list.',
              tools: [
                AiTool(
                  name: 'list_items',
                  description: 'List the items.',
                  runRich: (_) async => const AiToolResult(
                    forModel: 'milk, eggs',
                    blocks: [
                      AiBlock(kind: 'shopping.list', data: {'count': 2}),
                    ],
                  ),
                  run: (_) async => 'milk, eggs',
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), 'what is on my list');
    await tester.testTextInput.receiveAction(TextInputAction.send);
    await tester.pumpAndSettle();

    expect(find.text('what is on my list'), findsOneWidget);
    expect(find.text('milk and eggs'), findsOneWidget);
    // No renderer registered, so the block falls back to its kind.
    expect(find.text('shopping.list'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'drop the eggs');
    await tester.testTextInput.receiveAction(TextInputAction.send);
    await tester.pumpAndSettle();

    expect(
      client.prompts.last,
      contains('Earlier in this conversation'),
      reason: 'the follow-up has to see what was already said',
    );
    expect(find.text('just milk then'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.history));
    await tester.pumpAndSettle();
    expect(find.text('4 messages'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    final saved = store.listSummaries().single;
    expect(saved.title, 'what is on my list');
    expect(saved.turnCount, 4);
    final turns = store.load(saved.id)!.turns;
    expect(turns[1].payload!['blocks'], hasLength(1));

    // Deleting the open thread clears the sheet and empties the store.
    await tester.tap(find.byIcon(Icons.history));
    await tester.pumpAndSettle();
    // Scoped to the sheet: the chat header now carries an overflow menu of
    // its own, so a bare byIcon matches two.
    await tester.tap(
      find.descendant(
        of: find.byType(AiChatHistoryList),
        matching: find.byIcon(Icons.more_vert),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete').last);
    await tester.pumpAndSettle();
    // The list defers the delete until its undo window closes.
    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();

    expect(store.listSummaries(), isEmpty);
    expect(find.text('milk and eggs'), findsNothing);
  });

  testWidgets('a failed turn is kept, so a reload still shows the question', (
    tester,
  ) async {
    final store = await freshStore();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AiAssistantPage(
            store: store,
            runtime: PortalAiRuntime(
              client: _ScriptedClient(const []),

              appDescription: 'A shopping list.',
            ),
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), 'this will fail');
    await tester.testTextInput.receiveAction(TextInputAction.send);
    await tester.pumpAndSettle();

    final saved = store.listSummaries().single;
    expect(store.load(saved.id)!.turns.single.content, 'this will fail');
  });
}

void _turnMetadataTests() {
  test('a turn keeps its time and duration across a save and reload', () {
    final at = DateTime.utc(2026, 9, 1, 9, 14, 30);
    final turn = AiChatTurn(
      role: 'assistant',
      content: 'done',
      at: at,
      took: const Duration(milliseconds: 4200),
    );
    final back = aiChatTurnFromJson(turn.toJson());
    expect(back.at, at);
    expect(back.took, const Duration(milliseconds: 4200));
  });

  test('a turn saved before turns were stamped reloads without a time', () {
    final back = aiChatTurnFromJson({'role': 'user', 'content': 'hi'});
    expect(back.at, isNull);
    expect(back.took, isNull);
  });
}
