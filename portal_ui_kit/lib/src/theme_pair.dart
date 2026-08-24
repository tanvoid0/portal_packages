import 'package:flutter/material.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

/// Light/dark [ThemeData] pair keyed by [name], matching the old kit API.
@immutable
class ThemePair {
  const ThemePair({
    required this.name,
    required this.light,
    required this.dark,
  });

  final String name;
  final ThemeData light;
  final ThemeData dark;

  ThemeData getTheme(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return light;
      case ThemeMode.dark:
        return dark;
      case ThemeMode.system:
        final brightness =
            WidgetsBinding.instance.platformDispatcher.platformBrightness;
        return brightness == Brightness.dark ? dark : light;
    }
  }
}

/// Lets call sites written for the old kit keep using `.toThemeData()`.
extension PortalThemeDataCompat on ThemeData {
  ThemeData toThemeData() => this;
}

List<ThemePair>? _customThemes;

/// Named theme pairs built from [PortalThemeCatalog].
///
/// Includes a `default` entry (violet) so existing apps that persist that
/// name keep resolving after the move off the archived kit.
List<ThemePair> get customThemes {
  return _customThemes ??= [
    _fromPalette('default', PortalThemePalette.violet),
    for (final palette in PortalThemeCatalog.all)
      _fromPalette(palette.label.toLowerCase(), palette),
  ];
}

ThemePair _fromPalette(String name, PortalThemePalette palette) {
  final config = palette.toConfig();
  return ThemePair(
    name: name,
    light: config.light(),
    dark: config.dark(),
  );
}
