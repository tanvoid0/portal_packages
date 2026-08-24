import 'package:flutter/material.dart';

import '../tokens/design_tokens.dart';
import 'portal_default_color_schemes.dart';
import 'portal_theme_build_context.dart';
import 'portal_typography.dart';
import 'portal_ui_theme.dart';

/// Named style bundles for quick setup. Customise via [PortalThemeConfig] or
/// [buildPortalTheme] with your own tokens and [ColorScheme].
enum PortalUiPreset { defaultPreset, compact, rounded, generous }

PortalUiTheme _portalExtension(ColorScheme scheme, DesignTokens tokens) {
  final destructive = scheme.error;
  final onDestructive = scheme.onError;
  final muted = scheme.surfaceContainerLow;
  final onMuted = scheme.onSurfaceVariant;
  final accent = scheme.surfaceContainerHigh;
  final card = scheme.surfaceContainerHighest;
  final popover = scheme.surfaceContainerHighest;
  final border = scheme.outline.withValues(alpha: 0.65);
  final input = scheme.surfaceContainerHigh.withValues(alpha: 0.5);

  return PortalUiTheme(
    tokens: tokens,
    primary: scheme.primary,
    onPrimary: scheme.onPrimary,
    secondary: scheme.secondary,
    onSecondary: scheme.onSecondary,
    surface: scheme.surface,
    onSurface: scheme.onSurface,
    surfaceVariant: scheme.surfaceContainerHighest,
    onSurfaceVariant: scheme.onSurfaceVariant,
    outline: scheme.outline,
    destructive: destructive,
    onDestructive: onDestructive,
    muted: muted,
    onMuted: onMuted,
    focusRing: scheme.primary.withValues(alpha: 0.45),
    accent: accent,
    onAccent: scheme.onSurface,
    card: card,
    onCard: scheme.onSurface,
    popover: popover,
    onPopover: scheme.onSurface,
    border: border,
    input: input,
  );
}

TextTheme _textTheme(ColorScheme scheme, DesignTokens tokens) {
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
    labelLarge: portalControlLabelStyle(t.md, color: scheme.onSurface),
    labelMedium: TextStyle(fontSize: t.sm, color: muted),
    labelSmall: s.overline.copyWith(color: muted),
  );
}

/// Builds [ThemeData] with [PortalUiTheme] attached. Use [preset] for spacing
/// and radii; override [colorScheme] and [tokens] for brand/layout.
///
/// Prefer [PortalThemeConfig] when you need light/dark pairs and component themes.
ThemeData buildPortalTheme({
  required Brightness brightness,
  PortalUiPreset preset = PortalUiPreset.defaultPreset,
  ColorScheme? colorScheme,
  DesignTokens? tokens,
}) {
  final scheme = colorScheme ?? portalDefaultColorScheme(brightness);
  final resolvedTokens = tokens ?? designTokensForPreset(preset);
  final portal = _portalExtension(scheme, resolvedTokens);
  final textTheme = _textTheme(scheme, resolvedTokens);

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: scheme.surface,
    textTheme: textTheme,
    extensions: <ThemeExtension<dynamic>>[portal],
    splashFactory: InkSparkle.splashFactory,
  );
}
