import 'package:flutter/material.dart';

import '../tokens/design_tokens.dart';
import 'portal_color_palettes.dart';
import 'portal_component_themes.dart';
import 'portal_layout_insets.dart';
import 'portal_surface_palette.dart';
import 'portal_ui_theme.dart';
import 'theme_factory.dart';

/// Transforms [PortalUiTheme] after the base extension is built (e.g. glass surfaces).
typedef PortalUiThemeBuilder = PortalUiTheme Function(
  PortalThemeBuildContext context,
  PortalUiTheme base,
);

/// Light and dark [ThemeData] pair produced by [PortalThemeConfig.build].
@immutable
class PortalThemeModes {
  const PortalThemeModes({required this.light, required this.dark});

  final ThemeData light;
  final ThemeData dark;
}

/// Context for [PortalColorSchemeBuilder] — customize scheme from a seed or default.
@immutable
class PortalColorSchemeBuildContext {
  const PortalColorSchemeBuildContext({
    required this.brightness,
    required this.seedColor,
    required this.base,
    required this.palettes,
  });

  final Brightness brightness;
  final Color seedColor;
  final ColorScheme base;
  final PortalColorPalettes palettes;

  PortalSurfacePalette get surfacePalette =>
      palettes.forBrightness(brightness);
}

/// Context passed to typography, extension, and theme customizers.
@immutable
class PortalThemeBuildContext {
  const PortalThemeBuildContext({
    required this.brightness,
    required this.colorScheme,
    required this.portal,
    required this.tokens,
    required this.textTheme,
    required this.theme,
    required this.palettes,
    required this.surfacePalette,
    required this.layout,
  });

  final Brightness brightness;
  final ColorScheme colorScheme;
  final PortalUiTheme portal;
  final DesignTokens tokens;
  final TextTheme textTheme;
  final ThemeData theme;
  final PortalColorPalettes palettes;
  final PortalSurfacePalette surfacePalette;
  final PortalLayoutInsets layout;
}

/// Builds or adjusts the [ColorScheme] for one brightness.
typedef PortalColorSchemeBuilder = ColorScheme Function(
  PortalColorSchemeBuildContext context,
);

/// Merges typography after the portal base [TextTheme] is created.
typedef PortalTextThemeBuilder = TextTheme Function(
  PortalThemeBuildContext context,
  TextTheme baseTextTheme,
);

/// Adds app-specific [ThemeExtension]s on top of [PortalUiTheme].
typedef PortalThemeExtensionsBuilder = List<ThemeExtension<dynamic>> Function(
  PortalThemeBuildContext context,
);

/// Final hook to adjust [ThemeData] after component themes are applied.
typedef PortalThemeCustomizer = ThemeData Function(
  PortalThemeBuildContext context,
  ThemeData theme,
);

/// Builds per-brightness surface/nav overrides for component themes.
typedef PortalComponentThemeOptionsBuilder = PortalComponentThemeOptions
    Function(PortalThemeBuildContext context);

/// Resolves [DesignTokens] for a [PortalUiPreset].
DesignTokens designTokensForPreset(PortalUiPreset preset) {
  switch (preset) {
    case PortalUiPreset.defaultPreset:
      return DesignTokens.defaults;
    case PortalUiPreset.compact:
      return DesignTokens.compact;
    case PortalUiPreset.rounded:
      return DesignTokens.rounded;
    case PortalUiPreset.generous:
      return DesignTokens.generous;
  }
}

/// Infers a [PortalUiPreset] from a [DesignTokens] instance.
PortalUiPreset portalPresetForTokens(DesignTokens tokens) {
  if (identical(tokens, DesignTokens.compact)) {
    return PortalUiPreset.compact;
  }
  if (identical(tokens, DesignTokens.generous)) {
    return PortalUiPreset.generous;
  }
  if (identical(tokens, DesignTokens.rounded)) {
    return PortalUiPreset.rounded;
  }
  return PortalUiPreset.defaultPreset;
}
