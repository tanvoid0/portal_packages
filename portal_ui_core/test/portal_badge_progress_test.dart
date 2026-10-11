import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

void main() {
  Widget host(Widget child, {List<ThemeExtension<dynamic>> skin = const []}) =>
      MaterialApp(
        theme: PortalThemeConfig(extensionsBuilder: (_) => skin).light(),
        home: Scaffold(body: Center(child: SizedBox(width: 200, child: child))),
      );

  BoxDecoration badgeDeco(WidgetTester t) => t
      .widget<DecoratedBox>(find
          .descendant(
              of: find.byType(PortalBadge), matching: find.byType(DecoratedBox))
          .first)
      .decoration as BoxDecoration;

  testWidgets('badge: tone tints, outlined adds a border, theme alpha wins',
      (t) async {
    await t.pumpWidget(host(const PortalBadge(
        label: 'Paid', tone: PortalBadgeTone.success, icon: Icons.check)));
    expect(find.text('Paid'), findsOneWidget);
    expect(badgeDeco(t).border, isNull);

    await t.pumpWidget(host(
      const PortalBadge(
          label: 'Paid', foregroundColor: Colors.teal, outlined: true),
      skin: const [PortalBadgeTheme(tintAlpha: 0.5)],
    ));
    await t.pumpAndSettle();
    expect(badgeDeco(t).border, isNotNull);
    expect(badgeDeco(t).color!.a, closeTo(0.5, 0.01));
  });

  testWidgets('progress: fills to value, overflow recolours, NaN reads 0',
      (t) async {
    FractionallySizedBox bar() =>
        t.widget<FractionallySizedBox>(find.byType(FractionallySizedBox));
    Color fill() =>
        ((bar().child! as DecoratedBox).decoration as BoxDecoration).color!;

    await t.pumpWidget(host(const PortalProgress(value: 0.4)));
    await t.pumpAndSettle();
    expect(bar().widthFactor, closeTo(0.4, 0.001));
    final normal = fill();

    await t.pumpWidget(host(const PortalProgress(value: 1.5)));
    await t.pumpAndSettle();
    expect(bar().widthFactor, 1);
    expect(fill(), isNot(normal));

    await t.pumpWidget(host(const PortalProgress(value: double.nan)));
    await t.pumpAndSettle();
    expect(bar().widthFactor, 0);
  });

  testWidgets('progress: null is indeterminate', (t) async {
    await t.pumpWidget(host(const PortalProgress()));
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
  });

  testWidgets('segmented: drops empty segments, legend shows shares',
      (t) async {
    await t.pumpWidget(host(const PortalSegmentedProgress(segments: [
      PortalProgressSegment(label: 'Tax', value: 1, segmentColor: Colors.red),
      PortalProgressSegment(label: 'Net', value: 3, segmentColor: Colors.green),
      PortalProgressSegment(label: 'Zero', value: 0, segmentColor: Colors.blue),
    ])));
    expect(find.text('25%'), findsOneWidget);
    expect(find.text('75%'), findsOneWidget);
    expect(find.text('Zero'), findsNothing);
  });

  testWidgets('steps: tap reports the index, hit area is a tap target',
      (t) async {
    int? tapped;
    await t.pumpWidget(host(PortalStepProgress(
      count: 4,
      current: 1,
      onStepTap: (i) => tapped = i,
    )));
    expect(t.getSize(find.byType(GestureDetector).first).height,
        DesignTokens.defaults.minTapTarget);
    await t.tap(find.byType(GestureDetector).at(2));
    expect(tapped, 2);
  });

  testWidgets('steps: done is announced and drawn apart from upcoming',
      (t) async {
    final h = t.ensureSemantics();
    await t.pumpWidget(host(const PortalStepProgress(count: 3, current: 1)));
    final bars = find.byType(AnimatedContainer);
    expect(t.getSemantics(bars.at(0)).value, 'done');
    expect(t.getSemantics(bars.at(2)).value, isEmpty);
    expect(t.getSize(bars.at(0)).height,
        greaterThan(t.getSize(bars.at(2)).height));
    h.dispose();
  });
}
