import 'package:flutter/material.dart';

import 'portal_color_palettes.dart';

/// Default zinc-inspired light [ColorScheme] for Portal apps.
///
/// Derived from [PortalColorPalettes.zinc] with a neutral primary.
ColorScheme get portalLightColorScheme => PortalColorPalettes.zinc.colorScheme(
      brightness: Brightness.light,
      accent: const Color(0xFF18181B),
    );

/// Default zinc-inspired dark [ColorScheme] for Portal apps.
ColorScheme get portalDarkColorScheme => PortalColorPalettes.zinc.colorScheme(
      brightness: Brightness.dark,
      accent: const Color(0xFFFAFAFA),
    );

/// Returns the kit default [ColorScheme] for [brightness].
ColorScheme portalDefaultColorScheme(Brightness brightness) =>
    brightness == Brightness.dark
        ? portalDarkColorScheme
        : portalLightColorScheme;

/// Builds a seeded [ColorScheme] using Material 3 [ColorScheme.fromSeed].
ColorScheme portalSeededColorScheme({
  required Brightness brightness,
  required Color seedColor,
}) {
  return ColorScheme.fromSeed(
    seedColor: seedColor,
    brightness: brightness,
  );
}
