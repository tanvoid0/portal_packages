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
  testWidgets('onTap fires on a tap', (t) async {
    var taps = 0;
    await t.pumpWidget(_host(PortalPromptCard(
      icon: Icons.lightbulb_outline,
      title: 'Plan my week',
      onTap: () => taps++,
    )));
    await t.tap(find.byType(PortalPromptCard));
    await t.pump();
    expect(taps, 1);
  });

  testWidgets('subtitle only renders when given', (t) async {
    await t.pumpWidget(_host(const PortalPromptCard(
      icon: Icons.lightbulb_outline,
      title: 'Plan my week',
    )));
    expect(find.text('Plan my week'), findsOneWidget);
    expect(find.text('From your calendar'), findsNothing);

    await t.pumpWidget(_host(const PortalPromptCard(
      icon: Icons.lightbulb_outline,
      title: 'Plan my week',
      subtitle: 'From your calendar',
    )));
    expect(find.text('From your calendar'), findsOneWidget);
  });

  testWidgets('row lays cards out left to right in a horizontal scroller',
      (t) async {
    await t.pumpWidget(_host(SizedBox(
      width: 300,
      child: PortalPromptCardRow(
        children: [
          for (var i = 0; i < 3; i++)
            PortalPromptCard(icon: Icons.star, title: 'Card $i'),
        ],
      ),
    )));
    expect(find.byType(SingleChildScrollView), findsOneWidget);
    final xs = [
      for (var i = 0; i < 3; i++) t.getTopLeft(find.text('Card $i')).dx,
    ];
    expect(xs[0], lessThan(xs[1]));
    expect(xs[1], lessThan(xs[2]));
  });

  testWidgets('wrapped lays cards out two to a row', (t) async {
    await t.pumpWidget(_host(SizedBox(
      width: 300,
      child: PortalPromptCardRow(
        wrapped: true,
        children: [
          for (var i = 0; i < 4; i++)
            PortalPromptCard(icon: Icons.star, title: 'Card $i'),
        ],
      ),
    )));
    final row0 = t.getTopLeft(find.text('Card 0')).dy;
    final row1 = t.getTopLeft(find.text('Card 1')).dy;
    final row2 = t.getTopLeft(find.text('Card 2')).dy;
    // Card 0 and 1 share a row; card 2 starts the next one down.
    expect(row0, row1);
    expect(row2, greaterThan(row0));
  });
}
