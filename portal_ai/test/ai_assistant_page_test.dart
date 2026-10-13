import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portal_ai/portal_ai.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

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

/// The network is down until it is handed a reply.
class _FlakyClient implements AiCompletionClient {
  final replies = <String>[];

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<String> complete({
    required String systemPrompt,
    required String userPrompt,
    AiSamplerConfig sampler = const AiSamplerConfig(),
    bool jsonMode = false,
  }) async {
    if (replies.isEmpty) throw const SocketException('Failed host lookup');
    return replies.removeAt(0);
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

/// Starts an answer, then loses the connection under it.
class _CutOffClient extends _FlakyClient {
  @override
  Stream<String> completeStream({
    required String systemPrompt,
    required String userPrompt,
    AiSamplerConfig sampler = const AiSamplerConfig(),
  }) async* {
    yield '{"final": "partial';
    throw const SocketException('Connection reset by peer');
  }
}

/// Answers "Answer 1", "Answer 2", ... once [gate] opens, so a test can look
/// at the page while the reply is still on its way. Starts open.
class _GatedClient implements AiCompletionClient {
  var gate = Completer<void>()..complete();
  var _answers = 0;

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<String> complete({
    required String systemPrompt,
    required String userPrompt,
    AiSamplerConfig sampler = const AiSamplerConfig(),
    bool jsonMode = false,
  }) async => '{"title":"A chat"}';

  @override
  Stream<String> completeStream({
    required String systemPrompt,
    required String userPrompt,
    AiSamplerConfig sampler = const AiSamplerConfig(),
  }) async* {
    await gate.future;
    yield '{"final":"Answer ${++_answers}"}';
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
        name: 'delete_item',
        description: 'Delete an item.',
        parameters: const {'id': 'item id'},
        mutates: true,
        preview: (call) async {
          final id = call.argString('id');
          final name = basket.firstWhere(
            (item) => 'id-$item' == id,
            orElse: () => '',
          );
          return name.isEmpty ? null : AiItem(id: id, title: name);
        },
        run: (call) async {
          basket.removeWhere((item) => 'id-$item' == call.argString('id'));
          return 'deleted';
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
                AiItem(id: 'id-$item', title: item, subtitle: 'in the basket'),
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
        theme: buildPortalTheme(brightness: Brightness.light),
        home: Scaffold(
          body: AiAssistantPage(
            runtime: runtime,
            suggestions: AiSuggestion.prompts(const ['Add milk']),
          ),
        ),
      ),
    );
  }

  setUp(() => basket = <String>[]);

  testWidgets('suggestion cards show before the first run', (tester) async {
    await pumpSheet(tester, runtimeWith(const ['{"final":"done"}']));

    expect(find.text('Assistant'), findsOneWidget);
    expect(find.widgetWithText(AiSuggestionCards, 'Add milk'), findsOneWidget);
  });

  testWidgets('allowing a mutating tool runs it and logs the step', (
    tester,
  ) async {
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
    expect(find.text('Add item'), findsOneWidget);
    expect(find.text('Accept'), findsOneWidget);
    expect(basket, isEmpty);

    await tester.tap(find.text('Accept'));
    await tester.pumpAndSettle();

    expect(basket, ['Milk']);
    expect(find.text('added Milk'), findsOneWidget);
    expect(find.text('Added milk to your list.'), findsOneWidget);
  });

  testWidgets('a mutating tool asks with the row, not the id', (tester) async {
    basket.add('Milk');
    await pumpSheet(
      tester,
      runtimeWith(const [
        '{"tool":"delete_item","args":{"id":"id-Milk"}}',
        '{"final":"Gone."}',
      ]),
    );

    await tester.enterText(find.byType(TextField), 'delete the milk');
    await tester.testTextInput.receiveAction(TextInputAction.send);
    await tester.pump();

    // Nobody recognises a record by its id, so the card names the row the
    // tool resolved and drops the argument dump that held the id.
    expect(find.text('Milk'), findsOneWidget);
    expect(find.text('id-Milk'), findsNothing);

    await tester.tap(find.text('Accept'));
    await tester.pumpAndSettle();
    expect(basket, isEmpty);
  });

  testWidgets('skipping a mutating tool leaves state untouched', (
    tester,
  ) async {
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

    await tester.tap(find.text('Decline'));
    await tester.pumpAndSettle();

    expect(basket, isEmpty);
    // The step log shows the user their own refusal, not the sentence the
    // model was handed.
    expect(find.text('Declined'), findsOneWidget);
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

    expect(find.text('Accept'), findsNothing);
    expect(find.text('Bread'), findsOneWidget);
    expect(find.text('You have bread.'), findsOneWidget);
  });

  testWidgets('a rich result renders as rows, not as its raw text', (
    tester,
  ) async {
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

  testWidgets('a confirmation shows the arguments in words, not as JSON', (
    tester,
  ) async {
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

  testWidgets('tapping a row hands the host the entity and the record', (
    tester,
  ) async {
    basket.add('Bread');
    final tapped = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        theme: buildPortalTheme(brightness: Brightness.light),
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

  testWidgets('rows with no entity stay inert even with a handler', (
    tester,
  ) async {
    basket.add('Bread');
    final tapped = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        theme: buildPortalTheme(brightness: Brightness.light),
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

  testWidgets('reasoning is folded away, not shown as the answer', (
    tester,
  ) async {
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

  testWidgets(
    'a failed question can be retried, and succeeds the second time',
    (tester) async {
      // The first attempt has nothing to reply with; the retry does.
      final client = _ScriptedClient(const []);
      await tester.pumpWidget(
        MaterialApp(
          theme: buildPortalTheme(brightness: Brightness.light),
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
    },
  );

  /// A page that keeps its thread, over [client].
  Future<_MemoryStore> pumpKept(
    WidgetTester tester,
    AiCompletionClient client, {
    _MemoryStore? store,
    Widget? avatar,
  }) async {
    final kept = store ?? _MemoryStore();
    await tester.pumpWidget(
      MaterialApp(
        theme: buildPortalTheme(brightness: Brightness.light),
        home: Scaffold(
          body: AiAssistantPage(
            runtime: PortalAiRuntime(client: client),
            store: kept,
            avatar: avatar,
          ),
        ),
      ),
    );
    return kept;
  }

  Future<void> ask(WidgetTester tester, String question) async {
    await tester.enterText(find.byType(TextField), question);
    await tester.testTextInput.receiveAction(TextInputAction.send);
  }

  bool assistantBubble(Widget w) =>
      w is PortalChatBubble && w.author == PortalChatAuthor.assistant;

  testWidgets('offline before anything arrives: the question is Not sent', (
    tester,
  ) async {
    final client = _FlakyClient();
    await pumpKept(tester, client);

    await ask(tester, 'plan dinners');
    await tester.pumpAndSettle();

    // The mark sits under the question; there is no reply to hang one on.
    expect(find.textContaining('Not sent', findRichText: true), findsOneWidget);
    expect(find.text('plan dinners'), findsOneWidget);
    expect(find.byWidgetPredicate(assistantBubble), findsNothing);
    expect(tester.widget<TextField>(find.byType(TextField)).enabled, isTrue);
    expect(find.text("Can't reach"), findsOneWidget);

    client.replies.add('{"final":"Here is a plan."}');
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(find.text('Here is a plan.'), findsOneWidget);
    expect(find.textContaining('Not sent', findRichText: true), findsNothing);
    expect(find.text("Can't reach"), findsNothing);
    // Asked once, not left behind twice.
    expect(find.text('plan dinners'), findsOneWidget);
  });

  testWidgets('a reply cut off mid-flight keeps its words and offers Retry', (
    tester,
  ) async {
    await pumpKept(tester, _CutOffClient());

    await ask(tester, 'plan dinners');
    await tester.pumpAndSettle();

    // It got somewhere, so this is not "Not sent" even though the network
    // is why it stopped.
    expect(find.textContaining('partial'), findsOneWidget);
    expect(find.textContaining('Not sent', findRichText: true), findsNothing);
    expect(find.text('Retry'), findsOneWidget);
    expect(
      find.textContaining('No connection', findRichText: true),
      findsOneWidget,
    );
    expect(find.byTooltip('Copy reply'), findsNothing);
  });

  testWidgets('the foot says Writing while the reply is coming', (
    tester,
  ) async {
    final client = _GatedClient()..gate = Completer<void>();
    await pumpKept(tester, client);

    await ask(tester, 'hello');
    await tester.pump();

    // No text yet, and the foot already says so. pump, never settle: the
    // shimmer on the word loops for as long as the reply does.
    expect(find.text('Writing'), findsOneWidget);
    expect(find.byTooltip('Copy reply'), findsNothing);

    client.gate.complete();
    await tester.pumpAndSettle();

    expect(find.text('Answer 1'), findsOneWidget);
    expect(find.text('Writing'), findsNothing);
    expect(find.byTooltip('Copy reply'), findsOneWidget);
  });

  testWidgets('a proposed change makes the foot say Waiting for you', (
    tester,
  ) async {
    await pumpSheet(
      tester,
      runtimeWith(const [
        '{"tool":"add_item","args":{"name":"Milk"}}',
        '{"final":"Added."}',
      ]),
    );

    await ask(tester, 'add milk');
    await tester.pump();

    expect(find.text('Waiting for you'), findsOneWidget);
    expect(find.text('Writing'), findsNothing);
    // Typing now is the correction, and the field says so.
    expect(find.text('Type a change…'), findsOneWidget);

    await tester.tap(find.text('Accept'));
    await tester.pumpAndSettle();
    expect(find.text('Waiting for you'), findsNothing);
  });

  testWidgets('a host that is busy shows Writing before any text', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildPortalTheme(brightness: Brightness.light),
        home: Scaffold(
          body: AiAssistantPage(
            turns: const [AiChatTurn(role: 'user', content: 'plan my week')],
            onSend: (_) async {},
            busy: true,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Writing'), findsOneWidget);
  });

  testWidgets('every reply carries its own mark in the foot, no gutter', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildPortalTheme(brightness: Brightness.light),
        home: Scaffold(
          body: AiAssistantPage(
            avatar: const Icon(Icons.face),
            turns: const [
              AiChatTurn(role: 'user', content: 'plan my week'),
              AiChatTurn(role: 'assistant', content: 'Monday is clear.'),
              AiChatTurn(role: 'assistant', content: 'Tuesday is not.'),
            ],
            onSend: (_) async {},
          ),
        ),
      ),
    );

    // The header, plus the foot of each of the two replies.
    expect(find.byIcon(Icons.face), findsNWidgets(3));
  });

  testWidgets('only the newest reply can be regenerated', (tester) async {
    await pumpKept(tester, _GatedClient());

    for (final question in ['first', 'second']) {
      await ask(tester, question);
      await tester.pumpAndSettle();
    }
    expect(find.byTooltip('Copy reply'), findsNWidgets(2));
    expect(find.byTooltip('Regenerate reply'), findsOneWidget);

    await tester.tap(find.byTooltip('Regenerate reply'));
    await tester.pumpAndSettle();

    // The second answer is redone in place; the first is untouched.
    expect(find.text('Answer 1'), findsOneWidget);
    expect(find.text('Answer 2'), findsNothing);
    expect(find.text('Answer 3'), findsOneWidget);
    expect(find.text('second'), findsOneWidget);
  });

  testWidgets('a change that went through leaves a receipt, and keeps it', (
    tester,
  ) async {
    final store = _MemoryStore();
    await tester.pumpWidget(
      MaterialApp(
        theme: buildPortalTheme(brightness: Brightness.light),
        home: Scaffold(
          body: AiAssistantPage(
            runtime: runtimeWith(const [
              '{"tool":"add_item","args":{"name":"Milk"}}',
              '{"final":"Added milk to your list."}',
            ]),
            store: store,
          ),
        ),
      ),
    );

    await ask(tester, 'add milk');
    await tester.pump();
    await tester.tap(find.text('Accept'));
    await tester.pumpAndSettle();

    // Once the live step lines are gone, the receipt is what says it ran.
    expect(find.text('Add item'), findsOneWidget);
    final saved = store.load(store.listSummaries().single.id)!;
    expect(saved.turns.last.payload?['tools'], [
      {'name': 'add_item', 'failed': false, 'mutates': true},
    ]);
  });

  testWidgets(
    'a reload draws receipts from the saved tools, and survives none',
    (tester) async {
      final store = _MemoryStore();
      Future<void> save(String id, Object? tools) => store.save(
        AiChatSession(
          id: id,
          title: id,
          createdAt: DateTime(2026, 10, 1),
          updatedAt: DateTime(2026, 10, 1),
          turns: [
            const AiChatTurn(role: 'user', content: 'add milk'),
            AiChatTurn(
              role: 'assistant',
              content: 'Done.',
              payload: {'tools': ?tools},
            ),
          ],
        ),
      );
      Future<void> open(String id) => tester.pumpWidget(
        MaterialApp(
          theme: buildPortalTheme(brightness: Brightness.light),
          home: Scaffold(
            body: AiAssistantPage(
              key: UniqueKey(),
              runtime: PortalAiRuntime(client: _ScriptedClient(const [])),
              store: store,
              initialSessionId: id,
            ),
          ),
        ),
      );

      await save('ran', [
        {'name': 'add_item', 'failed': false, 'mutates': true},
        // Neither of these changed anything, so neither earns a receipt.
        {'name': 'list_items', 'failed': false, 'mutates': false},
        {'name': 'delete_item', 'failed': true, 'mutates': true},
      ]);
      await open('ran');
      expect(find.text('Add item'), findsOneWidget);
      expect(find.text('List items'), findsNothing);
      expect(find.text('Delete item'), findsNothing);

      // A thread from before turns recorded tools, and one with junk in the key.
      await save('old', null);
      await open('old');
      expect(find.text('Done.'), findsOneWidget);
      expect(find.text('Add item'), findsNothing);

      await save('odd', [
        'oops',
        3,
        {'name': 5, 'mutates': true},
        <String, Object?>{},
      ]);
      await open('odd');
      expect(tester.takeException(), isNull);
      expect(find.text('Done.'), findsOneWidget);
      expect(find.text('Add item'), findsNothing);

      await save('worse', 'not a list');
      await open('worse');
      expect(tester.takeException(), isNull);
      expect(find.text('Done.'), findsOneWidget);
    },
  );

  testWidgets('a new calendar day gets a stamp between turns', (tester) async {
    final now = DateTime.now();
    final earlier = now.subtract(const Duration(days: 3));
    await tester.pumpWidget(
      MaterialApp(
        theme: buildPortalTheme(brightness: Brightness.light),
        home: Scaffold(
          body: AiAssistantPage(
            turns: [
              AiChatTurn(role: 'user', content: 'old question', at: earlier),
              AiChatTurn(role: 'assistant', content: 'old answer', at: earlier),
              AiChatTurn(role: 'user', content: 'new question', at: now),
              AiChatTurn(role: 'assistant', content: 'new answer', at: now),
            ],
            onSend: (_) async {},
          ),
        ),
      ),
    );

    // One break, between the two days -- not before the first turn, and not
    // between turns of the same day.
    expect(find.text('Today'), findsOneWidget);
    expect(find.textContaining('old question'), findsOneWidget);
  });

  testWidgets('editing the last question puts it back in the composer', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildPortalTheme(brightness: Brightness.light),
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

    // Actions live behind a long-press on the bubble, not a standing button.
    await tester.longPress(find.text('plan dinners'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();

    expect(
      tester.widget<TextField>(find.byType(TextField)).controller?.text,
      'plan dinners',
    );
    // The turn and its answer are gone, not duplicated below the edit.
    expect(find.text('Sure.'), findsNothing);
  });

  testWidgets(
    'deleting the last question drops it without touching the composer',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildPortalTheme(brightness: Brightness.light),
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

      await tester.longPress(find.text('plan dinners'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      // Gone, and the composer was never touched.
      expect(find.text('plan dinners'), findsNothing);
      expect(find.text('Sure.'), findsNothing);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller?.text,
        '',
      );
    },
  );

  testWidgets('fresh ideas join the deck, and a failure keeps the old ones', (
    tester,
  ) async {
    final client = _ScriptedClient(const [
      '{"prompts":["Plan a roast","Use up leftovers"]}',
    ]);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildPortalTheme(brightness: Brightness.light),
        home: Scaffold(
          body: AiAssistantPage(
            runtime: PortalAiRuntime(client: client),
            suggestions: AiSuggestion.prompts(const ['Add milk']),
          ),
        ),
      ),
    );

    await tester.tap(find.text('More ideas'));
    await tester.pumpAndSettle();

    expect(find.text('Plan a roast'), findsOneWidget);
    // Merged, not swapped: the app's own prompt is curated copy and the model
    // has no way to know it was worth keeping.
    expect(find.text('Add milk'), findsOneWidget);

    // Script exhausted: what is on screen survives.
    await tester.tap(find.text('More ideas'));
    await tester.pumpAndSettle();
    expect(find.text('Plan a roast'), findsOneWidget);
  });

  testWidgets('an unaccepted consent card gates the composer', (tester) async {
    var accepted = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildPortalTheme(brightness: Brightness.light),
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => AiAssistantPage(
              runtime: PortalAiRuntime(client: _ScriptedClient(const [])),
              suggestions: AiSuggestion.prompts(const ['Add milk']),
              consent: AiConsent(
                accepted: accepted,
                onAccept: () => setState(() => accepted = true),
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.byType(AiConsentCard), findsOneWidget);
    expect(tester.widget<TextField>(find.byType(TextField)).enabled, isFalse);

    await tester.tap(find.text('Accept and continue'));
    await tester.pumpAndSettle();

    expect(find.byType(AiConsentCard), findsNothing);
    expect(tester.widget<TextField>(find.byType(TextField)).enabled, isTrue);
  });

  testWidgets('initialSessionId opens that thread; resume still opens newest', (
    tester,
  ) async {
    final store = _MemoryStore();
    for (final (id, day) in [('a', 1), ('b', 2)]) {
      await store.save(
        AiChatSession(
          id: id,
          title: id,
          createdAt: DateTime(2026, 10, day),
          updatedAt: DateTime(2026, 10, day),
          turns: [AiChatTurn(role: 'user', content: 'question $id')],
        ),
      );
    }
    // A fresh key each time: pumping the same type again would update the old
    // State and never run initState.
    Future<void> open({String? id, bool resume = false}) => tester.pumpWidget(
      MaterialApp(
        theme: buildPortalTheme(brightness: Brightness.light),
        home: Scaffold(
          body: AiAssistantPage(
            key: UniqueKey(),
            runtime: PortalAiRuntime(client: _ScriptedClient(const [])),
            store: store,
            resumeLastSession: resume,
            initialSessionId: id,
          ),
        ),
      ),
    );

    await open(resume: true);
    expect(find.text('question b'), findsOneWidget);

    // The picked thread wins over "newest".
    await open(id: 'a', resume: true);
    expect(find.text('question a'), findsOneWidget);
    expect(find.text('question b'), findsNothing);

    // A thread deleted since the list was drawn opens blank, not as another one.
    await open(id: 'gone', resume: true);
    expect(find.textContaining('question'), findsNothing);
  });

  testWidgets('picking a persona swaps the opening deck to its prompts', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildPortalTheme(brightness: Brightness.light),
        home: Scaffold(
          body: AiAssistantPage(
            runtime: PortalAiRuntime(client: _ScriptedClient(const [])),
            suggestions: AiSuggestion.prompts(const ['Add milk']),
            personas: const [
              AiPersona(
                id: 'writer',
                label: 'Writer',
                description: 'writing',
                suggestions: [AiSuggestion(prompt: 'Draft an email')],
              ),
            ],
          ),
        ),
      ),
    );

    // Auto shows the app's own deck.
    expect(find.widgetWithText(AiSuggestionCards, 'Add milk'), findsOneWidget);
    expect(
      find.widgetWithText(AiSuggestionCards, 'Draft an email'),
      findsNothing,
    );

    // Pinning Writer swaps the deck to the persona's starter prompts.
    await tester.tap(find.text('Writer'));
    await tester.pumpAndSettle();
    expect(
      find.widgetWithText(AiSuggestionCards, 'Draft an email'),
      findsOneWidget,
    );
    expect(find.widgetWithText(AiSuggestionCards, 'Add milk'), findsNothing);
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
