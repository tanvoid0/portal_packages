import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

void main() {
  const photo = Key('photo');
  const footer = Key('footer');

  Widget tile({required double footerHeight, double width = 136, double height = 102}) =>
      MaterialApp(
        theme: buildPortalTheme(brightness: Brightness.light),
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: width,
              height: height,
              child: PortalMediaTile(
                scrim: false,
                photo: const ColoredBox(key: photo, color: Colors.teal),
                footer: Column(
                  key: footer,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(height: footerHeight / 2),
                    SizedBox(height: footerHeight / 2),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

  testWidgets('a footer that fits leaves the photo the rest of the tile',
      (t) async {
    await t.pumpWidget(tile(footerHeight: 40));
    expect(t.takeException(), isNull);
    expect(t.getSize(find.byKey(photo)).height, 62);
    expect(t.getSize(find.byKey(footer)).height, 40);
  });

  testWidgets('a footer taller than the tile is clipped, the photo keeps a quarter',
      (t) async {
    // 107 dp of footer in a 102 dp tile: the photo used to be squeezed to 0
    // and the Column overflowed.
    await t.pumpWidget(tile(footerHeight: 107));
    expect(t.takeException(), isNull);
    expect(t.getSize(find.byKey(photo)).height, 102 / 4);
    expect(t.getSize(find.byType(SingleChildScrollView)).height, 102 * 3 / 4);
  });

  testWidgets('topEnd and bottomStart lay out independently of the original pair',
      (t) async {
    const topEnd = Key('topEnd');
    const bottomStart = Key('bottomStart');
    await t.pumpWidget(MaterialApp(
      theme: buildPortalTheme(brightness: Brightness.light),
      home: const Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 136,
            height: 102,
            child: PortalMediaTile(
              photo: ColoredBox(color: Colors.teal),
              topEnd: SizedBox(key: topEnd, width: 8, height: 8),
              bottomStart: SizedBox(key: bottomStart, width: 8, height: 8),
            ),
          ),
        ),
      ),
    ));
    expect(t.takeException(), isNull);
    expect(find.byKey(topEnd), findsOneWidget);
    expect(find.byKey(bottomStart), findsOneWidget);
  });

  testWidgets('a footer taller than the tile does not eat taps meant for it',
      (t) async {
    var taps = 0;
    await t.pumpWidget(MaterialApp(
      theme: buildPortalTheme(brightness: Brightness.light),
      home: Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 136,
            height: 102,
            child: PortalMediaTile(
              photo: const ColoredBox(color: Colors.teal),
              footer: const SizedBox(height: 300),
              onTap: () => taps++,
            ),
          ),
        ),
      ),
    ));
    await t.tapAt(const Offset(68, 90));
    expect(taps, 1);
    expect(t.takeException(), isNull);
  });
}
