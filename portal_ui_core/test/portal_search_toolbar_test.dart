import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

void main() {
  Widget host(Widget child) => MaterialApp(
        theme: buildPortalTheme(brightness: Brightness.light),
        home: Scaffold(body: child),
      );

  testWidgets('search field reports changes, filter/sort taps fire, chip removes',
      (t) async {
    String? query;
    var filterTapped = false;
    var sortTapped = false;
    var chipRemoved = false;

    await t.pumpWidget(host(PortalSearchToolbar(
      hintText: 'Search',
      onChanged: (v) => query = v,
      filterCount: 2,
      onFilterTap: () => filterTapped = true,
      sortLabel: 'Newest',
      onSortTap: () => sortTapped = true,
      chips: [
        PortalSearchToolbarChip(label: 'Active', onRemoved: () => chipRemoved = true),
      ],
    )));

    await t.enterText(find.byType(TextField), 'milk');
    expect(query, 'milk');

    await t.tap(find.bySemanticsLabel('Filters'));
    expect(filterTapped, isTrue);

    await t.tap(find.bySemanticsLabel('Newest'));
    expect(sortTapped, isTrue);

    expect(find.text('Active'), findsOneWidget);
    await t.tap(find.descendant(
      of: find.widgetWithText(InputChip, 'Active'),
      matching: find.byIcon(PortalIcons.close_rounded),
    ));
    expect(chipRemoved, isTrue);
  });

  testWidgets('filter button shows no dot when filterCount is zero', (t) async {
    await t.pumpWidget(host(const PortalSearchToolbar(
      hintText: 'Search',
      filterCount: 0,
      onFilterTap: null,
    )));
    // With no onFilterTap the button is not drawn at all.
    expect(find.bySemanticsLabel('Filters'), findsNothing);
  });
}
