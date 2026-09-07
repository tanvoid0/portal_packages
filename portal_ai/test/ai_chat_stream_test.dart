import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portal_ai/portal_ai.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Hands back one reply, in pieces, so the page has something to render mid
/// generation.
class _DrippingClient implements AiCompletionClient {
  _DrippingClient(this.chunks);

  final List<String> chunks;

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<String> complete({
    required String systemPrompt,
    required String userPrompt,
    AiSamplerConfig sampler = const AiSamplerConfig(),
    bool jsonMode = false,
  }) async => chunks.join();

  @override
  Stream<String> completeStream({
    required String systemPrompt,
    required String userPrompt,
    AiSamplerConfig sampler = const AiSamplerConfig(),
  }) async* {
    for (final chunk in chunks) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
      yield chunk;
    }
  }
}

Widget _page(AiCompletionClient client, {AiChatStore? store}) => MaterialApp(
  home: Scaffold(
    body: AiAssistantPage(
      title: 'Assistant',
      store: store,
      runtime: PortalAiRuntime(
        client: client,
        tools: const [],
        appDescription: 'A test app.',
      ),
    ),
  ),
);

void main() {
  testWidgets('the answer renders while it is still being written', (
    tester,
  ) async {
    await tester.pumpWidget(
      _page(_DrippingClient(['{"final": "one ', 'two ', 'three"}'])),
    );

    await tester.enterText(find.byType(TextField), 'hello');
    await tester.testTextInput.receiveAction(TextInputAction.send);
    await tester.pump();

    await tester.pump(const Duration(milliseconds: 15));
    expect(find.textContaining('one'), findsOneWidget);
    // Still generating: the JSON wrapper never reaches the screen.
    expect(find.textContaining('{'), findsNothing);

    await tester.pump(const Duration(milliseconds: 15));
    expect(find.textContaining('one two'), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.textContaining('one two three'), findsOneWidget);
  });

  testWidgets('the composer keeps focus after a send', (tester) async {
    await tester.pumpWidget(_page(_DrippingClient(['{"final": "done"}'])));

    await tester.enterText(find.byType(TextField), 'hello');
    await tester.testTextInput.receiveAction(TextInputAction.send);
    await tester.pumpAndSettle();

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.focusNode?.hasFocus, isTrue);
  });

  testWidgets('an answer can be copied out', (tester) async {
    final clipboard = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          clipboard.add((call.arguments as Map)['text'] as String);
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );

    SharedPreferences.setMockInitialValues({});
    // A turn only exists in store mode; without one there is nothing to copy.
    final store = await PrefsAiChatStore.open('portal_test_stream');
    await tester.pumpWidget(
      _page(_DrippingClient(['{"final": "the answer"}']), store: store),
    );
    await tester.enterText(find.byType(TextField), 'hello');
    await tester.testTextInput.receiveAction(TextInputAction.send);
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.copy_outlined));
    await tester.pumpAndSettle();

    expect(clipboard, ['the answer']);
  });

  testWidgets('an older question can be reworked, once confirmed', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final store = await PrefsAiChatStore.open('portal_test_rewind');
    await tester.pumpWidget(
      _page(_DrippingClient(['{"final": "an answer"}']), store: store),
    );

    for (final question in ['first question', 'second question']) {
      await tester.enterText(find.byType(TextField), question);
      await tester.testTextInput.receiveAction(TextInputAction.send);
      await tester.pumpAndSettle();
    }
    expect(find.text('second question'), findsOneWidget);

    await tester.longPress(find.text('first question'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit').last);
    await tester.pumpAndSettle();

    // Three messages would go, so it asks first.
    expect(find.textContaining('drops the 3 messages'), findsOneWidget);
    await tester.tap(find.text('Go back'));
    await tester.pumpAndSettle();

    expect(find.text('second question'), findsNothing);
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller?.text, 'first question');
  });
}
