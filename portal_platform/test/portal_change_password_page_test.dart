import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portal_platform/portal_platform.dart';

void main() {
  Future<void> pumpPage(WidgetTester tester) =>
      tester.pumpWidget(const MaterialApp(home: PortalChangePasswordPage()));

  Future<void> submit(WidgetTester tester) async {
    await tester.tap(find.widgetWithText(FilledButton, 'Update password'));
    await tester.pump();
  }

  testWidgets('validation blocks the call before any field is filled', (
    tester,
  ) async {
    await pumpPage(tester);
    await submit(tester);

    // No ApiClient is registered, so reaching the call would throw.
    expect(find.text('Enter your current password'), findsOneWidget);
    expect(find.text('Use at least 8 characters'), findsOneWidget);
  });

  testWidgets('a mismatched confirmation is caught', (tester) async {
    await pumpPage(tester);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Current password'),
      'old-password',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'New password'),
      'new-password',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Confirm new password'),
      'new-passwrod',
    );
    await submit(tester);

    expect(find.text('Passwords do not match'), findsOneWidget);
  });

  testWidgets('the reveal toggle is per field', (tester) async {
    await pumpPage(tester);

    expect(find.byTooltip('Show password'), findsNWidgets(3));
    await tester.tap(find.byTooltip('Show password').first);
    await tester.pump();

    expect(find.byTooltip('Hide password'), findsOneWidget);
    expect(find.byTooltip('Show password'), findsNWidgets(2));
  });

  testWidgets('onSubmit replaces the write, and its failure stays in place', (
    tester,
  ) async {
    var calls = <List<String>>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PortalChangePasswordPage(
            onSubmit: (current, next) async {
              calls.add([current, next]);
              throw ApiException('Current password is incorrect', 400);
            },
          ),
        ),
      ),
    );

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Current password'),
      'wrong-password',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'New password'),
      'new-password',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Confirm new password'),
      'new-password',
    );
    await submit(tester);
    await tester.pumpAndSettle();

    expect(calls, [
      ['wrong-password', 'new-password'],
    ]);
    // The message is shown on the form, which is still up.
    expect(find.text('Current password is incorrect'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Update password'), findsOneWidget);
  });
}
