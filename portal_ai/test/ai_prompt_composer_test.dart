import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portal_ai/portal_ai.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

void main() {
  Future<void> pump(WidgetTester tester, Widget composer) => tester.pumpWidget(
    MaterialApp(
      theme: buildPortalTheme(brightness: Brightness.light),
      home: Scaffold(body: composer),
    ),
  );

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

  testWidgets('a labelled composer submits through its tooltip button', (
    tester,
  ) async {
    // Regression: PortalComposer has no labelled-button slot, so submitLabel
    // now only renames the button's tooltip -- the widget tree it renders is
    // the same docked shape as any other bordered composer.
    var sent = 0;
    await pump(
      tester,
      AiPromptComposer(
        controller: TextEditingController(text: 'abc'),
        bordered: true,
        minChars: 3,
        submitLabel: 'Generate',
        onSubmit: () => sent++,
      ),
    );

    await tester.tap(find.byTooltip('Generate'));
    expect(sent, 1);
  });

  testWidgets('disabled locks the field, busy offers stop instead', (
    tester,
  ) async {
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
    // Found by tooltip rather than by widget type: the control is a circular
    // InkWell now, and the tooltip is the part that must never go missing.
    await tester.tap(find.byTooltip('Stop'));
    expect(stopped, 1);
  });
}
