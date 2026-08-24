import 'package:flutter/material.dart';

import '../tokens/design_tokens.dart';
import 'portal_color_palettes.dart';
import 'portal_component_themes.dart';
import 'portal_layout_insets.dart';
import 'portal_theme_build_context.dart';
import 'portal_theme_palette.dart';
import 'portal_typography_config.dart';
import 'portal_ui_theme.dart';
import 'theme_factory.dart';

/// Bundles every customizable input for building Portal app themes.
///
/// **Minimal setup** — pick a catalog palette:
/// ```dart
/// final modes = PortalThemePalette.violet.toConfig().build();
/// ```
///
/// **From catalog with app hooks:**
/// ```dart
/// final config = PortalThemeConfig.fromPalette(
///   PortalThemePalette.emerald,
///   typography: myTypography,
/// );
/// ```
@immutable
class PortalThemeConfig {
  const PortalThemeConfig({
    this.palette,
    this.colorPalettes = PortalColorPalettes.zinc,
    this.tokens = DesignTokens.rounded,
    this.layout = const PortalLayoutInsets(),
    this.typography = const PortalTypographyConfig(),
    this.preset,
    this.colorSchemeBuilder,
    this.textThemeBuilder,
    this.extensionsBuilder,
    this.componentThemeOptionsBuilder,
    this.portalUiThemeBuilder,
    this.customize,
    this.useComponentThemes = true,
  });

  /// When set, documents which catalog palette this config started from.
  final PortalThemePalette? palette;

  final PortalColorPalettes colorPalettes;
  final DesignTokens tokens;
  final PortalLayoutInsets layout;
  final PortalTypographyConfig typography;

  /// When null, inferred from [tokens] via [portalPresetForTokens].
  final PortalUiPreset? preset;

  final PortalColorSchemeBuilder? colorSchemeBuilder;
  final PortalTextThemeBuilder? textThemeBuilder;
  final PortalThemeExtensionsBuilder? extensionsBuilder;
  final PortalComponentThemeOptionsBuilder? componentThemeOptionsBuilder;
  final PortalUiThemeBuilder? portalUiThemeBuilder;
  final PortalThemeCustomizer? customize;
  final bool useComponentThemes;

  PortalUiPreset get resolvedPreset =>
      preset ?? portalPresetForTokens(tokens);

  /// Minimal setup from a [PortalThemePalette] with optional fine-grained overrides.
  factory PortalThemeConfig.fromPalette(
    PortalThemePalette palette, {
    PortalColorPalettes? colorPalettes,
    DesignTokens? tokens,
    PortalLayoutInsets? layout,
    PortalTypographyConfig? typography,
    PortalUiPreset? preset,
    PortalColorSchemeBuilder? colorSchemeBuilder,
    PortalTextThemeBuilder? textThemeBuilder,
    PortalThemeExtensionsBuilder? extensionsBuilder,
    PortalComponentThemeOptionsBuilder? componentThemeOptionsBuilder,
    PortalUiThemeBuilder? portalUiThemeBuilder,
    PortalThemeCustomizer? customize,
    bool? useComponentThemes,
  }) {
    return PortalThemeConfig(
      palette: palette,
      colorPalettes: colorPalettes ?? palette.colorPalettes,
      tokens: tokens ?? palette.tokens,
      layout: layout ?? palette.layout,
      typography: typography ?? const PortalTypographyConfig(),
      preset: preset,
      colorSchemeBuilder: colorSchemeBuilder,
      textThemeBuilder: textThemeBuilder,
      extensionsBuilder: extensionsBuilder,
      componentThemeOptionsBuilder: componentThemeOptionsBuilder,
      portalUiThemeBuilder: portalUiThemeBuilder,
      customize: customize,
      useComponentThemes: useComponentThemes ?? true,
    );
  }

  /// Applies a runtime accent while keeping surfaces/tokens from this config.
  PortalThemeConfig withAccent(Color accent) {
    return copyWith(
      colorPalettes: colorPalettes.copyWith(seedColor: accent),
      palette: palette?.withAccent(accent),
    );
  }

