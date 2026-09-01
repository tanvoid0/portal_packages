import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portal_ai/portal_ai.dart';

/// The sheet needs a runtime, but nothing here ever asks the model.
class _DeadClient implements AiCompletionClient {
  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<String> complete({
    required String systemPrompt,
    required String userPrompt,
    AiSamplerConfig sampler = const AiSamplerConfig(),
    bool jsonMode = false,
  }) async =>
      throw const AiCompletionException('not used');

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
  late List<String> accepted;
  late List<String> discarded;

  const proposals = [
    AiProposal(id: 'a', title: 'Write the report', subtitle: 'Mon 09:00'),
    AiProposal(id: 'b', title: 'Book the flight', badge: 'Task'),
  ];

  Future<void> pump(WidgetTester tester) => tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AiAssistantSheet(
              runtime: PortalAiRuntime(
                client: _DeadClient(),

                appDescription: 'A planner.',
              ),
              proposals: proposals,
              onAcceptProposal: (p) => accepted.add(p.id),
              onDiscardProposal: (p) => discarded.add(p.id),
            ),
          ),
        ),
      );

  setUp(() {
    accepted = <String>[];
    discarded = <String>[];
  });

  testWidgets('accepting removes the card and fires once', (tester) async {
    await pump(tester);
    await tester.tap(find.text('Write the report'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();

    expect(accepted, ['a']);
    expect(find.text('Write the report'), findsNothing);
    expect(find.text('Book the flight'), findsOneWidget);
  });

  testWidgets('discarding does not accept', (tester) async {
    await pump(tester);
    await tester.tap(find.text('Write the report'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Discard'));
    await tester.pumpAndSettle();

    expect(discarded, ['a']);
    expect(accepted, isEmpty);
    expect(find.text('Write the report'), findsNothing);
  });

  testWidgets('add all accepts everything left, once each', (tester) async {
    await pump(tester);
    await tester.tap(find.text('Add all (2)'));
    await tester.pumpAndSettle();

    expect(accepted, ['a', 'b']);
    expect(find.text('Add all (2)'), findsNothing);
  });

  _hostDrivenTests();
}

/// The host-driven mode: no runtime, no agent, the app answers itself.
void _hostDrivenTests() {
  testWidgets('onSend takes over sending and turns render as bubbles',
      (tester) async {
    final sent = <String>[];
    var turns = <AiChatTurn>[];

    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) => Scaffold(
            body: AiAssistantSheet(
              turns: turns,
              onSend: (prompt) async {
                sent.add(prompt);
                setState(() {
                  turns = [
                    ...turns,
                    AiChatTurn(role: 'user', content: prompt),
                    const AiChatTurn(role: 'assistant', content: 'planned it'),
                  ];
                });
              },
            ),
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), 'plan my monday');
    await tester.testTextInput.receiveAction(TextInputAction.send);
    await tester.pumpAndSettle();

    expect(sent, ['plan my monday']);
    expect(find.text('plan my monday'), findsOneWidget);
    expect(find.text('planned it'), findsOneWidget);
  });
}
