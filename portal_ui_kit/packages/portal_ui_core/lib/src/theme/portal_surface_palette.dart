import 'package:flutter/material.dart';

import 'portal_component_themes.dart';

/// Semantic surface hierarchy for one brightness (scaffold, cards, tracks, nav).
@immutable
class PortalSurfacePalette {
  const PortalSurfacePalette({
    required this.scaffold,
    required this.surface,
    required this.surfaceElevated,
    required this.surfacePanel,
    required this.track,
    required this.trackMuted,
    required this.trackBorder,
    required this.nodePill,
    required this.onSurface,
    required this.onSurfaceMuted,
    required this.navBar,
    required this.navPill,
    this.onAccentDark = Colors.white,
  });

  final Color scaffold;
  final Color surface;
  final Color surfaceElevated;
  final Color surfacePanel;
  final Color track;
  final Color trackMuted;
  final Color trackBorder;
  final Color nodePill;
  final Color onSurface;
  final Color onSurfaceMuted;
  final Color navBar;
  final Color navPill;
  final Color onAccentDark;

  PortalSurfacePalette copyWith({
    Color? scaffold,
    Color? surface,
    Color? surfaceElevated,
    Color? surfacePanel,
    Color? track,
    Color? trackMuted,
    Color? trackBorder,
    Color? nodePill,
    Color? onSurface,
    Color? onSurfaceMuted,
    Color? navBar,
    Color? navPill,
    Color? onAccentDark,
  }) {
    return PortalSurfacePalette(
      scaffold: scaffold ?? this.scaffold,
      surface: surface ?? this.surface,
      surfaceElevated: surfaceElevated ?? this.surfaceElevated,
      surfacePanel: surfacePanel ?? this.surfacePanel,
      track: track ?? this.track,
      trackMuted: trackMuted ?? this.trackMuted,
      trackBorder: trackBorder ?? this.trackBorder,
      nodePill: nodePill ?? this.nodePill,
      onSurface: onSurface ?? this.onSurface,
      onSurfaceMuted: onSurfaceMuted ?? this.onSurfaceMuted,
      navBar: navBar ?? this.navBar,
      navPill: navPill ?? this.navPill,
      onAccentDark: onAccentDark ?? this.onAccentDark,
    );
  }

  /// Maps this palette to Material [ColorScheme] surface roles (non-primary).
  ColorScheme applySurfacesTo(ColorScheme scheme) {
    return scheme.copyWith(
      secondary: surfaceElevated,
      onSecondary: onSurface,
      secondaryContainer: surfacePanel,
      onSecondaryContainer: onSurface,
      surface: scaffold,
      onSurface: onSurface,
      onSurfaceVariant: onSurfaceMuted,
      surfaceContainerHighest: surface,
      surfaceContainerHigh: surfaceElevated,
      surfaceContainer: surfacePanel,
      surfaceContainerLow: trackMuted,
      outline: trackBorder,
      outlineVariant: navPill,
    );
  }

  /// Component-theme surface overrides derived from this palette.
  PortalComponentThemeOptions toComponentThemeOptions() {
    return PortalComponentThemeOptions(
      scaffoldBackgroundColor: scaffold,
      canvasColor: surface,
      navigationBarBackgroundColor: navBar,
      bottomNavigationBarBackgroundColor: navBar,
      appBarBackgroundColor: scaffold,
      cardColor: surface,
    );
  }
}
