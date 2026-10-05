import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

/// Per-component re-skin hooks.
///
/// Each class is a [ThemeExtension] whose every field is nullable: null means
/// "derive from the tokens", so an app sets only what its brand changes. An
/// explicit constructor argument on the widget still wins over the theme.
/// Register them through the existing `PortalThemeConfig.extensionsBuilder`:
///
/// ```dart
/// extensionsBuilder: (ctx) => [
///   PortalStatCardTheme(accentColor: ctx.colorScheme.tertiary),
/// ],
/// ```
@immutable
class PortalStatCardTheme extends ThemeExtension<PortalStatCardTheme> {
  const PortalStatCardTheme({
    this.accentColor,
    this.valueColor,
    this.labelColor,
    this.padding,
    this.wellAlpha,
  });

  /// Glyph tint when the widget passes none. Defaults to the app's primary.
  final Color? accentColor;
  final Color? valueColor;
  final Color? labelColor;

  /// Card padding. Defaults to `spacing.md` all round.
  final EdgeInsetsGeometry? padding;

  /// Opacity of the tint behind the glyph. Defaults to 0.18.
  final double? wellAlpha;

  static PortalStatCardTheme of(BuildContext context) =>
      Theme.of(context).extension<PortalStatCardTheme>() ??
      const PortalStatCardTheme();

  @override
  PortalStatCardTheme copyWith({
    Color? accentColor,
    Color? valueColor,
    Color? labelColor,
    EdgeInsetsGeometry? padding,
    double? wellAlpha,
  }) =>
      PortalStatCardTheme(
        accentColor: accentColor ?? this.accentColor,
        valueColor: valueColor ?? this.valueColor,
        labelColor: labelColor ?? this.labelColor,
        padding: padding ?? this.padding,
        wellAlpha: wellAlpha ?? this.wellAlpha,
      );

  @override
  PortalStatCardTheme lerp(PortalStatCardTheme? other, double t) {
    if (other == null) return this;
    return PortalStatCardTheme(
      accentColor: Color.lerp(accentColor, other.accentColor, t),
      valueColor: Color.lerp(valueColor, other.valueColor, t),
      labelColor: Color.lerp(labelColor, other.labelColor, t),
      padding: EdgeInsetsGeometry.lerp(padding, other.padding, t),
      wellAlpha: lerpDouble(wellAlpha, other.wellAlpha, t),
    );
  }
}

@immutable
class PortalEmptyStateTheme extends ThemeExtension<PortalEmptyStateTheme> {
  const PortalEmptyStateTheme({
    this.iconColor,
    this.iconWellColor,
    this.iconSize,
    this.titleColor,
    this.messageColor,
  });

  /// Defaults to `onSurfaceVariant`.
  final Color? iconColor;

  /// Well behind the glyph when the widget passes none. Null leaves it bare.
  final Color? iconWellColor;

  /// Defaults to `spacing.xxl`.
  final double? iconSize;
  final Color? titleColor;
  final Color? messageColor;

  static PortalEmptyStateTheme of(BuildContext context) =>
      Theme.of(context).extension<PortalEmptyStateTheme>() ??
      const PortalEmptyStateTheme();

  @override
  PortalEmptyStateTheme copyWith({
    Color? iconColor,
    Color? iconWellColor,
    double? iconSize,
    Color? titleColor,
    Color? messageColor,
  }) =>
      PortalEmptyStateTheme(
        iconColor: iconColor ?? this.iconColor,
        iconWellColor: iconWellColor ?? this.iconWellColor,
        iconSize: iconSize ?? this.iconSize,
        titleColor: titleColor ?? this.titleColor,
        messageColor: messageColor ?? this.messageColor,
      );

  @override
  PortalEmptyStateTheme lerp(PortalEmptyStateTheme? other, double t) {
    if (other == null) return this;
    return PortalEmptyStateTheme(
      iconColor: Color.lerp(iconColor, other.iconColor, t),
      iconWellColor: Color.lerp(iconWellColor, other.iconWellColor, t),
      iconSize: lerpDouble(iconSize, other.iconSize, t),
      titleColor: Color.lerp(titleColor, other.titleColor, t),
      messageColor: Color.lerp(messageColor, other.messageColor, t),
    );
  }
}
