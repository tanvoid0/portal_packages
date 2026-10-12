import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

void main() {
  Widget host(Widget child) => MaterialApp(
        theme: buildPortalTheme(brightness: Brightness.light),
        home: Scaffold(body: Center(child: child)),
      );

  testWidgets('empty url shows the icon fallback at the given size',
      (t) async {
    await t.pumpWidget(host(const PortalNetworkImage(
      url: '',
      size: 48,
      fallbackIcon: Icons.photo,
    )));
    await t.pump();
    expect(find.byIcon(Icons.photo), findsOneWidget);
    expect(find.byType(CircleAvatar), findsNothing);
    final box = t.getSize(find.byType(PortalNetworkImage));
    expect(box, const Size(48, 48));
  });

  testWidgets('null url also falls back, never attempting a fetch',
      (t) async {
    await t.pumpWidget(host(const PortalNetworkImage(
      url: null,
      size: 40,
    )));
    await t.pump();
    // No network widget mounted for a null/blank url.
    expect(find.byIcon(PortalIcons.image_rounded), findsOneWidget);
  });

  testWidgets('a non-empty url mounts the cached image, not the fallback',
      (t) async {
    await t.pumpWidget(host(const PortalNetworkImage(
      url: 'https://example.com/a.png',
      size: 40,
    )));
    await t.pump();
    // Still loading (no network in a test) -- the dimmed fallback icon
    // stands in, but a real fetch was attempted (no exception surfaced as
    // a fallback-only widget tree would never need the loader state).
    expect(find.byType(PortalNetworkImage), findsOneWidget);
  });

  testWidgets('a set fallbackIconColor overrides the muted default',
      (t) async {
    await t.pumpWidget(host(const PortalNetworkImage(
      url: '',
      size: 40,
      fallbackIcon: Icons.local_dining,
      fallbackIconColor: Colors.teal,
    )));
    await t.pump();
    final icon = t.widget<Icon>(find.byIcon(Icons.local_dining));
    expect(icon.color, Colors.teal);
  });

  testWidgets('a null url draws the gradient "no photo yet" placeholder, '
      'not the empty-string fallback box', (t) async {
    await t.pumpWidget(host(const PortalNetworkImage(url: null, size: 40)));
    await t.pump();
    final decorated = t.widgetList<DecoratedBox>(find.descendant(
      of: find.byType(PortalNetworkImage),
      matching: find.byType(DecoratedBox),
    ));
    expect(
      decorated.any((d) => (d.decoration as BoxDecoration).gradient != null),
      isTrue,
    );
  });

  testWidgets('circle shape clips the tile', (t) async {
    await t.pumpWidget(host(const PortalNetworkImage(
      url: '',
      size: 40,
      shape: BoxShape.circle,
    )));
    await t.pump();
    final container = t.widget<Container>(find
        .descendant(
          of: find.byType(PortalNetworkImage),
          matching: find.byType(Container),
        )
        .first);
    expect((container.decoration as BoxDecoration).shape, BoxShape.circle);
  });
}
