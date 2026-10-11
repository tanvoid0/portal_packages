import 'package:flutter/material.dart';
import 'package:material_color_utilities/material_color_utilities.dart';

import '../motion/portal_haptics.dart';
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
    this.haptics,
    this.dynamicColor = false,
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

  /// When given, sets [PortalHaptics.enabled] every time a theme is built
  /// from this config. Left null (the default) so a theme rebuild — e.g.
  /// switching accent colour — does not overwrite the user's own haptics
  /// setting; a caller that genuinely wants to force the switch (a demo, a
  /// test) passes it explicitly.
  final bool? haptics;

  /// Follow the device's dynamic colour (Android 12+ Material You).
  ///
  /// Off by default: every app has a deliberate brand palette and wallpaper
  /// colour fights it. On, `PortalDynamicColorBuilder` harmonises the brand
  /// seed toward the wallpaper's primary — see [build] `wallpaper:`. The flag
  /// is read by that widget only, and may flip at runtime (the widget keeps
  /// its subtree mounted); [build] itself harmonises whenever it is handed a
  /// wallpaper scheme.
  final bool dynamicColor;

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
    bool? haptics,
    bool dynamicColor = false,
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
      haptics: haptics,
      dynamicColor: dynamicColor,
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
    bool? haptics,
    bool? dynamicColor,
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
      haptics: haptics ?? this.haptics,
      dynamicColor: dynamicColor ?? this.dynamicColor,
    );
  }

  /// Both light and dark themes for an optional runtime [accent].
  ///
  /// [wallpaper] is the device's dynamic scheme (what
  /// `PortalDynamicColorBuilder` feeds in). When given, the seed — [accent] or
  /// the palette's — is harmonised toward its primary ([Blend.harmonize]: hue
  /// rotated up to 15°, chroma and tone kept), so the palette nods to the
  /// wallpaper without giving up the brand. Semantic roles derive from the
  /// resulting primary and follow. Surfaces and tokens are the config's own
  /// either way.
  PortalThemeModes build({Color? accent, ColorScheme? wallpaper}) {
    var seed = accent;
    if (wallpaper != null) {
      seed = Color(Blend.harmonize(
        (accent ?? colorPalettes.seedColor).toARGB32(),
        wallpaper.primary.toARGB32(),
      ));
    }
    return PortalThemeModes(
      light: light(accent: seed),
      dark: dark(accent: seed),
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
    if (haptics != null) PortalHaptics.enabled = haptics!;
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
      theme = theme.copyWith(
        extensions: [...theme.extensions.values, portal],
      );
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
