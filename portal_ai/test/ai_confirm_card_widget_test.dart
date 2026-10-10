import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portal_ai/src/widgets/ai_confirm_card.dart';
import 'package:portal_ai/src/widgets/ai_step_tile.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

Future<void> _pump(WidgetTester tester, Widget child) => tester.pumpWidget(
  MaterialApp(
    theme: buildPortalTheme(brightness: Brightness.light),
    home: Scaffold(body: SingleChildScrollView(child: child)),
  ),
);

void main() {
  testWidgets('shows the three answers and fires them', (tester) async {
    final fired = <String>[];
    await _pump(
      tester,
      AiConfirmCard(
        toolName: 'recipe.create_recipe',
        args: const {'title': 'Ratatouille', 'servings': 4},
        onAccept: () => fired.add('accept'),
        onEdit: () => fired.add('edit'),
        onDecline: () => fired.add('decline'),
      ),
    );

    expect(find.text('Create recipe'), findsOneWidget);
    expect(find.text('Decline'), findsOneWidget);
    expect(find.text('Edit'), findsOneWidget);
    expect(find.text('Accept'), findsOneWidget);
    expect(find.text('Ratatouille'), findsOneWidget);
    expect(
      tester
          .widget<PortalButton>(find.widgetWithText(PortalButton, 'Accept'))
          .variant,
      PortalButtonVariant.primary,
    );

    for (final label in ['Decline', 'Edit', 'Accept']) {
      await tester.tap(find.text(label));
    }
    expect(fired, ['decline', 'edit', 'accept']);
  });

  testWidgets('a delete tool gets the destructive primary, still tappable', (
    tester,
  ) async {
    var accepted = 0;
    await _pump(
      tester,
      AiConfirmCard(
        toolName: 'meal_plan.delete_entry',
        args: const {},
        onAccept: () => accepted++,
        onDecline: () {},
      ),
    );

    expect(
      tester
          .widget<PortalButton>(find.widgetWithText(PortalButton, 'Accept'))
          .variant,
      PortalButtonVariant.destructive,
    );
    expect(find.text('Edit'), findsNothing);
    await tester.tap(find.text('Accept'));
    expect(accepted, 1);
  });

  testWidgets('an id inside a row is not shown to the user', (tester) async {
    await _pump(
      tester,
      AiConfirmCard(
        toolName: 'meal_plan.add_entries',
        args: const {
          'entries': [
            {
              'recipe_id': '868faf5c-bdc9-4f55-8a2e-1c3d5e7f9a0b',
              'date': '2026-09-08',
            },
          ],
        },
        onAccept: () {},
        onDecline: () {},
      ),
    );

    expect(find.text('2026-09-08'), findsOneWidget);
    expect(find.textContaining('868faf5c'), findsNothing);
  });

  testWidgets('step line and receipt show their text', (tester) async {
    await _pump(
      tester,
      const Column(
        children: [
          AiStepLine(icon: Icons.search, text: 'Looked up recipes'),
          AiReceipt(label: 'Saved to your recipes'),
          AiReceipt(label: 'Could not save', failed: true),
        ],
      ),
    );

    expect(find.text('Looked up recipes'), findsOneWidget);
    expect(find.text('Saved to your recipes'), findsOneWidget);
    expect(find.text('Could not save'), findsOneWidget);
  });
}
