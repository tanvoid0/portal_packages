import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

void main() {
  Widget host(Widget child) => MaterialApp(
        theme: buildPortalTheme(brightness: Brightness.light),
        home: Scaffold(body: Center(child: child)),
      );

  testWidgets('busyLabel is what a screen reader hears while loading',
      (t) async {
    final handle = t.ensureSemantics();
    await t.pumpWidget(host(PortalButton(
      label: 'Save',
      busyLabel: 'Saving',
      isLoading: true,
      onPressed: () {},
    )));
    expect(find.bySemanticsLabel(RegExp('Saving')), findsWidgets);
    expect(find.bySemanticsLabel('Save'), findsNothing);

    // No busyLabel: the label stays, as before.
    await t.pumpWidget(host(PortalButton(
      label: 'Save',
      isLoading: true,
      onPressed: () {},
    )));
    expect(find.bySemanticsLabel('Save'), findsWidgets);
    handle.dispose();
  });

  testWidgets('a failed save shows Retry, and Retry saves again', (t) async {
    var saves = 0;
    await t.pumpWidget(host(PortalButtonDock.save(
      label: 'Save',
      failed: 'Could not save.',
      onSave: () => saves++,
    )));
    // Inline PortalPrompt renders message + action in one Text.rich with a
    // trailing spacer, so match the substring, not the exact run.
    expect(find.textContaining('Could not save.'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);

    await t.tap(find.text('Retry'));
    expect(saves, 1);

    // Saving hides the stale failure.
    await t.pumpWidget(host(PortalButtonDock.save(
      label: 'Save',
      busyLabel: 'Saving',
      saving: true,
      failed: 'Could not save.',
      onSave: () => saves++,
    )));
    expect(find.text('Retry'), findsNothing);
    expect(find.text('Saving'), findsOneWidget);
  });
}
