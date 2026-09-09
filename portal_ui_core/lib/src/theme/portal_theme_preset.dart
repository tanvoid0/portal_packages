import 'package:flutter/material.dart';

import '../tokens/design_tokens.dart';
import 'portal_theme_build_context.dart';
import 'portal_theme_config.dart';
import 'portal_theme_palette.dart';

/// Default composed theme id (`violet` palette + `material` visual style).
const String kPortalDefaultThemeId = 'violet-material';

/// A complete, importable Portal theme — color palette + layout tokens + component
/// themes bundled for one-line [MaterialApp] setup.
@immutable
class PortalThemePreset {
  const PortalThemePreset({
    required this.id,
    required this.label,
    required this.config,
    this.description,
    this.tags = const [],
  });

  final String id;
  final String label;
  final String? description;
  final PortalThemeConfig config;

  /// Optional labels for search/filter (`generated`, `experimental`, …).
  final List<String> tags;

  /// Brand accent shown in settings pickers.
  Color get accentColor => config.colorPalettes.seedColor;

  /// Layout token bundle (spacing, radii, motion).
  DesignTokens get tokens => config.tokens;

  /// Underlying catalog palette when this preset started from one.
  PortalThemePalette? get palette => config.palette;

  PortalThemeModes build({Color? accent}) => config.build(accent: accent);

  ThemeData light({Color? accent}) => config.light(accent: accent);

  ThemeData dark({Color? accent}) => config.dark(accent: accent);
}
