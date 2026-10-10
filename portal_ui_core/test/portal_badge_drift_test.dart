import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

void main() {
  Widget host(Widget child) => MaterialApp(
        theme: buildPortalTheme(brightness: Brightness.light),
        home: Scaffold(body: Center(child: child)),
      );

  Size badgeSize(WidgetTester t) => t.getSize(find.byType(PortalBadge));

  testWidgets('compact renders its label, smaller than the regular pill',
      (t) async {
    await t.pumpWidget(host(const PortalBadge(label: 'Due', icon: Icons.add)));
    final regular = badgeSize(t);
    await t.pumpWidget(
        host(const PortalBadge(label: 'Due', icon: Icons.add, compact: true)));
    expect(find.text('Due'), findsOneWidget);
    expect(badgeSize(t).height, lessThan(regular.height));
    expect(badgeSize(t).width, lessThan(regular.width));
  });

  test('ofLevel: top third shouts, middle warns, the rest stays neutral', () {
    expect(PortalBadgeTone.ofLevel(3), PortalBadgeTone.danger);
    expect(PortalBadgeTone.ofLevel(2), PortalBadgeTone.warning);
    expect(PortalBadgeTone.ofLevel(1), PortalBadgeTone.neutral);
    expect(PortalBadgeTone.ofLevel(5, max: 5), PortalBadgeTone.danger);
  });

  testWidgets('ofLevel + containerTone build, on the container not the tint',
      (t) async {
    await t.pumpWidget(host(PortalBadge.ofLevel(3,
        label: 'High', compact: true, containerTone: true)));
    expect(find.text('High'), findsOneWidget);
    final deco = t
        .widget<DecoratedBox>(find
            .descendant(
                of: find.byType(PortalBadge),
                matching: find.byType(DecoratedBox))
            .first)
        .decoration as BoxDecoration;
    expect(deco.color,
        PortalSemanticColors.of(t.element(find.text('High'))).dangerContainer);
  });
}
