import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portal_ai/portal_ai.dart';

void main() {
  Future<void> pump(
    WidgetTester tester,
    Widget composer,
  ) =>
      tester.pumpWidget(MaterialApp(home: Scaffold(body: composer)));

  testWidgets('the keyboard send action submits', (tester) async {
    // Regression: rebuilding the field on every keystroke to keep the counter
    // live dropped the text-input connection, and send silently did nothing.
    var sent = 0;
    await pump(
      tester,
      AiPromptComposer(
        controller: TextEditingController(),
        maxLength: 100,
        onSubmit: () => sent++,
      ),
    );

    await tester.enterText(find.byType(TextField), 'hello');
    await tester.testTextInput.receiveAction(TextInputAction.send);
    await tester.pumpAndSettle();

    expect(sent, 1);
  });

  testWidgets('the counter tracks what is typed', (tester) async {
    await pump(
      tester,
      AiPromptComposer(
        controller: TextEditingController(),
        maxLength: 100,
        onSubmit: () {},
      ),
    );

    expect(find.text('0/100'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'hello');
    await tester.pump();
    expect(find.text('5/100'), findsOneWidget);
  });

  testWidgets('submit stays dark until minChars is typed', (tester) async {
    var sent = 0;
    await pump(
      tester,
      AiPromptComposer(
        controller: TextEditingController(),
        minChars: 3,
        submitLabel: 'Generate',
        onSubmit: () => sent++,
      ),
    );

    Future<bool> enabled() async =>
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed !=
            null;

    expect(await enabled(), isFalse);
    await tester.enterText(find.byType(TextField), 'ab');
    await tester.pump();
    expect(await enabled(), isFalse);

    await tester.enterText(find.byType(TextField), 'abc');
    await tester.pump();
    expect(await enabled(), isTrue);

    await tester.tap(find.text('Generate'));
    expect(sent, 1);
  });

  testWidgets('disabled locks the field, busy offers stop instead',
      (tester) async {
    var stopped = 0;
    await pump(
      tester,
      AiPromptComposer(
        controller: TextEditingController(text: 'hi'),
        enabled: false,
        onSubmit: () {},
      ),
    );
    expect(tester.widget<TextField>(find.byType(TextField)).enabled, isFalse);


    await pump(
      tester,
      AiPromptComposer(
        controller: TextEditingController(text: 'hi'),
        busy: true,
        onStop: () => stopped++,
        onSubmit: () {},
      ),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(tester.widget<TextField>(find.byType(TextField)).readOnly, isTrue);
    // The stop glyph sits inside the spinner; the button is what takes taps.
    // It has to stay live while busy -- it is the only way to cancel a run.
    await tester.tap(find.byType(IconButton));
    expect(stopped, 1);
  });
}
