import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

void main() {
  Widget host(Widget child) => MaterialApp(
        theme: const PortalThemeConfig().light(),
        home: Scaffold(body: Center(child: SizedBox(width: 320, child: child))),
      );

  testWidgets('day ring: target shows ring + "x / y kcal"; none shows number',
      (t) async {
    await t.pumpWidget(host(const PortalNutritionDayRing(
      consumedCalories: 1234,
      targetCalories: 2000,
      consumedProtein: 42,
      consumedCarbs: 180,
      consumedFat: 55,
    )));
    expect(find.byType(PortalProgressRing), findsOneWidget);
    expect(find.text('1,234 / 2,000 kcal'), findsOneWidget);
    expect(find.text('P 42g · C 180g · F 55g'), findsOneWidget);

    await t.pumpWidget(host(const PortalNutritionDayRing(
      consumedCalories: 1234,
      consumedProtein: 42,
      consumedCarbs: 180,
      consumedFat: 55,
    )));
    expect(find.byType(PortalProgressRing), findsNothing);
    expect(find.text('1,234'), findsOneWidget);
  });

  testWidgets('food tile: servings only when != 1, delete is named',
      (t) async {
    var deleted = false;
    await t.pumpWidget(host(PortalFoodLogTile(
      name: 'Oats',
      calories: 300,
      servings: 2,
      mealType: 'Breakfast',
      onDelete: () => deleted = true,
    )));
    expect(find.text('x2'), findsOneWidget);
    expect(find.text('300 kcal'), findsOneWidget);
    await t.tap(find.byTooltip('Delete entry'));
    expect(deleted, isTrue);

    await t.pumpWidget(host(const PortalFoodLogTile(name: 'Egg', calories: 70)));
    expect(find.text('x1'), findsNothing);
    expect(find.byTooltip('Delete entry'), findsNothing);
  });

  testWidgets('goals sheet: whole kcal, decimal macros, empty clears',
      (t) async {
    final saved = <List<num>>[];
    await t.pumpWidget(host(PortalNutritionGoalsSheet(
      onSave: (c, p, cb, f) async => saved.add([c, p, cb, f]),
      onClose: () {},
    )));
    Finder field(int i) => find.byType(TextField).at(i);
    Future<void> save() async {
      await t.tap(find.text('Save goals'));
      // pump, not settle: the dock keeps spinning once the (inert) onClose returns.
      await t.pump(const Duration(milliseconds: 300));
    }

    await t.enterText(field(0), '2000.5');
    await save();
    expect(find.text('Enter whole calories, or leave it empty.'), findsOneWidget);
    expect(saved, isEmpty);

    await t.enterText(field(0), '2000');
    await t.enterText(field(1), '12.5');
    await save();
    expect(saved, [
      [2000, 12.5, 0, 0],
    ]);
  });
}
