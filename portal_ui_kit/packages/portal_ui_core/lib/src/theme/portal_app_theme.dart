import 'package:flutter/material.dart';

import 'portal_theme_build_context.dart';
import 'portal_theme_config.dart';

/// Convenience wrapper around [PortalThemeConfig] for apps that prefer a
/// builder-style API. New code should use [PortalThemeConfig] directly.
@immutable
class PortalAppTheme {
  PortalAppTheme({PortalThemeConfig? config})
      : config = config ?? portalDefaultThemeConfig;

  final PortalThemeConfig config;

  PortalThemeModes build({Color? accent}) => config.build(accent: accent);

  ThemeData light({Color? accent}) => config.light(accent: accent);

  ThemeData dark({Color? accent}) => config.dark(accent: accent);

  PortalAppTheme copyWith({PortalThemeConfig? config}) {
    return PortalAppTheme(config: config ?? this.config);
  }
}

/// Kit default — violet catalog palette, rounded tokens, component themes.
final PortalAppTheme portalDefaultAppTheme = PortalAppTheme();
