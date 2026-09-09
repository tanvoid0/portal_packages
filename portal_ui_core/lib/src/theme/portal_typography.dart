import 'package:flutter/material.dart';

/// Bold label metrics for interactive controls (buttons, compact actions).
///
/// Always pass an explicit [color] that contrasts with the control’s fill.
/// Do not use [ThemeData.textTheme.labelLarge] (or other roles that embed
/// [ColorScheme.onSurface]) for text on [PortalUiTheme.primary],
/// [PortalUiTheme.destructive], or other non-surface colors: [Text] merges its
/// [Text.style] over [DefaultTextStyle], so a baked-in [onSurface] color wins
/// and can make labels illegible.
///
/// Use the active preset’s type scale (`DesignTokens.typeScale`) for
/// [fontSize] so controls match `buildPortalTheme`.
TextStyle portalControlLabelStyle(
  double fontSize, {
  required Color color,
}) {
  return TextStyle(
    fontSize: fontSize,
    fontWeight: FontWeight.w600,
    color: color,
  );
}
