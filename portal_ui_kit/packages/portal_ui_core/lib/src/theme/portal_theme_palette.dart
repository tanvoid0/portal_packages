import 'package:flutter/material.dart';

import '../tokens/design_tokens.dart';
import 'portal_color_palettes.dart';
import 'portal_layout_insets.dart';
import 'portal_theme_build_context.dart';
import 'portal_theme_config.dart';
import 'portal_theme_palette_id.dart';
import 'portal_typography_config.dart';
import 'theme_factory.dart';

/// A pickable, prebuilt theme palette — zinc surfaces + brand seed by default.
///
/// Use as-is for minimal setup, or [copyWith] / [toConfig] hooks for fine control.
///
/// ```dart
/// // Minimal — pick a palette and build
/// final modes = PortalThemePalette.violet.toConfig().build();
///
/// // Runtime accent override (e.g. settings picker)
/// final theme = PortalThemePalette.violet.toConfig().dark(accent: userColor);
///
/// // Deep customize surfaces or tokens
/// PortalThemePalette.emerald.copyWith(
///   surfaces: PortalColorPalettes.zinc.copyWith(
///     light: PortalColorPalettes.zinc.light.copyWith(scaffold: myBg),
///   ),
/// ).toConfig(typography: myTypography);
/// ```
@immutable
class PortalThemePalette {
  const PortalThemePalette({
    required this.id,
    required this.label,
    required this.seedColor,
    this.surfaces = PortalColorPalettes.zinc,
    this.tokens = DesignTokens.rounded,
    this.layout = const PortalLayoutInsets(),
    this.description,
  });

  final PortalThemePaletteId id;
  final String label;
  final Color seedColor;

  /// Neutral surface hierarchy shared by most presets (override for warm/cool).
  final PortalColorPalettes surfaces;
  final DesignTokens tokens;
  final PortalLayoutInsets layout;
  final String? description;

  /// Surfaces + [seedColor] merged for [PortalThemeConfig].
  PortalColorPalettes get colorPalettes =>
      surfaces.copyWith(seedColor: seedColor);

  PortalThemePalette copyWith({
    PortalThemePaletteId? id,
    String? label,
    Color? seedColor,
    PortalColorPalettes? surfaces,
    DesignTokens? tokens,
    PortalLayoutInsets? layout,
    String? description,
  }) {
    return PortalThemePalette(
      id: id ?? this.id,
      label: label ?? this.label,
      seedColor: seedColor ?? this.seedColor,
      surfaces: surfaces ?? this.surfaces,
      tokens: tokens ?? this.tokens,
      layout: layout ?? this.layout,
      description: description ?? this.description,
    );
  }

  /// Same preset with a runtime accent (settings color picker).
  PortalThemePalette withAccent(Color accent) => copyWith(seedColor: accent);

  /// Builds a [PortalThemeConfig] from this palette, with optional overrides.
  PortalThemeConfig toConfig({
    PortalColorPalettes? colorPalettes,
    DesignTokens? tokens,
    PortalLayoutInsets? layout,
    PortalTypographyConfig? typography,
    PortalUiPreset? preset,
    PortalColorSchemeBuilder? colorSchemeBuilder,
    PortalTextThemeBuilder? textThemeBuilder,
    PortalThemeExtensionsBuilder? extensionsBuilder,
    PortalComponentThemeOptionsBuilder? componentThemeOptionsBuilder,
    PortalThemeCustomizer? customize,
    bool? useComponentThemes,
  }) {
    return PortalThemeConfig(
      colorPalettes: colorPalettes ?? this.colorPalettes,
      tokens: tokens ?? this.tokens,
      layout: layout ?? this.layout,
      typography: typography ?? const PortalTypographyConfig(),
      preset: preset,
      colorSchemeBuilder: colorSchemeBuilder,
      textThemeBuilder: textThemeBuilder,
      extensionsBuilder: extensionsBuilder,
      componentThemeOptionsBuilder: componentThemeOptionsBuilder,
      customize: customize,
      useComponentThemes: useComponentThemes ?? true,
    );
  }

