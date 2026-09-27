import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

Widget _host(Widget child) {
  return MaterialApp(
    theme: buildPortalTheme(brightness: Brightness.light),
    home: Scaffold(body: child),
  );
}

void main() {
  testWidgets('no scope ancestor: renders child, no badge', (t) async {
    await t.pumpWidget(_host(
      const PortalReviewTag(id: 'a.b', child: Text('Hello')),
    ));
    expect(find.text('Hello'), findsOneWidget);
    expect(find.text('a.b'), findsNothing);
  });

  testWidgets('scope enabled: badge id is shown', (t) async {
    await t.pumpWidget(_host(
      const PortalReviewScope(
        initiallyEnabled: true,
        child: PortalReviewTag(id: 'a.b', child: Text('Hello')),
      ),
    ));
    expect(find.text('Hello'), findsOneWidget);
    expect(find.text('a.b'), findsOneWidget);
  });

  testWidgets('toggling the pill off hides the badge', (t) async {
    await t.pumpWidget(_host(
      const PortalReviewScope(
        initiallyEnabled: true,
        child: PortalReviewTag(id: 'a.b', child: Text('Hello')),
      ),
    ));
    expect(find.text('a.b'), findsOneWidget);

    await t.tap(find.byTooltip('Hide review badges'));
    await t.pump();

    expect(find.text('a.b'), findsNothing);
  });
}
