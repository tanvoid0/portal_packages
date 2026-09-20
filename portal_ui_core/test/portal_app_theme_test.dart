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

  group('B4 sub-themes', () {
    test('pickers, sheet, tabs and slider are themed from tokens', () {
      final theme = PortalThemePalette.violet.toConfig().light();
      // Pickers share the dialog's shell, whatever surface the palette gave it.
      final panel = theme.dialogTheme.backgroundColor;
      final xl = BorderRadius.circular(portalUiThemeFrom(theme)!.tokens.radii.xl);

      expect(theme.datePickerTheme.backgroundColor, panel);
      expect((theme.datePickerTheme.shape as RoundedRectangleBorder).borderRadius, xl);
      expect(theme.timePickerTheme.backgroundColor, panel);
      expect((theme.timePickerTheme.shape as RoundedRectangleBorder).borderRadius, xl);
      // The unselected hour/minute field must not vanish into the panel.
      final unselectedField = WidgetStateProperty.resolveAs<Color?>(
        theme.timePickerTheme.hourMinuteColor,
        const <WidgetState>{},
      );
      expect(unselectedField, isNotNull);
      expect(unselectedField, isNot(panel));
      // Handle styled, not forced: apps still hand-draw one on transparent sheets.
      expect(theme.bottomSheetTheme.showDragHandle, isNull);
      expect(theme.bottomSheetTheme.dragHandleSize, const Size(36, 4));
      // Indicator left to M3 so TabBar.indicatorColor and .secondary still work.
      expect(theme.tabBarTheme.indicator, isNull);
      expect(theme.tabBarTheme.dividerColor, Colors.transparent);
      expect(theme.sliderTheme.thumbShape, isA<HandleThumbShape>());
      expect(theme.sliderTheme.trackShape, isA<GappedSliderTrackShape>());
      expect(theme.sliderTheme.rangeThumbShape, isA<HandleRangeSliderThumbShape>());
      expect(theme.sliderTheme.tickMarkShape, isA<RoundSliderTickMarkShape>());
    });
  });

  group('PortalAppTheme', () {
    test('delegates to PortalThemeConfig', () {
      final modes = portalDefaultAppTheme.build();
      expect(modes.light.scaffoldBackgroundColor, isNotNull);
    });
  });
}
