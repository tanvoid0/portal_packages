import 'package:flutter/material.dart';

import 'portal_surface_palette.dart';

/// Light/dark surface palettes plus brand and semantic colors.
@immutable
class PortalColorPalettes {
  const PortalColorPalettes({
    required this.light,
    required this.dark,
    this.seedColor = const Color(0xFF6366F1),
    this.lightError = const Color(0xFFDC2626),
    this.darkError = const Color(0xFFEF4444),
    this.onError = Colors.white,
  });

  final PortalSurfacePalette light;
  final PortalSurfacePalette dark;
  final Color seedColor;
  final Color lightError;
  final Color darkError;
  final Color onError;

  PortalSurfacePalette forBrightness(Brightness brightness) =>
      brightness == Brightness.dark ? dark : light;

  PortalColorPalettes copyWith({
    PortalSurfacePalette? light,
    PortalSurfacePalette? dark,
    Color? seedColor,
    Color? lightError,
    Color? darkError,
    Color? onError,
  }) {
    return PortalColorPalettes(
      light: light ?? this.light,
      dark: dark ?? this.dark,
      seedColor: seedColor ?? this.seedColor,
      lightError: lightError ?? this.lightError,
      darkError: darkError ?? this.darkError,
      onError: onError ?? this.onError,
    );
  }

  /// Builds a full [ColorScheme] from [seedColor]/[accent] and surface palettes.
  ColorScheme colorScheme({
    required Brightness brightness,
    Color? accent,
  }) {
    final resolvedAccent = accent ?? seedColor;
    final palette = forBrightness(brightness);
    final base = ColorScheme.fromSeed(
      seedColor: resolvedAccent,
      brightness: brightness,
    );
    final error = brightness == Brightness.dark ? darkError : lightError;

    return palette.applySurfacesTo(base).copyWith(
          primary: base.primary,
          onPrimary: base.onPrimary,
          primaryContainer: base.primaryContainer,
          onPrimaryContainer: base.onPrimaryContainer,
          tertiary: base.tertiary,
          error: error,
          onError: onError,
        );
  }

  /// Kit default zinc neutrals.
  static const PortalColorPalettes zinc = PortalColorPalettes(
    light: PortalSurfacePalette(
      scaffold: Color(0xFFF8F8F9),
      surface: Color(0xFFFFFFFF),
      surfaceElevated: Color(0xFFF4F4F5),
      surfacePanel: Color(0xFFEBEBED),
      track: Color(0xFFE4E4E7),
      trackMuted: Color(0xFFF4F4F5),
      trackBorder: Color(0xFFD4D4D8),
      nodePill: Color(0xFFE4E4E7),
      onSurface: Color(0xFF18181B),
      onSurfaceMuted: Color(0xFF71717A),
      navBar: Color(0xFFFFFFFF),
      navPill: Color(0xFFE4E4E7),
    ),
    dark: PortalSurfacePalette(
      scaffold: Color(0xFF09090B),
      surface: Color(0xFF18181B),
      surfaceElevated: Color(0xFF27272A),
      surfacePanel: Color(0xFF1F1F23),
      track: Color(0xFF3F3F46),
      trackMuted: Color(0xFF27272A),
      trackBorder: Color(0xFF3F3F46),
      nodePill: Color(0xFF3F3F46),
      onSurface: Color(0xFFFAFAFA),
      onSurfaceMuted: Color(0xFFA1A1AA),
      navBar: Color(0xFF09090B),
      navPill: Color(0xFF3F3F46),
      onAccentDark: Color(0xFF18181B),
    ),
  );

  /// Cool slate neutrals — blue-gray surface family.
  static const PortalColorPalettes slate = PortalColorPalettes(
    light: PortalSurfacePalette(
      scaffold: Color(0xFFF8FAFC),
      surface: Color(0xFFFFFFFF),
      surfaceElevated: Color(0xFFF1F5F9),
      surfacePanel: Color(0xFFE2E8F0),
      track: Color(0xFFCBD5E1),
      trackMuted: Color(0xFFF1F5F9),
      trackBorder: Color(0xFFCBD5E1),
      nodePill: Color(0xFFE2E8F0),
      onSurface: Color(0xFF0F172A),
      onSurfaceMuted: Color(0xFF64748B),
      navBar: Color(0xFFFFFFFF),
      navPill: Color(0xFFE2E8F0),
    ),
    dark: PortalSurfacePalette(
      scaffold: Color(0xFF020617),
      surface: Color(0xFF0F172A),
      surfaceElevated: Color(0xFF1E293B),
      surfacePanel: Color(0xFF334155),
      track: Color(0xFF475569),
      trackMuted: Color(0xFF1E293B),
      trackBorder: Color(0xFF475569),
      nodePill: Color(0xFF334155),
      onSurface: Color(0xFFF8FAFC),
      onSurfaceMuted: Color(0xFF94A3B8),
      navBar: Color(0xFF020617),
      navPill: Color(0xFF334155),
      onAccentDark: Color(0xFF0F172A),
    ),
    seedColor: Color(0xFF64748B),
  );
}
