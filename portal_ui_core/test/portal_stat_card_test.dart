import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

void main() {
  Widget host(Widget child, {List<ThemeExtension<dynamic>> skin = const []}) =>
      MaterialApp(
        theme: PortalThemeConfig(extensionsBuilder: (_) => skin).light(),
        home: Scaffold(body: Center(child: child)),
      );

  Color? fill(WidgetTester t) => t
      .widget<Material>(find
          .descendant(
              of: find.byType(PortalCard), matching: find.byType(Material))
          .first)
      .color;

  testWidgets('value colour and background: widget beats theme beats default',
      (t) async {
    await t.pumpWidget(host(const PortalStatCard(value: '9', label: 'A')));
    final plain = fill(t);
    final cs = Theme.of(t.element(find.byType(Scaffold))).colorScheme;
    expect(t.widget<Text>(find.text('9')).style!.color, cs.onSurface);

    await t.pumpWidget(host(
      const PortalStatCard(value: '9', label: 'A'),
      skin: const [
        PortalStatCardTheme(
            backgroundColor: Colors.teal, valueColor: Colors.red),
      ],
    ));
    await t.pumpAndSettle();
    expect(fill(t), Colors.teal);
    expect(t.widget<Text>(find.text('9')).style!.color, Colors.red);

    await t.pumpWidget(host(
      const PortalStatCard(
        value: '9',
        label: 'A',
        valueColor: Colors.green,
        backgroundColor: Colors.amber,
      ),
      skin: const [
        PortalStatCardTheme(
            backgroundColor: Colors.teal, valueColor: Colors.red),
      ],
    ));
    await t.pumpAndSettle();
    expect(fill(t), Colors.amber);
    expect(t.widget<Text>(find.text('9')).style!.color, Colors.green);
    expect(plain, isNot(Colors.amber));
  });

  // PortalStatRow measures its cells with IntrinsicHeight; a cell holding
  // PortalText (AutoSizeText -> LayoutBuilder) throws on the intrinsic query.
  testWidgets('a row of filled tiles lays out under IntrinsicHeight',
      (t) async {
    await t.pumpWidget(host(const PortalStatRow(stats: [
      PortalStatCard.tile(icon: Icons.bedtime, value: '7.5 h', label: 'Sleep'),
      PortalStatCard.tile(
          icon: Icons.directions_walk,
          value: '8,200',
          label: 'Steps',
          note: '+4%'),
      PortalStatCard.tile(icon: Icons.water_drop, value: '2 L', label: 'Water'),
    ])));
    expect(t.takeException(), isNull);
    expect(find.text('Sleep'), findsOneWidget);
    expect(find.text('Steps'), findsOneWidget);
  });

  testWidgets('a row of plain cards lays out under IntrinsicHeight', (t) async {
    await t.pumpWidget(host(const PortalStatRow(stats: [
      PortalStatCard(value: '9', label: 'Done', delta: '+2'),
      PortalStatCard(value: '3', label: 'Open'),
      PortalStatCard(value: '1', label: 'Late'),
    ])));
    expect(t.takeException(), isNull);
    expect(find.text('Open'), findsOneWidget);
  });

  testWidgets('a long tile label shrinks to fit instead of overflowing',
      (t) async {
    await t.pumpWidget(host(const SizedBox(
      width: 300,
      child: PortalStatRow(stats: [
        PortalStatCard.tile(
            icon: Icons.bedtime, value: '1', label: 'Average weekly sleep'),
        PortalStatCard.tile(icon: Icons.bedtime, value: '2', label: 'B'),
      ]),
    )));
    expect(t.takeException(), isNull);
    expect(find.text('Average weekly sleep'), findsOneWidget);
  });
}
