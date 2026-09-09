import 'package:flutter/material.dart';

import 'portal_theme_build_context.dart';
import 'portal_theme_config.dart';
import 'portal_theme_palette.dart';
import 'portal_theme_palette_id.dart';
import 'portal_theme_preset.dart';
import 'portal_visual_theme.dart';

/// Combines an accent [PortalThemePalette] with a [PortalVisualTheme] style.
///
/// Palette controls colors; visual theme controls layout tokens and component
/// chrome — pick them independently in settings UI.
abstract final class PortalThemeComposer {
  /// Builds a [PortalThemeConfig] from palette + visual style.
  static PortalThemeConfig config({
    required PortalThemePalette palette,
    required PortalVisualTheme visualTheme,
  }) {
    return PortalThemeConfig.fromPalette(
      palette,
      tokens: visualTheme.tokens,
      componentThemeOptionsBuilder: visualTheme.componentThemeOptionsBuilder,
      portalUiThemeBuilder: visualTheme.resolvedPortalUiThemeBuilder,
      customize: visualTheme.resolvedCustomize,
    );
  }

  /// Light and dark [ThemeData] for [MaterialApp].
  static PortalThemeModes build({
    required PortalThemePalette palette,
    required PortalVisualTheme visualTheme,
    Color? accent,
  }) {
    return config(palette: palette, visualTheme: visualTheme).build(
      accent: accent,
    );
  }

  /// Stable id for persistence: `violet-material`, `emerald-glass`, …
  static String composeId({
    required PortalThemePalette palette,
    required PortalVisualTheme visualTheme,
  }) =>
      '${palette.id.name}-${visualTheme.id}';

  /// Full importable preset (palette + visual style bundled).
  static PortalThemePreset preset({
    required PortalThemePalette palette,
    required PortalVisualTheme visualTheme,
  }) {
    return PortalThemePreset(
      id: composeId(palette: palette, visualTheme: visualTheme),
      label: '${palette.label} · ${visualTheme.label}',
      description: visualTheme.description,
      tags: [...visualTheme.tags, 'composed'],
      config: config(palette: palette, visualTheme: visualTheme),
    );
  }

  /// Resolves a composed preset by palette id + visual theme id strings.
  static PortalThemePreset? tryPresetByIds({
    required String paletteId,
    required String visualThemeId,
  }) {
    PortalThemePaletteId? parsed;
    for (final id in PortalThemePaletteId.values) {
      if (id.name == paletteId) {
        parsed = id;
        break;
      }
    }
    if (parsed == null) return null;
    final palette = PortalThemeCatalog.tryById(parsed);
    final visual = PortalVisualThemeRegistry.instance.tryById(visualThemeId);
    if (palette == null || visual == null) return null;
    return preset(palette: palette, visualTheme: visual);
  }
}
