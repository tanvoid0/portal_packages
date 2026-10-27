import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

void main() {
  Widget host(Widget child) => MaterialApp(
        theme: buildPortalTheme(brightness: Brightness.light),
        home: Scaffold(body: SizedBox(height: 300, child: child)),
      );

  testWidgets('one url shows no dot row', (t) async {
    await t.pumpWidget(host(const PortalPhotoCarousel(urls: ['a.png'])));
    await t.pumpAndSettle();

    expect(find.byType(AnimatedContainer), findsNothing);
  });

  testWidgets('three urls show three dots', (t) async {
    await t.pumpWidget(
      host(const PortalPhotoCarousel(urls: ['a.png', 'b.png', 'c.png'])),
    );
    await t.pumpAndSettle();

    expect(find.byType(AnimatedContainer), findsNWidgets(3));
  });

  testWidgets('swiping advances the page', (t) async {
    int? changed;
    await t.pumpWidget(host(PortalPhotoCarousel(
      urls: const ['a.png', 'b.png', 'c.png'],
      onPageChanged: (i) => changed = i,
    )));
    await t.pumpAndSettle();

    await t.drag(find.byType(PageView), const Offset(-400, 0));
    await t.pumpAndSettle();

    expect(changed, 1);
  });
}
