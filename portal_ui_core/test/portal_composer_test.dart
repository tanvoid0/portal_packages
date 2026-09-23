import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

Widget _host(Widget child) {
  return MaterialApp(
    theme: buildPortalTheme(brightness: Brightness.light),
    home: Scaffold(body: child),
  );
}

void main() {
  testWidgets('does not fire onSubmit on empty text', (t) async {
    final controller = TextEditingController();
    var submits = 0;
    await t.pumpWidget(_host(PortalComposer(
      controller: controller,
      onSubmit: () => submits++,
    )));
    await t.tap(find.byIcon(Icons.arrow_upward_rounded));
    await t.pump();
    expect(submits, 0);
  });

  testWidgets('fires onSubmit from the send button once there is text',
      (t) async {
    final controller = TextEditingController(text: 'hello');
    var submits = 0;
    await t.pumpWidget(_host(PortalComposer(
      controller: controller,
      onSubmit: () => submits++,
    )));
    await t.tap(find.byIcon(Icons.arrow_upward_rounded));
    await t.pump();
    expect(submits, 1);
  });

  testWidgets('fires onSubmit from the keyboard send action too', (t) async {
    final controller = TextEditingController(text: 'hello');
    var submits = 0;
    await t.pumpWidget(_host(PortalComposer(
      controller: controller,
      onSubmit: () => submits++,
    )));
    await t.showKeyboard(find.byType(TextField));
    await t.testTextInput.receiveAction(TextInputAction.send);
    await t.pump();
    expect(submits, 1);
  });

  testWidgets('suppresses onSubmit while not enabled', (t) async {
    final controller = TextEditingController(text: 'hello');
    var submits = 0;
    await t.pumpWidget(_host(PortalComposer(
      controller: controller,
      onSubmit: () => submits++,
      enabled: false,
    )));
    // A disabled field wraps its own decoration -- suffix icon included --
    // in an IgnorePointer, so the tap does not land; that is the guard.
    await t.tap(find.byIcon(Icons.arrow_upward_rounded), warnIfMissed: false);
    await t.pump();
    expect(submits, 0);
  });

  testWidgets('shows a stop control instead of send while busy', (t) async {
    final controller = TextEditingController(text: 'hello');
    await t.pumpWidget(_host(PortalComposer(
      controller: controller,
      onSubmit: () {},
      busy: true,
    )));
    expect(find.byIcon(Icons.stop_rounded), findsOneWidget);
    expect(find.byIcon(Icons.arrow_upward_rounded), findsNothing);
  });

  testWidgets('stop tap calls onStop, never onSubmit', (t) async {
    final controller = TextEditingController(text: 'hello');
    var submits = 0;
    var stops = 0;
    await t.pumpWidget(_host(PortalComposer(
      controller: controller,
      onSubmit: () => submits++,
      busy: true,
      onStop: () => stops++,
    )));
    await t.tap(find.byIcon(Icons.stop_rounded));
    await t.pump();
    expect(stops, 1);
    expect(submits, 0);
  });

  testWidgets('lays out the leading and trailing slots', (t) async {
    final controller = TextEditingController();
    await t.pumpWidget(_host(PortalComposer(
      controller: controller,
      onSubmit: () {},
      leading: const [Icon(Icons.attach_file)],
      trailing: const [Icon(Icons.mic)],
    )));
    expect(find.byIcon(Icons.attach_file), findsOneWidget);
    expect(find.byIcon(Icons.mic), findsOneWidget);
  });

  testWidgets('minChars holds the send button until the text is long enough',
      (t) async {
    final controller = TextEditingController(text: 'hi');
    var submits = 0;
    await t.pumpWidget(_host(PortalComposer(
      controller: controller,
      minChars: 4,
      onSubmit: () => submits++,
    )));
    await t.tap(find.byIcon(Icons.arrow_upward_rounded));
    await t.pump();
    expect(submits, 0);

    controller.text = 'hello';
    await t.pump();
    await t.tap(find.byIcon(Icons.arrow_upward_rounded));
    await t.pump();
    expect(submits, 1);
  });

  testWidgets('maxLength truncates typed text and draws no counter of its own',
      (t) async {
    final controller = TextEditingController();
    await t.pumpWidget(_host(PortalComposer(
      controller: controller,
      maxLength: 5,
      onSubmit: () {},
    )));
    await t.enterText(find.byType(TextField), 'far too long');
    await t.pump();
    expect(controller.text, 'far t');
    // The caller renders its own count into `trailing`; Flutter's would sit
    // under the pill where the dock has no room for it.
    expect(find.text('5/5'), findsNothing);
  });
}
