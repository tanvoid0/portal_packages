import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../components/portal_card.dart' show PortalCardElevation;

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
class PortalCardTheme extends ThemeExtension<PortalCardTheme> {
  const PortalCardTheme({
    this.padding,
    this.borderRadius,
    this.backgroundColor,
    this.border,
    this.elevation,
  });

  /// Defaults to `spacing.lg` all round.
  final EdgeInsetsGeometry? padding;

  /// Defaults to the variant's radius (`radii.lg` for most).
  final BorderRadius? borderRadius;

  /// Fill of every variant that has one. Defaults to the card tone.
  final Color? backgroundColor;

  /// Replaces the variant's border, and also draws on `tonal` and `elevated`,
  /// which have none by default.
  final BorderSide? border;

  /// Shadow level when the widget passes none. Defaults to flat.
  final PortalCardElevation? elevation;

  static PortalCardTheme of(BuildContext context) =>
      Theme.of(context).extension<PortalCardTheme>() ?? const PortalCardTheme();

  @override
  PortalCardTheme copyWith({
    EdgeInsetsGeometry? padding,
    BorderRadius? borderRadius,
    Color? backgroundColor,
    BorderSide? border,
    PortalCardElevation? elevation,
  }) =>
      PortalCardTheme(
        padding: padding ?? this.padding,
        borderRadius: borderRadius ?? this.borderRadius,
        backgroundColor: backgroundColor ?? this.backgroundColor,
        border: border ?? this.border,
        elevation: elevation ?? this.elevation,
      );

  @override
  PortalCardTheme lerp(PortalCardTheme? other, double t) {
    if (other == null) return this;
    return PortalCardTheme(
      padding: EdgeInsetsGeometry.lerp(padding, other.padding, t),
      borderRadius: BorderRadius.lerp(borderRadius, other.borderRadius, t),
      backgroundColor: Color.lerp(backgroundColor, other.backgroundColor, t),
      border: t < 0.5 ? border : other.border,
      elevation: t < 0.5 ? elevation : other.elevation,
    );
  }
}

@immutable
class PortalStatCardTheme extends ThemeExtension<PortalStatCardTheme> {
  const PortalStatCardTheme({
    this.accentColor,
    this.valueColor,
    this.labelColor,
    this.padding,
    this.wellAlpha,
    this.backgroundColor,
  });

  /// Glyph tint when the widget passes none. Defaults to the app's primary.
  final Color? accentColor;
  final Color? valueColor;
  final Color? labelColor;

  /// Card padding. Defaults to `spacing.md` all round.
  final EdgeInsetsGeometry? padding;

  /// Opacity of the tint behind the glyph. Defaults to 0.18.
  final double? wellAlpha;

