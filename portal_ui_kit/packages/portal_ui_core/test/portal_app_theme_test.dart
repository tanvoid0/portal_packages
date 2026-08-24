import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

void main() {
  group('PortalThemeConfig', () {
    test('build returns light and dark themes with component layers', () {
      final config = PortalThemePalette.violet.toConfig();
      final modes = config.build();

      expect(modes.light.brightness, Brightness.light);
      expect(modes.dark.brightness, Brightness.dark);
      expect(modes.light.inputDecorationTheme.filled, isTrue);
      expect(modes.dark.chipTheme, isNotNull);
    });

    test('colorSchemeBuilder can customize seeded scheme', () {
      final config = PortalThemeConfig(
        colorPalettes: PortalColorPalettes.zinc,
        colorSchemeBuilder: (ctx) =>
            ctx.base.copyWith(surface: const Color(0xFFFF0000)),
      );
      final light = config.light();

      expect(light.colorScheme.surface, const Color(0xFFFF0000));
    });

    test('customize hook receives built theme', () {
      final config = PortalThemeConfig(
        customize: (ctx, theme) => theme.copyWith(
          cardTheme: theme.cardTheme.copyWith(
            margin: const EdgeInsets.all(8),
          ),
        ),
      );
      final theme = config.light();

      expect(theme.cardTheme.margin, isNotNull);
    });

    test('surface palette maps to color scheme roles', () {
      final scheme = PortalColorPalettes.zinc.colorScheme(
        brightness: Brightness.light,
        accent: const Color(0xFF7C3AED),
      );

      expect(scheme.surface, PortalColorPalettes.zinc.light.scaffold);
      expect(scheme.onSurfaceVariant, PortalColorPalettes.zinc.light.onSurfaceMuted);
    });
  });

  group('PortalAppTheme', () {
    test('delegates to PortalThemeConfig', () {
      final modes = portalDefaultAppTheme.build();
      expect(modes.light.scaffoldBackgroundColor, isNotNull);
    });
  });
}
