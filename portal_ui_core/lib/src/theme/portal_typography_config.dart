import 'package:flutter/material.dart';

import '../tokens/design_tokens.dart';
import 'portal_theme_build_context.dart';

/// Optional typography customization applied after the portal base [TextTheme].
typedef PortalTextThemeMerger = TextTheme Function(
  PortalThemeBuildContext context,
  TextTheme baseTextTheme,
);

/// Typography configuration for [PortalThemeConfig].
@immutable
class PortalTypographyConfig {
  const PortalTypographyConfig({this.merge});

  /// When set, receives the portal base text theme and returns the final theme.
  /// Use for Google Fonts, weight tweaks, or accent-colored labels.
  final PortalTextThemeMerger? merge;

  PortalTypographyConfig copyWith({PortalTextThemeMerger? merge}) {
    return PortalTypographyConfig(merge: merge ?? this.merge);
  }
}

/// Builds a [TextTheme] from [DesignTokens.textStyles] and a [ColorScheme].
TextTheme portalTextThemeFromTokens({
  required ColorScheme colorScheme,
  required DesignTokens tokens,
}) {
  final scheme = colorScheme;
  final t = tokens.typeScale;
  final s = tokens.textStyles;
  final muted = scheme.onSurfaceVariant;

  return TextTheme(
    displayLarge: s.display.copyWith(color: scheme.onSurface),
    displayMedium: s.headline.copyWith(color: scheme.onSurface),
    displaySmall: s.title.copyWith(color: scheme.onSurface),
    headlineLarge: s.headline.copyWith(color: scheme.onSurface),
    headlineMedium: s.title.copyWith(color: scheme.onSurface),
    headlineSmall: s.subtitle.copyWith(color: scheme.onSurface),
    titleLarge: s.title.copyWith(color: scheme.onSurface),
    titleMedium: s.subtitle.copyWith(color: scheme.onSurface),
    titleSmall: TextStyle(
      fontSize: t.lg,
      fontWeight: FontWeight.w600,
      color: scheme.onSurface,
    ),
    bodyLarge: s.body.copyWith(color: scheme.onSurface),
    bodyMedium: TextStyle(fontSize: t.md, color: muted, height: 1.45),
    bodySmall: s.caption.copyWith(color: muted),
    labelLarge: TextStyle(
      fontSize: t.md,
      fontWeight: FontWeight.w600,
      color: scheme.onSurface,
    ),
    labelMedium: TextStyle(fontSize: t.sm, color: muted),
    labelSmall: s.overline.copyWith(color: muted),
  );
}