  /// Card fill when the widget passes none. Defaults to the card's own tone.
  final Color? backgroundColor;

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
    Color? backgroundColor,
  }) =>
      PortalStatCardTheme(
        accentColor: accentColor ?? this.accentColor,
        valueColor: valueColor ?? this.valueColor,
        labelColor: labelColor ?? this.labelColor,
        padding: padding ?? this.padding,
        wellAlpha: wellAlpha ?? this.wellAlpha,
        backgroundColor: backgroundColor ?? this.backgroundColor,
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
      backgroundColor: Color.lerp(backgroundColor, other.backgroundColor, t),
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

@immutable
class PortalBadgeTheme extends ThemeExtension<PortalBadgeTheme> {
  const PortalBadgeTheme({
    this.padding,
    this.textStyle,
    this.tintAlpha,
    this.borderRadius,
  });

  /// Defaults to `spacing.md` across, `spacing.xs` down.
  final EdgeInsetsGeometry? padding;

  /// Defaults to `textStyles.caption` at w600; colour is always the tone's.
  final TextStyle? textStyle;

  /// Opacity of the tone behind the label. Defaults to 0.14 light, 0.22 dark.
  final double? tintAlpha;

  /// Defaults to `radii.full`.
  final BorderRadiusGeometry? borderRadius;

  static PortalBadgeTheme of(BuildContext context) =>
      Theme.of(context).extension<PortalBadgeTheme>() ??
      const PortalBadgeTheme();

  @override
  PortalBadgeTheme copyWith({
    EdgeInsetsGeometry? padding,
    TextStyle? textStyle,
    double? tintAlpha,
    BorderRadiusGeometry? borderRadius,
  }) =>
      PortalBadgeTheme(
        padding: padding ?? this.padding,
        textStyle: textStyle ?? this.textStyle,
        tintAlpha: tintAlpha ?? this.tintAlpha,
        borderRadius: borderRadius ?? this.borderRadius,
      );

  @override
  PortalBadgeTheme lerp(PortalBadgeTheme? other, double t) {
    if (other == null) return this;
    return PortalBadgeTheme(
      padding: EdgeInsetsGeometry.lerp(padding, other.padding, t),
      textStyle: TextStyle.lerp(textStyle, other.textStyle, t),
      tintAlpha: lerpDouble(tintAlpha, other.tintAlpha, t),
      borderRadius:
          BorderRadiusGeometry.lerp(borderRadius, other.borderRadius, t),
    );
  }
}

@immutable
class PortalProgressTheme extends ThemeExtension<PortalProgressTheme> {
  const PortalProgressTheme({
    this.height,
    this.fillColor,
    this.trackColor,
    this.overflowColor,
    this.doneColor,
  });

  /// Track thickness. Defaults to `spacing.sm`.
  final double? height;

  /// Defaults to the app's primary.
  final Color? fillColor;

  /// Defaults to `muted`.
  final Color? trackColor;

  /// Fill once a value passes 1. Defaults to `danger`.
  final Color? overflowColor;

  /// A completed step in `PortalStepProgress`. Defaults to `success`.
  final Color? doneColor;

  static PortalProgressTheme of(BuildContext context) =>
      Theme.of(context).extension<PortalProgressTheme>() ??
      const PortalProgressTheme();

  @override
  PortalProgressTheme copyWith({
    double? height,
    Color? fillColor,
    Color? trackColor,
    Color? overflowColor,
    Color? doneColor,
  }) =>
      PortalProgressTheme(
        height: height ?? this.height,
        fillColor: fillColor ?? this.fillColor,
        trackColor: trackColor ?? this.trackColor,
        overflowColor: overflowColor ?? this.overflowColor,
        doneColor: doneColor ?? this.doneColor,
      );

  @override
  PortalProgressTheme lerp(PortalProgressTheme? other, double t) {
    if (other == null) return this;
    return PortalProgressTheme(
      height: lerpDouble(height, other.height, t),
      fillColor: Color.lerp(fillColor, other.fillColor, t),
      trackColor: Color.lerp(trackColor, other.trackColor, t),
      overflowColor: Color.lerp(overflowColor, other.overflowColor, t),
      doneColor: Color.lerp(doneColor, other.doneColor, t),
    );
  }
}

@immutable
class PortalTextFieldTheme extends ThemeExtension<PortalTextFieldTheme> {
  const PortalTextFieldTheme({
    this.filledColor,
    this.contentPadding,
    this.borderRadius,
  });

  /// Fill of a `filled` field. Defaults to `portal.input`.
  final Color? filledColor;

  /// Defaults to `spacing.lg` across, `spacing.md` down on a `filled` field.
  final EdgeInsetsGeometry? contentPadding;

  /// Corner of a `filled` field. Defaults to `radii.md`.
  final BorderRadius? borderRadius;

  static PortalTextFieldTheme of(BuildContext context) =>
      Theme.of(context).extension<PortalTextFieldTheme>() ??
      const PortalTextFieldTheme();

  @override
  PortalTextFieldTheme copyWith({
    Color? filledColor,
    EdgeInsetsGeometry? contentPadding,
    BorderRadius? borderRadius,
  }) =>
      PortalTextFieldTheme(
        filledColor: filledColor ?? this.filledColor,
        contentPadding: contentPadding ?? this.contentPadding,
        borderRadius: borderRadius ?? this.borderRadius,
      );

  @override
  PortalTextFieldTheme lerp(PortalTextFieldTheme? other, double t) {
    if (other == null) return this;
    return PortalTextFieldTheme(
      filledColor: Color.lerp(filledColor, other.filledColor, t),
      contentPadding:
          EdgeInsetsGeometry.lerp(contentPadding, other.contentPadding, t),
      borderRadius: BorderRadius.lerp(borderRadius, other.borderRadius, t),
    );
  }
}

@immutable
class PortalCalendarTheme extends ThemeExtension<PortalCalendarTheme> {
  const PortalCalendarTheme({
    this.selectedColor,
    this.onSelectedColor,
    this.markerColor,
  });

  /// Fill of the selected day and ink of today. Defaults to the app's primary.
  final Color? selectedColor;

  /// Ink on the selected day. Defaults to `onPrimary`.
  final Color? onSelectedColor;

  /// The dot under a marked day. Defaults to [selectedColor].
  final Color? markerColor;

  static PortalCalendarTheme of(BuildContext context) =>
      Theme.of(context).extension<PortalCalendarTheme>() ??
      const PortalCalendarTheme();

  @override
  PortalCalendarTheme copyWith({
    Color? selectedColor,
    Color? onSelectedColor,
    Color? markerColor,
  }) =>
      PortalCalendarTheme(
        selectedColor: selectedColor ?? this.selectedColor,
        onSelectedColor: onSelectedColor ?? this.onSelectedColor,
        markerColor: markerColor ?? this.markerColor,
      );

  @override
  PortalCalendarTheme lerp(PortalCalendarTheme? other, double t) {
    if (other == null) return this;
    return PortalCalendarTheme(
      selectedColor: Color.lerp(selectedColor, other.selectedColor, t),
      onSelectedColor: Color.lerp(onSelectedColor, other.onSelectedColor, t),
      markerColor: Color.lerp(markerColor, other.markerColor, t),
    );
  }
}

@immutable
class PortalFilterChipTheme extends ThemeExtension<PortalFilterChipTheme> {
  const PortalFilterChipTheme({
    this.selectedColor,
    this.onSelectedColor,
    this.unselectedColor,
    this.onUnselectedColor,
    this.borderColor,
    this.minHeight,
  });

  /// Fill when selected. Defaults to the app's primary.
  final Color? selectedColor;

  /// Label and glyph when selected. Defaults to `onPrimary`.
  final Color? onSelectedColor;

  /// Fill when not selected. Defaults to the surface variant.
  final Color? unselectedColor;

  /// Label and glyph when not selected. Defaults to `onSurfaceVariant`.
  final Color? onUnselectedColor;

  /// Outline when not selected. Defaults to the outline tone.
  final Color? borderColor;

  /// Painted height. Defaults to `minTapTarget` (compact: 32). Under
  /// `minTapTarget` the hit area stays `minTapTarget` around the paint.
  final double? minHeight;

  static PortalFilterChipTheme of(BuildContext context) =>
      Theme.of(context).extension<PortalFilterChipTheme>() ??
      const PortalFilterChipTheme();

  @override
  PortalFilterChipTheme copyWith({
    Color? selectedColor,
    Color? onSelectedColor,
    Color? unselectedColor,
    Color? onUnselectedColor,
    Color? borderColor,
    double? minHeight,
  }) =>
      PortalFilterChipTheme(
        selectedColor: selectedColor ?? this.selectedColor,
        onSelectedColor: onSelectedColor ?? this.onSelectedColor,
        unselectedColor: unselectedColor ?? this.unselectedColor,
        onUnselectedColor: onUnselectedColor ?? this.onUnselectedColor,
        borderColor: borderColor ?? this.borderColor,
        minHeight: minHeight ?? this.minHeight,
      );

  @override
  PortalFilterChipTheme lerp(PortalFilterChipTheme? other, double t) {
    if (other == null) return this;
    return PortalFilterChipTheme(
      selectedColor: Color.lerp(selectedColor, other.selectedColor, t),
      onSelectedColor: Color.lerp(onSelectedColor, other.onSelectedColor, t),
      unselectedColor: Color.lerp(unselectedColor, other.unselectedColor, t),
      onUnselectedColor:
          Color.lerp(onUnselectedColor, other.onUnselectedColor, t),
      borderColor: Color.lerp(borderColor, other.borderColor, t),
      minHeight: lerpDouble(minHeight, other.minHeight, t),
    );
  }
}

@immutable
class PortalNavBarTheme extends ThemeExtension<PortalNavBarTheme> {
  const PortalNavBarTheme({
    this.backgroundColor,
    this.borderColor,
    this.markColor,
    this.selectedWellColor,
    this.selectedMarkColor,
    this.boxShadow,
  });

  /// Bar fill. Defaults to the card tone.
  final Color? backgroundColor;

  /// Bar outline. Defaults to the border tone.
  final Color? borderColor;

  /// Icon and label ink. Defaults to `onCard`.
  final Color? markColor;

  /// The indicator well behind the selected icon. Defaults to the muted tone.
  final Color? selectedWellColor;

  /// Icon ink while selected. Defaults to [markColor].
  final Color? selectedMarkColor;

  /// Defaults to `tokens.elevation.medium`.
  final List<BoxShadow>? boxShadow;

  static PortalNavBarTheme of(BuildContext context) =>
      Theme.of(context).extension<PortalNavBarTheme>() ??
      const PortalNavBarTheme();

  @override
  PortalNavBarTheme copyWith({
    Color? backgroundColor,
    Color? borderColor,
    Color? markColor,
    Color? selectedWellColor,
    Color? selectedMarkColor,
    List<BoxShadow>? boxShadow,
  }) =>
      PortalNavBarTheme(
        backgroundColor: backgroundColor ?? this.backgroundColor,
        borderColor: borderColor ?? this.borderColor,
        markColor: markColor ?? this.markColor,
        selectedWellColor: selectedWellColor ?? this.selectedWellColor,
        selectedMarkColor: selectedMarkColor ?? this.selectedMarkColor,
        boxShadow: boxShadow ?? this.boxShadow,
      );

  @override
  PortalNavBarTheme lerp(PortalNavBarTheme? other, double t) {
    if (other == null) return this;
    return PortalNavBarTheme(
      backgroundColor: Color.lerp(backgroundColor, other.backgroundColor, t),
      borderColor: Color.lerp(borderColor, other.borderColor, t),
      markColor: Color.lerp(markColor, other.markColor, t),
      selectedWellColor:
          Color.lerp(selectedWellColor, other.selectedWellColor, t),
      selectedMarkColor:
          Color.lerp(selectedMarkColor, other.selectedMarkColor, t),
      boxShadow: t < 0.5 ? boxShadow : other.boxShadow,
    );
  }
}
