import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portal_ai/portal_ai.dart';

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

/// The refusal string is written for the model; the step log is read by the
/// user, and used to print it word for word.
void main() {
  testWidgets('a correction is not read back as third-person tool output',
      (tester) async {
    final runtime = PortalAiRuntime(
      client: _Scripted([
        '{"tool":"add_item","args":{"name":"Milk"}}',
        '{"final":"ok"}',
      ]),
      tools: [
        AiTool(
          name: 'add_item',
          description: 'Adds an item.',
          parameters: const {'name': 'what to add'},
          mutates: true,
          run: (call) async => 'added',
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: AiAssistantPage(runtime: runtime))),
    );
    await tester.enterText(find.byType(TextField).last, 'add milk');
    await tester.testTextInput.receiveAction(TextInputAction.send);
    await tester.pump(const Duration(milliseconds: 50));

    await tester.enterText(find.byType(TextField).last, 'make it oat milk');
    await tester.testTextInput.receiveAction(TextInputAction.send);
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.textContaining('user declined this action'), findsNothing);
    expect(find.textContaining('Declined'), findsOneWidget);
  });
}
