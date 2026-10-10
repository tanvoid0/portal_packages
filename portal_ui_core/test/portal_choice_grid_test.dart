import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

void main() {
  Widget host(Widget child) => MaterialApp(
        theme: buildPortalTheme(brightness: Brightness.light),
        home: Scaffold(body: SingleChildScrollView(child: child)),
      );

  const choices = [
    PortalChoiceOption.color('Red', Color(0xFFE53935)),
    PortalChoiceOption.color('Green', Color(0xFF43A047)),
    PortalChoiceOption.color('Blue', Color(0xFF1E88E5)),
  ];
  final cells = find.byType(PortalPressable);

  testWidgets('selected cell is announced, outlined and carries a check',
      (t) async {
    final handle = t.ensureSemantics();
    await t.pumpWidget(host(PortalChoiceGrid(
      choices: choices,
      selected: 1,
      onSelected: (_) {},
    )));

    expect(t.getSemantics(cells.at(1)).label, 'Green');
    expect(t.getSemantics(cells.at(1)).flagsCollection.isSelected.name,
        'isTrue');
    expect(t.getSemantics(cells.at(0)).flagsCollection.isSelected.name,
        'isFalse');

    // Selection is not fill alone: one check, on the selected cell only, and
    // an outline on it.
    final check = find.byIcon(PortalIcons.check_rounded);
    expect(check, findsOneWidget);
    expect(find.descendant(of: cells.at(1), matching: check), findsOneWidget);
    expect(
      find.descendant(
        of: cells.at(1),
        matching: find.byWidgetPredicate((w) =>
            w is DecoratedBox &&
            w.decoration is BoxDecoration &&
            (w.decoration as BoxDecoration).border != null &&
            (w.decoration as BoxDecoration).shape == BoxShape.rectangle),
      ),
      findsOneWidget,
    );

    await t.pumpWidget(host(PortalChoiceGrid(
      choices: choices,
      selected: null,
      onSelected: (_) {},
    )));
    expect(find.byIcon(PortalIcons.check_rounded), findsNothing);
    handle.dispose();
  });

  testWidgets('tapping a cell reports its index; 48 dp targets', (t) async {
    int? got;
    await t.pumpWidget(host(PortalChoiceGrid(
      choices: choices,
      selected: 1,
      onSelected: (i) => got = i,
    )));
    expect(t.getSize(cells.at(0)).width, greaterThanOrEqualTo(48));
    expect(t.getSize(cells.at(0)).height, greaterThanOrEqualTo(48));

    await t.tap(cells.at(2));
    await t.pumpAndSettle();
    expect(got, 2);
  });

  testWidgets('enabled: false ignores taps', (t) async {
    int? got;
    await t.pumpWidget(host(PortalChoiceGrid(
      choices: choices,
      selected: 1,
      enabled: false,
      onSelected: (i) => got = i,
    )));
    await t.tap(cells.at(2));
    await t.pumpAndSettle();
    expect(got, isNull);
  });
}
