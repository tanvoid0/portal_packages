import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portal_ai/portal_ai.dart';

/// Replies with one tool call, then a final message.
class _Scripted implements AiCompletionClient {
  _Scripted(this.replies);
  final List<String> replies;
  var _i = 0;

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<String> complete({
    required String systemPrompt,
    required String userPrompt,
    AiSamplerConfig sampler = const AiSamplerConfig(),
    bool jsonMode = false,
  }) async => replies[_i++ % replies.length];

  @override
  Stream<String> completeStream({
    required String systemPrompt,
    required String userPrompt,
    AiSamplerConfig sampler = const AiSamplerConfig(),
    bool jsonMode = false,
  }) async* {
    yield await complete(systemPrompt: systemPrompt, userPrompt: userPrompt);
  }
}

AiTool _addItem(List<String> into) => AiTool(
  name: 'add_item',
  description: 'Adds an item.',
  parameters: const {'name': 'what to add'},
  mutates: true,
  run: (call) async {
    into.add(call.argString('name') ?? '');
    return 'added';
  },
);

Future<void> _pump(
  WidgetTester tester,
  PortalAiRuntime runtime, {
  Future<bool> Function(AiToolCall call)? onEdit,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: AiAssistantPage(runtime: runtime, onEditToolCall: onEdit),
      ),
    ),
  );
}

Future<void> _ask(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(TextField).last, text);
  await tester.testTextInput.receiveAction(TextInputAction.send);
  await tester.pump();
}

void main() {
  testWidgets('typing while a card is open corrects it instead of stopping', (
    tester,
  ) async {
    final added = <String>[];
    final runtime = PortalAiRuntime(
      client: _Scripted([
        '{"tool":"add_item","args":{"name":"Milk"}}',
        '{"tool":"add_item","args":{"name":"Oat milk"}}',
        '{"final":"Added oat milk."}',
      ]),
      tools: [_addItem(added)],
    );
    await _pump(tester, runtime);

    await _ask(tester, 'add milk');
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('Add item'), findsOneWidget);
    expect(find.text('Milk'), findsOneWidget);

    // The composer stays live: the run is waiting on the user, not busy.
    await _ask(tester, 'make it oat milk');
    await tester.pump(const Duration(milliseconds: 50));

    // The first call was declined with the correction; what waits now is the
    // model's revised proposal, and nothing has been written.
    expect(added, isEmpty);
    expect(find.text('Oat milk'), findsOneWidget);

    await tester.tap(find.text('Accept'));
    await tester.pump(const Duration(milliseconds: 50));
    expect(added, ['Oat milk']);
  });

  testWidgets('no Edit button without an app form to open', (tester) async {
    final runtime = PortalAiRuntime(
      client: _Scripted([
        '{"tool":"add_item","args":{"name":"Milk"}}',
        '{"final":"done"}',
      ]),
      tools: [_addItem([])],
    );
    await _pump(tester, runtime);
    await _ask(tester, 'add milk');
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Accept'), findsOneWidget);
    expect(find.text('Edit'), findsNothing);
  });

  testWidgets('saving in the app form counts as done, so the tool never runs', (
    tester,
  ) async {
    final added = <String>[];
    AiToolCall? edited;
    final runtime = PortalAiRuntime(
      client: _Scripted([
        '{"tool":"add_item","args":{"name":"Milk"}}',
        '{"final":"done"}',
      ]),
      tools: [_addItem(added)],
    );
    await _pump(
      tester,
      runtime,
      onEdit: (call) async {
        edited = call;
        return true;
      },
    );
    await _ask(tester, 'add milk');
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(find.text('Edit'));
    await tester.pump(const Duration(milliseconds: 50));

    expect(edited?.argString('name'), 'Milk');
    expect(added, isEmpty);
  });
}
