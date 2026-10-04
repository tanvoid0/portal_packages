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
    this.darkOnError = const Color(0xFF410002),
  });

  final PortalSurfacePalette light;
  final PortalSurfacePalette dark;
  final Color seedColor;
  final Color lightError;
  final Color darkError;

  /// Foreground on [lightError].
  final Color onError;

  /// Foreground on [darkError]. White on the dark red reads 3.76:1, under AA,
  /// so the dark side takes M3's error ink instead (F2).
  final Color darkOnError;

  PortalSurfacePalette forBrightness(Brightness brightness) =>
      brightness == Brightness.dark ? dark : light;

  PortalColorPalettes copyWith({
    PortalSurfacePalette? light,
    PortalSurfacePalette? dark,
    Color? seedColor,
    Color? lightError,
    Color? darkError,
    Color? onError,
    Color? darkOnError,
  }) {
    return PortalColorPalettes(
      light: light ?? this.light,
      dark: dark ?? this.dark,
      seedColor: seedColor ?? this.seedColor,
      lightError: lightError ?? this.lightError,
      darkError: darkError ?? this.darkError,
      onError: onError ?? this.onError,
      darkOnError: darkOnError ?? this.darkOnError,
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
    final dark = brightness == Brightness.dark;
    final error = dark ? darkError : lightError;

    return palette.applySurfacesTo(base).copyWith(
          primary: base.primary,
          onPrimary: base.onPrimary,
          primaryContainer: base.primaryContainer,
          onPrimaryContainer: base.onPrimaryContainer,
          tertiary: base.tertiary,
          error: error,
          onError: dark ? darkOnError : onError,
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
      // Reads as ColorScheme.outline, and task draws control borders from it
      // directly. Zinc-300 was 1.39:1 on the page, under the 3:1 a border or
      // icon needs; this is 3.06 on the page and 3.25 on the card (F2).
      trackBorder: Color(0xFF8E8E96),
      nodePill: Color(0xFFE4E4E7),
      onSurface: Color(0xFF18181B),
      // Zinc-500 (#71717A) is 4.40:1 on surfaceElevated / zinc-100, under AA
      // for text, and it feeds onSurfaceVariant: placeholders, hints, source
      // chips and muted text on a grouped page all failed on it, and a
      // chevron mixed from it read 2.84:1 against the 3:1 a control needs.
      // Stepped 12% toward onSurface — 5.15:1 (K9).
      onSurfaceMuted: Color(0xFF66666F),
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
      // 1.91:1 on the page before; 4.12 now, 3.08 on the card (F2).
      trackBorder: Color(0xFF71717A),
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
      // 1.42:1 before; 3.26 on the page, 3.41 on the card (F2).
      trackBorder: Color(0xFF7D8CA3),
      nodePill: Color(0xFFE2E8F0),
      onSurface: Color(0xFF0F172A),
      // Slate-500 was 4.34:1 on surfaceContainerHigh, the same defect zinc
      // had (K9); stepped toward onSurface (F2).
      onSurfaceMuted: Color(0xFF5B687E),
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
      // 2.66:1 before; 4.24 on the page, 3.07 on the card (F2).
      trackBorder: Color(0xFF64748B),
      nodePill: Color(0xFF334155),
      onSurface: Color(0xFFF8FAFC),
      // Slate-400 was 4.04:1 on surfaceContainer, the grouped page's tone;
      // stepped 12% toward onSurface — 4.55 there, 6.43 on the card (F2).
      onSurfaceMuted: Color(0xFFA0ADC0),
      navBar: Color(0xFF020617),
      navPill: Color(0xFF334155),
      onAccentDark: Color(0xFF0F172A),
    ),
    seedColor: Color(0xFF64748B),
  );
}
