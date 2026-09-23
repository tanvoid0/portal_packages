import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

Widget _host(Widget child, {bool disableAnimations = false}) {
  return MediaQuery(
    data: MediaQueryData(disableAnimations: disableAnimations),
    child: MaterialApp(
      theme: buildPortalTheme(brightness: Brightness.light),
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  testWidgets('announces itself for a screen reader', (t) async {
    await t.pumpWidget(_host(const PortalTypingDots()));
    expect(find.bySemanticsLabel('Typing'), findsOneWidget);
  });

  testWidgets('accepts a custom label', (t) async {
    await t.pumpWidget(
      _host(const PortalTypingDots(semanticsLabel: 'Assistant is typing')),
    );
    expect(find.bySemanticsLabel('Assistant is typing'), findsOneWidget);
  });

  Finder dotBuilders() => find.descendant(
        of: find.byType(PortalTypingDots),
        matching: find.byType(AnimatedBuilder),
      );

  testWidgets('drives its three dots off a ticker when motion is allowed',
      (t) async {
    await t.pumpWidget(_host(const PortalTypingDots()));
    expect(dotBuilders(), findsNWidgets(3));
    await t.pump(const Duration(milliseconds: 200));
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('holds still with no ticker under disableAnimations', (t) async {
    await t.pumpWidget(
      _host(const PortalTypingDots(), disableAnimations: true),
    );
    expect(dotBuilders(), findsNothing);
    // Pumping time forward changes nothing -- there is no controller to
    // drive a frame with.
    await t.pump(const Duration(seconds: 1));
    expect(dotBuilders(), findsNothing);
    expect(find.bySemanticsLabel('Typing'), findsOneWidget);
  });
}
