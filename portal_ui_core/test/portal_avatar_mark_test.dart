import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

void main() {
  Widget host(Widget child) => MaterialApp(
        theme: buildPortalTheme(brightness: Brightness.light),
        home: Scaffold(body: Center(child: child)),
      );

  testWidgets('avatar: two upper-cased initials, token size, status ring',
      (t) async {
    await t.pumpWidget(host(const PortalAvatarMark(
      initials: 'tanveer',
      size: PortalAvatarMarkSize.lg,
      statusColor: Colors.green,
    )));

    expect(find.text('TA'), findsOneWidget);
    expect(
      t.getSize(find.byType(PortalAvatarMark)),
      Size.square(DesignTokens.defaults.avatarSizes.lg),
    );
    final ring = t.widget<DecoratedBox>(find.ancestor(
      of: find.byType(CircleAvatar),
      matching: find.byType(DecoratedBox),
    ).first);
    final border = (ring.decoration as BoxDecoration).border as Border;
    expect(border.top.color, Colors.green);
  });

  testWidgets('badge: zero hides, a count shows, null is a dot', (t) async {
    await t.pumpWidget(host(const Row(children: [
      PortalCountBadge(count: 0, child: Icon(Icons.inbox)),
      PortalCountBadge(count: 5, child: Icon(Icons.mail)),
      PortalCountBadge(child: Icon(Icons.circle)),
    ])));

    final badges = t.widgetList<Badge>(find.byType(Badge)).toList();
    expect(badges[0].isLabelVisible, isFalse);
    expect(badges[1].isLabelVisible, isTrue);
    expect(find.text('5'), findsOneWidget);
    expect(badges[2].isLabelVisible, isTrue);
    expect(badges[2].label, isNull);
  });

  testWidgets('ring: springs from empty to the value, labels the percent',
      (t) async {
    await t.pumpWidget(host(const PortalProgressRing(value: 0.5)));

    CircularProgressIndicator arc() => t.widget<CircularProgressIndicator>(
          find.byType(CircularProgressIndicator),
        );
    expect(arc().value, 0);
    await t.pump(const Duration(milliseconds: 100));
    expect(arc().value, allOf(greaterThan(0), lessThan(0.5)));
    await t.pumpAndSettle();
    expect(arc().value, 0.5);
    expect(find.text('50%'), findsOneWidget);

    // Over 1 clamps rather than wrapping the arc.
    await t.pumpWidget(host(const PortalProgressRing(value: 1.4)));
    await t.pumpAndSettle();
    expect(arc().value, 1);
    expect(find.text('100%'), findsOneWidget);
  });
}