  PortalThemeConfig copyWith({
    PortalThemePalette? palette,
    PortalColorPalettes? colorPalettes,
    DesignTokens? tokens,
    PortalLayoutInsets? layout,
    PortalTypographyConfig? typography,
    PortalUiPreset? preset,
    PortalColorSchemeBuilder? colorSchemeBuilder,
    PortalTextThemeBuilder? textThemeBuilder,
    PortalThemeExtensionsBuilder? extensionsBuilder,
    PortalComponentThemeOptionsBuilder? componentThemeOptionsBuilder,
    PortalUiThemeBuilder? portalUiThemeBuilder,
    PortalThemeCustomizer? customize,
    bool? useComponentThemes,
    bool clearPreset = false,
    bool clearPortalUiThemeBuilder = false,
    bool clearColorSchemeBuilder = false,
    bool clearTextThemeBuilder = false,
    bool clearExtensionsBuilder = false,
    bool clearComponentThemeOptionsBuilder = false,
    bool clearCustomize = false,
  }) {
    return PortalThemeConfig(
      palette: palette ?? this.palette,
      colorPalettes: colorPalettes ?? this.colorPalettes,
      tokens: tokens ?? this.tokens,
      layout: layout ?? this.layout,
      typography: typography ?? this.typography,
      preset: clearPreset ? null : (preset ?? this.preset),
      colorSchemeBuilder: clearColorSchemeBuilder
          ? null
          : (colorSchemeBuilder ?? this.colorSchemeBuilder),
      textThemeBuilder: clearTextThemeBuilder
          ? null
          : (textThemeBuilder ?? this.textThemeBuilder),
      extensionsBuilder: clearExtensionsBuilder
          ? null
          : (extensionsBuilder ?? this.extensionsBuilder),
      componentThemeOptionsBuilder: clearComponentThemeOptionsBuilder
          ? null
          : (componentThemeOptionsBuilder ??
              this.componentThemeOptionsBuilder),
      portalUiThemeBuilder: clearPortalUiThemeBuilder
          ? null
          : (portalUiThemeBuilder ?? this.portalUiThemeBuilder),
      customize: clearCustomize ? null : (customize ?? this.customize),
      useComponentThemes: useComponentThemes ?? this.useComponentThemes,
    );
  }

  /// Both light and dark themes for an optional runtime [accent].
  PortalThemeModes build({Color? accent}) {
    return PortalThemeModes(
      light: light(accent: accent),
      dark: dark(accent: accent),
    );
  }

  ThemeData light({Color? accent}) =>
      _buildTheme(brightness: Brightness.light, accent: accent);

  ThemeData dark({Color? accent}) =>
      _buildTheme(brightness: Brightness.dark, accent: accent);

  ThemeData _buildTheme({
    required Brightness brightness,
    Color? accent,
  }) {
    final resolvedAccent = accent ?? colorPalettes.seedColor;
    final colorScheme = _resolveColorScheme(
      brightness: brightness,
      accent: resolvedAccent,
    );
    final surfacePalette = colorPalettes.forBrightness(brightness);

    var theme = buildPortalTheme(
      brightness: brightness,
      preset: resolvedPreset,
      colorScheme: colorScheme,
      tokens: tokens,
    );

    var portal = theme.extension<PortalUiTheme>()!;
    var textTheme = theme.textTheme;

    if (portalUiThemeBuilder != null) {
      final preCtx = PortalThemeBuildContext(
        brightness: brightness,
        colorScheme: colorScheme,
        portal: portal,
        tokens: tokens,
        textTheme: textTheme,
        theme: theme,
        palettes: colorPalettes,
        surfacePalette: surfacePalette,
        layout: layout,
      );
      portal = portalUiThemeBuilder!(preCtx, portal);
      theme = theme.copyWith(extensions: <ThemeExtension<dynamic>>[portal]);
    }

    final buildCtx = PortalThemeBuildContext(
      brightness: brightness,
      colorScheme: colorScheme,
      portal: portal,
      tokens: tokens,
      textTheme: textTheme,
      theme: theme,
      palettes: colorPalettes,
      surfacePalette: surfacePalette,
      layout: layout,
    );

    final typographyMerger = textThemeBuilder ?? typography.merge;
    if (typographyMerger != null) {
      textTheme = typographyMerger(buildCtx, textTheme);
      theme = theme.copyWith(textTheme: textTheme);
    }

    if (extensionsBuilder != null) {
      final extras = extensionsBuilder!(buildCtx);
      theme = theme.copyWith(
        extensions: [...theme.extensions.values, ...extras],
      );
    }

    if (useComponentThemes) {
      final options = componentThemeOptionsBuilder?.call(buildCtx) ??
          surfacePalette.toComponentThemeOptions();
      theme = applyPortalComponentThemes(
        base: theme,
        colorScheme: colorScheme,
        tokens: tokens,
        textTheme: textTheme,
        options: options,
      );
    }

    if (customize != null) {
      theme = customize!(buildCtx, theme);
    }

    return theme;
  }

  ColorScheme _resolveColorScheme({
    required Brightness brightness,
    Color? accent,
  }) {
    final resolvedAccent = accent ?? colorPalettes.seedColor;

    if (colorSchemeBuilder != null) {
      final base = ColorScheme.fromSeed(
        seedColor: resolvedAccent,
        brightness: brightness,
      );
      return colorSchemeBuilder!(
        PortalColorSchemeBuildContext(
          brightness: brightness,
          seedColor: resolvedAccent,
          base: base,
          palettes: colorPalettes,
        ),
      );
    }

    return colorPalettes.colorScheme(
      brightness: brightness,
      accent: resolvedAccent,
    );
  }
}

/// Kit default — violet palette, rounded tokens, component themes.
final PortalThemeConfig portalDefaultThemeConfig =
    PortalThemePalette.violet.toConfig();
