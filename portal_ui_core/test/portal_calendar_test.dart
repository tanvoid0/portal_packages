import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

void main() {
  Widget host(Widget child) => MaterialApp(
        theme: buildPortalTheme(brightness: Brightness.light),
        home: Scaffold(body: SingleChildScrollView(child: child)),
      );

  testWidgets('calendar: month grid, tap reports the day, arrows flip month',
      (t) async {
    DateTime? picked;
    DateTime? month;
    await t.pumpWidget(host(PortalCalendar(
      initialMonth: DateTime(2026, 2),
      selected: DateTime(2026, 2, 10),
      markedDays: {DateTime(2026, 2, 12)},
      onSelected: (d) => picked = d,
      onMonthChanged: (m) => month = m,
    )));

    expect(find.text('February 2026'), findsOneWidget);
    // Feb 2026 has 28 days.
    expect(find.text('28'), findsOneWidget);
    expect(find.text('29'), findsNothing);

    await t.tap(find.text('14'));
    expect(picked, DateTime(2026, 2, 14));

    final sem = t.getSemantics(find.text('10'));
    expect(sem.flagsCollection.isSelected.name, 'isTrue');
    expect(find.bySemanticsLabel(RegExp('has activity')), findsOneWidget);

    await t.tap(find.byTooltip('Next month'));
    await t.pump();
    expect(find.text('March 2026'), findsOneWidget);
    expect(month, DateTime(2026, 3));
  });

  testWidgets('calendar: day hit area is a tap target', (t) async {
    await t.pumpWidget(host(PortalCalendar(initialMonth: DateTime(2026, 2))));
    final tokens = PortalUiTheme.of(t.element(find.byType(PortalCalendar))).tokens;
    final cell = find.ancestor(of: find.text('14'), matching: find.byType(InkWell));
    expect(t.getSize(cell.first).height, tokens.minTapTarget);
  });

  testWidgets('a screen reader can select a day', (t) async {
    final h = t.ensureSemantics();
    DateTime? picked;
    await t.pumpWidget(host(PortalCalendar(
      initialMonth: DateTime(2026, 2),
      onSelected: (d) => picked = d,
    )));
    t.semantics.tap(find.semantics.byLabel(RegExp('February 14')));
    await t.pump();
    expect(picked, DateTime(2026, 2, 14));
    h.dispose();
  });
}
