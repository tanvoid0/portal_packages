import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

void main() {
  const identity = PortalAppIdentity(
    icon: Icons.check,
    name: 'Test App',
    tagline: 'Does the thing',
  );

  Widget page({Widget? hero, bool offline = false}) => MaterialApp(
        theme: buildPortalTheme(brightness: Brightness.light),
        home: PortalOnboardingPage(
          identity: identity,
          greeting: 'Hello',
          question: 'Ready?',
          onSignIn: () {},
          hero: hero,
          offline: offline,
        ),
      );

  testWidgets('a given hero renders instead of the default identity mark', (
    tester,
  ) async {
    await tester.pumpWidget(page(hero: const Text('HERO')));

    expect(find.text('HERO'), findsOneWidget);
    expect(find.byIcon(Icons.check), findsNothing);
  });

  testWidgets('offline disables sign in and shows the offline hint', (
    tester,
  ) async {
    await tester.pumpWidget(page(offline: true));

    final button = tester.widget<PortalButton>(find.byType(PortalButton));
    expect(button.onPressed, isNull);
    expect(
      find.text('No connection. Signing in needs the internet.'),
      findsOneWidget,
    );
  });
}
