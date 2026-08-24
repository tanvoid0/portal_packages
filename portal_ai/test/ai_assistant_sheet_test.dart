import 'package:flutter/material.dart';
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
        usesLocalModel: false,
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
        ],
      );

  Future<void> pumpSheet(WidgetTester tester, PortalAiRuntime runtime) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AiAssistantSheet(
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

  testWidgets('a backend failure surfaces instead of hanging', (tester) async {
    await pumpSheet(tester, runtimeWith(const []));

    await tester.enterText(find.byType(TextField), 'anything');
    await tester.testTextInput.receiveAction(TextInputAction.send);
    await tester.pumpAndSettle();

    expect(find.textContaining('script exhausted'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}
