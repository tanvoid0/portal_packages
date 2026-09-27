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
        enabled: true,
        child: PortalReviewTag(id: 'a.b', child: Text('Hello')),
      ),
    ));
    expect(find.text('Hello'), findsOneWidget);
    expect(find.text('a.b'), findsOneWidget);
  });

  testWidgets('scope disabled: no badge, and the scope draws nothing', (t) async {
    await t.pumpWidget(_host(
      const PortalReviewScope(
        enabled: false,
        child: PortalReviewTag(id: 'a.b', child: Text('Hello')),
      ),
    ));
    expect(find.text('Hello'), findsOneWidget);
    expect(find.text('a.b'), findsNothing);
    // No on-canvas toggle: the demo's side panel owns the switch.
    expect(find.byType(Tooltip), findsNothing);
  });

  testWidgets('flipping enabled hides the badge', (t) async {
    Widget scope(bool enabled) => _host(
          PortalReviewScope(
            enabled: enabled,
            child: const PortalReviewTag(id: 'a.b', child: Text('Hello')),
          ),
        );
    await t.pumpWidget(scope(true));
    expect(find.text('a.b'), findsOneWidget);

    await t.pumpWidget(scope(false));
    expect(find.text('a.b'), findsNothing);
  });
}
