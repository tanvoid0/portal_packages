import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

void main() {
  Widget host(Widget child) => MaterialApp(
        theme: buildPortalTheme(brightness: Brightness.light),
        home: Scaffold(body: SingleChildScrollView(child: child)),
      );

  testWidgets('a dimmed row fades but still reads and taps the same',
      (t) async {
    final h = t.ensureSemantics();
    var taps = 0;
    await t.pumpWidget(host(PortalListItem(
      title: 'Old',
      subtitle: 'archived',
      dimmed: true,
      onTap: () => taps++,
    )));
    final fade = t.widget<Opacity>(find
        .ancestor(of: find.text('Old'), matching: find.byType(Opacity))
        .first);
    expect(fade.opacity, .5);
    expect(t.getSemantics(find.text('Old')).label, 'Old, archived');
    await t.tap(find.text('Old'));
    expect(taps, 1);
    h.dispose();
  });

  testWidgets('a prompt takes a second action; one action stays the default',
      (t) async {
    var a = 0, b = 0;
    await t.pumpWidget(host(PortalPrompt(
      message: 'Sync failed',
      sentiment: PortalSentiment.negative,
      action: (label: 'Retry', onPressed: () => a++),
      secondaryAction: (label: 'Not now', onPressed: () => b++),
    )));
    await t.pumpAndSettle();
    await t.tap(find.text('Retry'));
    await t.tap(find.text('Not now'));
    expect([a, b], [1, 1]);

    await t.pumpWidget(host(PortalPrompt(
      message: 'Sync failed',
      action: (label: 'Retry', onPressed: () {}),
    )));
    expect(find.text('Not now'), findsNothing);
    expect(find.text('Retry'), findsOneWidget);
  });
}