  // ── Prebuilt palettes (zinc surfaces + brand seed) ─────────────────────

  static const PortalThemePalette zinc = PortalThemePalette(
    id: PortalThemePaletteId.zinc,
    label: 'Zinc',
    seedColor: Color(0xFF52525B),
    description: 'Neutral gray accent on zinc surfaces',
  );

  static const PortalThemePalette violet = PortalThemePalette(
    id: PortalThemePaletteId.violet,
    label: 'Violet',
    seedColor: Color(0xFF7C3AED),
    description: 'Portal Task default — purple accent',
  );

  static const PortalThemePalette indigo = PortalThemePalette(
    id: PortalThemePaletteId.indigo,
    label: 'Indigo',
    seedColor: Color(0xFF6366F1),
    description: 'Indigo accent',
  );

  static const PortalThemePalette blue = PortalThemePalette(
    id: PortalThemePaletteId.blue,
    label: 'Blue',
    seedColor: Color(0xFF3B82F6),
  );

  static const PortalThemePalette emerald = PortalThemePalette(
    id: PortalThemePaletteId.emerald,
    label: 'Emerald',
    seedColor: Color(0xFF10B981),
  );

  static const PortalThemePalette teal = PortalThemePalette(
    id: PortalThemePaletteId.teal,
    label: 'Teal',
    seedColor: Color(0xFF14B8A6),
  );

  static const PortalThemePalette rose = PortalThemePalette(
    id: PortalThemePaletteId.rose,
    label: 'Rose',
    seedColor: Color(0xFFF43F5E),
  );

  static const PortalThemePalette orange = PortalThemePalette(
    id: PortalThemePaletteId.orange,
    label: 'Orange',
    seedColor: Color(0xFFF97316),
  );

  static const PortalThemePalette amber = PortalThemePalette(
    id: PortalThemePaletteId.amber,
    label: 'Amber',
    seedColor: Color(0xFFF59E0B),
  );

  /// Cool blue-gray surfaces (slate neutrals instead of zinc).
  static const PortalThemePalette slate = PortalThemePalette(
    id: PortalThemePaletteId.slate,
    label: 'Slate',
    seedColor: Color(0xFF64748B),
    surfaces: PortalColorPalettes.slate,
    description: 'Cool slate surfaces with blue-gray accent',
  );
}

/// Catalog of pickable [PortalThemePalette]s for settings UI and quick setup.
abstract final class PortalThemeCatalog {
  static const PortalThemePalette defaultPalette = PortalThemePalette.violet;

  static const List<PortalThemePalette> all = [
    PortalThemePalette.zinc,
    PortalThemePalette.violet,
    PortalThemePalette.indigo,
    PortalThemePalette.blue,
    PortalThemePalette.emerald,
    PortalThemePalette.teal,
    PortalThemePalette.rose,
    PortalThemePalette.orange,
    PortalThemePalette.amber,
    PortalThemePalette.slate,
  ];

  static PortalThemePalette byId(PortalThemePaletteId id) {
    for (final palette in all) {
      if (palette.id == id) return palette;
    }
    return defaultPalette;
  }

  static PortalThemePalette? tryById(PortalThemePaletteId id) {
    for (final palette in all) {
      if (palette.id == id) return palette;
    }
    return null;
  }

  /// Finds the catalog entry whose [PortalThemePalette.seedColor] matches
  /// [color] (RGB only). Returns null if no preset matches — use [withAccent].
  static PortalThemePalette? matchingSeed(Color color) {
    for (final palette in all) {
      if (_sameRgb(palette.seedColor, color)) return palette;
    }
    return null;
  }

  static bool _sameRgb(Color a, Color b) =>
      a.r == b.r && a.g == b.g && a.b == b.b;
}
