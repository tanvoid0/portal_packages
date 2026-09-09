import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

void main() {
  group('PortalThemePalette', () {
    test('toConfig builds light and dark themes', () {
      final modes = PortalThemePalette.emerald.toConfig().build();
      expect(modes.light.colorScheme.primary, isNotNull);
      expect(modes.dark.brightness, Brightness.dark);
    });

    test('withAccent overrides seed while keeping surfaces', () {
      const custom = Color(0xFF123456);
      final palette = PortalThemePalette.violet.withAccent(custom);
      expect(palette.seedColor, custom);
      expect(palette.surfaces, PortalColorPalettes.zinc);
    });

    test('slate preset uses slate surfaces', () {
      expect(
        PortalThemePalette.slate.colorPalettes.light.scaffold,
        PortalColorPalettes.slate.light.scaffold,
      );
    });
  });

  group('PortalThemeCatalog', () {
    test('all contains every preset id', () {
      expect(PortalThemeCatalog.all.length, PortalThemePaletteId.values.length);
      for (final id in PortalThemePaletteId.values) {
        expect(PortalThemeCatalog.byId(id).id, id);
      }
    });

    test('matchingSeed finds catalog entry', () {
      final match = PortalThemeCatalog.matchingSeed(
        PortalThemePalette.indigo.seedColor,
      );
      expect(match?.id, PortalThemePaletteId.indigo);
    });

    test('fromPalette is minimal setup', () {
      final config = PortalThemeConfig.fromPalette(PortalThemePalette.rose);
      expect(config.palette?.id, PortalThemePaletteId.rose);
      expect(config.colorPalettes.seedColor, PortalThemePalette.rose.seedColor);
    });
  });
}
