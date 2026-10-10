import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

void main() {
  // 2026-10-05 .. 2026-10-11 (Mon..Sun); day 3 is the 8th.
  final days = [for (var i = 5; i <= 11; i++) DateTime(2026, 10, i)];
  const dot = Key('dot-9');

  setUp(() => PortalHaptics.enabled = false);
  tearDown(() => PortalHaptics.enabled = true);

  Widget host(Widget child) => MaterialApp(
        theme: buildPortalTheme(brightness: Brightness.light),
        home: Scaffold(body: child),
      );

  Widget strip({
    ValueChanged<DateTime>? onSelected,
    Widget Function(DateTime)? mark,
  }) =>
      host(PortalDayStrip(
        days: days,
        selected: days[3],
        today: days[1],
        onSelected: onSelected,
        mark: mark ??
            (d) => d.day == 9
                ? const PortalDayDot(key: dot)
                : const SizedBox.shrink(),
        markLabel: (d) => d.day == 9 ? 'workout logged' : null,
      ));

  testWidgets('strip: selected day is announced, a tap reports the day, mark renders',
      (t) async {
    final h = t.ensureSemantics();
    DateTime? picked;
    await t.pumpWidget(strip(onSelected: (d) => picked = d));

    expect(t.getSemantics(find.text('8')).flagsCollection.isSelected.name,
        'isTrue');
    expect(t.getSemantics(find.text('6')).flagsCollection.isSelected.name,
        'isFalse');
    expect(find.byKey(dot), findsOneWidget);

    await t.tap(find.text('6'));
    expect(picked, DateTime(2026, 10, 6));

    final tokens = PortalUiTheme.of(t.element(find.byType(PortalDayStrip))).tokens;
    final cell = find.ancestor(of: find.text('6'), matching: find.byType(InkWell));
    expect(t.getSize(cell.first).height, greaterThanOrEqualTo(tokens.minTapTarget));
    expect(t.getSize(cell.first).width, greaterThanOrEqualTo(tokens.minTapTarget));
    h.dispose();
  });

  testWidgets('strip: the mark is its own semantics node, today is spoken',
      (t) async {
    final h = t.ensureSemantics();
    await t.pumpWidget(strip(onSelected: (_) {}));

    final markNode = t.getSemantics(find.byKey(dot));
    expect(markNode.label, 'workout logged');
    // The day's label is the date alone: the mark is not folded into it.
    expect(t.getSemantics(find.text('9')).label, isNot(contains('logged')));
    expect(find.bySemanticsLabel(RegExp('Today')), findsOneWidget);
    h.dispose();
  });

  testWidgets('strip: a mark with its own tap does not select the day', (t) async {
    DateTime? picked;
    var meter = 0;
    await t.pumpWidget(strip(
      onSelected: (d) => picked = d,
      mark: (d) => d.day == 9
          ? GestureDetector(
              key: dot,
              behavior: HitTestBehavior.opaque,
              onTap: () => meter++,
              child: const SizedBox.square(dimension: 8),
            )
          : const SizedBox.shrink(),
    ));

    await t.tap(find.byKey(dot));
    expect(meter, 1);
    expect(picked, isNull);
  });
}
