import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portal_ai/portal_ai.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

void main() {
  Future<void> openSearch(WidgetTester tester) async {
    final now = DateTime.now();
    await tester.pumpWidget(
      MaterialApp(
        theme: buildPortalTheme(brightness: Brightness.light),
        home: Scaffold(
          body: AiAssistantPage(
            turns: [
              AiChatTurn(role: 'user', content: 'milk please', at: now),
              AiChatTurn(role: 'assistant', content: 'added milk', at: now),
              AiChatTurn(role: 'user', content: 'and bread', at: now),
            ],
            onSend: (_) async {},
          ),
        ),
      ),
    );
    await tester.tap(find.byIcon(Icons.more_vert_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Find in conversation'));
    await tester.pumpAndSettle();
  }

  testWidgets('search counts matches and steps through them', (tester) async {
    await openSearch(tester);
    await tester.enterText(find.byType(PortalSearchField), 'milk');
    await tester.pumpAndSettle();

    expect(find.text('1 of 2'), findsOneWidget);
    expect(find.textContaining('bread'), findsNothing);

    await tester.tap(find.byTooltip('Next match'));
    await tester.pumpAndSettle();
    expect(find.text('2 of 2'), findsOneWidget);

    // Wraps past the last match, and back before the first.
    await tester.tap(find.byTooltip('Next match'));
    await tester.pumpAndSettle();
    expect(find.text('1 of 2'), findsOneWidget);
    await tester.tap(find.byTooltip('Previous match'));
    await tester.pumpAndSettle();
    expect(find.text('2 of 2'), findsOneWidget);
  });

  testWidgets('a query with no hits says so and disables stepping', (
    tester,
  ) async {
    await openSearch(tester);
    await tester.enterText(find.byType(PortalSearchField), 'zebra');
    await tester.pumpAndSettle();

    expect(find.text('No matches'), findsOneWidget);
  });
}
