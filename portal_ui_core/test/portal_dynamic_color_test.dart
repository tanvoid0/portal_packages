// CorePalette is deprecated upstream but is the plugin's wire format: the
// mocked channel below must answer what dynamic_color decodes with
// CorePalette.fromList.
// ignore_for_file: deprecated_member_use

import 'dart:typed_data';

import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_color_utilities/material_color_utilities.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

double _hue(Color c) => Hct.fromInt(c.toARGB32()).hue;

double _hueDiff(Color a, Color b) {
  final d = (_hue(a) - _hue(b)).abs() % 360;
  return d > 180 ? 360 - d : d;
}

void main() {
  final config = PortalThemePalette.violet.toConfig();
  // Red: far enough from violet that harmonising visibly moves the seed.
  const wallpaperSeed = Color(0xFFE53935);
  final wallpaper = ColorScheme.fromSeed(seedColor: wallpaperSeed);

  group('PortalThemeConfig.dynamicColor', () {
    test('off by default, toggles through copyWith and fromPalette', () {
      expect(config.dynamicColor, isFalse);
      expect(config.copyWith(dynamicColor: true).dynamicColor, isTrue);
      expect(
        PortalThemeConfig.fromPalette(
          PortalThemePalette.violet,
          dynamicColor: true,
        ).dynamicColor,
        isTrue,
      );
    });

    test('build(wallpaper:) harmonises the seed and the semantic roles', () {
      final brand = config.build().light;
      final tuned = config.build(wallpaper: wallpaper).light;
      final bp = brand.colorScheme.primary, tp = tuned.colorScheme.primary;

      expect(tp, isNot(bp));
      // Harmonise, not replace: rotated toward the wallpaper by at most 15°.
      expect(_hueDiff(tp, bp), lessThanOrEqualTo(15.5));
      expect(_hueDiff(tp, wallpaper.primary),
          lessThan(_hueDiff(bp, wallpaper.primary)));
      // Semantic roles are computed from the tuned scheme by theme_factory,
      // so they follow for free; not asserted here because a role only moves
      // when it sits within 30° of a primary (Blend.harmonize caps at 15°),
      // and violet toward red moves none of them.
    });
  });

  group('PortalDynamicColorBuilder', () {
    // Answers the plugin channel as an Android 12+ device would, recording
    // every call so the off path can prove it never asked.
    List<String> mockWallpaper(WidgetTester tester) {
      final calls = <String>[];
      final messenger = tester.binding.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(DynamicColorPlugin.channel,
          (call) async {
        calls.add(call.method);
        if (call.method != DynamicColorPlugin.methodName) return null;
        // Android answers an IntArray, which the codec decodes as Int32List.
        return Int32List.fromList(
          CorePalette.of(wallpaperSeed.toARGB32()).asList(),
        );
      });
      addTearDown(() =>
          messenger.setMockMethodCallHandler(DynamicColorPlugin.channel, null));
      return calls;
    }

    final brand = config.build().light.colorScheme.primary;

    testWidgets('off: brand palette, no platform channel', (tester) async {
      final calls = mockWallpaper(tester);
      late PortalThemeModes modes;
      await tester.pumpWidget(PortalDynamicColorBuilder(
        config: config,
        builder: (_, m) {
          modes = m;
          return const SizedBox();
        },
      ));
      await tester.pump();
      expect(calls, isEmpty);
      expect(modes.light.colorScheme.primary, brand);
    });

    testWidgets(
        'on: brand first frame, then harmonised; flipping off keeps the tree',
        (tester) async {
      mockWallpaper(tester);
      late PortalThemeModes modes;
      Widget app({required bool dynamicColor}) => PortalDynamicColorBuilder(
            config: config.copyWith(dynamicColor: dynamicColor),
            builder: (_, m) {
              modes = m;
              return const SizedBox();
            },
          );

      await tester.pumpWidget(app(dynamicColor: true));
      expect(modes.light.colorScheme.primary, brand);

      await tester.pump(); // the platform answer lands
      final expected = config
          .build(
            wallpaper: CorePalette.of(wallpaperSeed.toARGB32()).toColorScheme(),
          )
          .light
          .colorScheme
          .primary;
      expect(modes.light.colorScheme.primary, expected);
      expect(modes.light.colorScheme.primary, isNot(brand));

      // Same slot, same element: the subtree is updated, not remounted.
      final element = tester.element(find.byType(SizedBox));
      await tester.pumpWidget(app(dynamicColor: false));
      expect(tester.element(find.byType(SizedBox)), same(element));
      expect(modes.light.colorScheme.primary, brand);
    });
  });
}
