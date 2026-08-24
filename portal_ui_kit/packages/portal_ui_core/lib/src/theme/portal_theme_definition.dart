import 'package:flutter/material.dart';

import 'portal_color_palettes.dart';
import 'portal_design_token_presets.dart';
import 'portal_theme_build_context.dart';
import 'portal_theme_config.dart';
import 'portal_theme_palette.dart';
import 'portal_theme_preset.dart';

/// Declarative theme spec — define once, [toPreset] builds a full [PortalThemeConfig]
/// that drives every Portal widget via [ThemeData] (no widget edits required).
///
/// Add new entries to your app's theme list and call [PortalThemeRegistry.registerDefinition].
@immutable
class PortalThemeDefinition {
  const PortalThemeDefinition({
    required this.id,
    required this.label,
    this.seedColor,
    this.palette,
    this.surfaces = PortalColorPalettes.zinc,
    this.layout = PortalDesignTokenPresets.rounded,
    this.description,
    this.customize,
    this.tags = const [],
  });

  final String id;
  final String label;

  /// Brand accent. Ignored when [palette] is set (palette seed wins).
  final Color? seedColor;

  /// Start from a catalog palette (surfaces + seed).
  final PortalThemePalette? palette;

  /// Surface hierarchy when not using [palette].
  final PortalColorPalettes surfaces;

  /// Layout tokens (spacing, radii, motion).
  final PortalDesignTokenPreset layout;

  final String? description;
  final PortalThemeCustomizer? customize;
  final List<String> tags;

  Color get resolvedSeed =>
      palette?.seedColor ?? seedColor ?? surfaces.seedColor;

  PortalThemePreset toPreset() {
    final colorPalettes = (palette?.colorPalettes ??
            surfaces.copyWith(seedColor: resolvedSeed))
        .copyWith(seedColor: resolvedSeed);

    return PortalThemePreset(
      id: id,
      label: label,
      description: description ??
          '${layout.label} layout · ${palette?.label ?? 'custom'} accent',
      tags: tags,
      config: PortalThemeConfig(
        palette: palette,
        colorPalettes: colorPalettes,
        tokens: layout.tokens,
        customize: customize,
      ),
    );
  }

  /// Combines a catalog [palette] with a [layout] preset (matrix entry).
  factory PortalThemeDefinition.matrix({
    required PortalThemePalette palette,
    required PortalDesignTokenPreset layout,
  }) {
    return PortalThemeDefinition(
      id: '${palette.id.name}-${layout.id}',
      label: '${palette.label} · ${layout.label}',
      palette: palette,
      layout: layout,
      description: layout.description,
      tags: const ['generated'],
    );
  }
}
