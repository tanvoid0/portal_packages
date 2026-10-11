import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portal_platform/portal_platform.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

void main() {
  Future<void> pumpView(WidgetTester tester, {String? email}) =>
      tester.pumpWidget(MaterialApp(
        theme: buildPortalTheme(brightness: Brightness.light),
        home: PortalPasswordResetView(email: email),
      ));

  testWidgets('starts on the request step: email only, no code fields', (
    tester,
  ) async {
    await pumpView(tester, email: 'user@example.com');

    expect(find.widgetWithText(PortalTextField, 'Email'), findsOneWidget);
    expect(find.text('user@example.com'), findsOneWidget);
    expect(find.text('Verification code'), findsNothing);
    expect(find.text('New password'), findsNothing);
    expect(find.widgetWithText(PortalButton, 'Send code'), findsOneWidget);
  });

  testWidgets('a bad email blocks the request', (tester) async {
    await pumpView(tester, email: 'not-an-email');

    await tester.tap(find.widgetWithText(PortalButton, 'Send code'));
    await tester.pump();

    expect(find.text('Enter a valid email'), findsOneWidget);
    // Still on step 0 — no request was attempted.
    expect(find.text('Verification code'), findsNothing);
  });

  testWidgets('renders on the design-system components, not raw Material', (
    tester,
  ) async {
    await pumpView(tester, email: 'user@example.com');

    expect(find.byType(PortalAppBar), findsOneWidget);
    expect(find.byType(PortalTextField), findsOneWidget);
    expect(find.byType(PortalButton), findsOneWidget);
    expect(find.byType(FilledButton), findsNothing);
  });
}
