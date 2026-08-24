import 'package:flutter/material.dart';

import '../tokens/design_tokens.dart';
import 'portal_surface_treatment.dart';

/// Portal-specific colors and shape tokens, merged into [ThemeData] via
/// [ThemeExtension].
///
/// Semantic roles align with [shadcn/ui](https://ui.shadcn.com/) so bricks can
/// share one vocabulary across palettes and visual styles.
@immutable
class PortalUiTheme extends ThemeExtension<PortalUiTheme> {
  const PortalUiTheme({
    required this.tokens,
    required this.primary,
    required this.onPrimary,
    required this.secondary,
    required this.onSecondary,
    required this.surface,
    required this.onSurface,
    required this.surfaceVariant,
    required this.onSurfaceVariant,
    required this.outline,
    required this.destructive,
    required this.onDestructive,
    required this.muted,
    required this.onMuted,
    required this.focusRing,
    required this.accent,
    required this.onAccent,
    required this.card,
    required this.onCard,
    required this.popover,
    required this.onPopover,
    required this.border,
    required this.input,
    this.surfaceTreatment = PortalSurfaceTreatment.solid,
    this.glassStyle,
  });

  final DesignTokens tokens;

  final Color primary;
  final Color onPrimary;
  final Color secondary;
  final Color onSecondary;
  final Color surface;
  final Color onSurface;
  final Color surfaceVariant;
  final Color onSurfaceVariant;
  final Color outline;
  final Color destructive;
  final Color onDestructive;
  final Color muted;
  final Color onMuted;
  final Color focusRing;

  /// Hover/selected surface tint (shadcn `accent`).
  final Color accent;
  final Color onAccent;

  /// Elevated panel surface (shadcn `card`).
  final Color card;
  final Color onCard;

  /// Floating overlay surface (menus, popovers, tooltips).
  final Color popover;
  final Color onPopover;

  /// Default border color for controls and panels.
  final Color border;

  /// Input field fill color.
  final Color input;

  /// Drives [PortalThemedSurface] rendering (solid vs frosted glass).
  final PortalSurfaceTreatment surfaceTreatment;
  final PortalGlassStyle? glassStyle;

  bool get isGlass => surfaceTreatment == PortalSurfaceTreatment.glass;

  // ── shadcn aliases ──────────────────────────────────────────────────────

  Color get background => surface;
  Color get foreground => onSurface;
  Color get ring => focusRing;
  Color get primaryForeground => onPrimary;
  Color get secondaryForeground => onSecondary;
  Color get destructiveForeground => onDestructive;
  Color get mutedForeground => onMuted;
  Color get accentForeground => onAccent;
  Color get cardForeground => onCard;
  Color get popoverForeground => onPopover;

  // ── border helpers ──────────────────────────────────────────────────────

  /// Standard control border using the semantic [border] token.
  BorderSide borderSide({double? width}) => BorderSide(
        color: border,
        width: width ?? tokens.borderWidth,
      );

  /// Softer divider / inset border.
  BorderSide subtleBorderSide({double? width}) => BorderSide(
        color: border.withValues(alpha: 0.55),
        width: width ?? tokens.borderWidth,
      );

  /// Light border for badges, chips, and disabled controls.
  BorderSide mutedBorderSide({double? width}) => BorderSide(
        color: border.withValues(alpha: 0.35),
        width: width ?? tokens.borderWidth,
      );

  /// Disabled input/control border.
  BorderSide disabledBorderSide({double? width}) => BorderSide(
        color: border.withValues(alpha: 0.4),
        width: width ?? tokens.borderWidth,
      );

  /// Focus ring border (keyboard focus).
  BorderSide focusBorderSide({double? width}) => BorderSide(
        color: ring,
        width: width ?? tokens.borderWidth + 1,
      );

  /// Primary-colored focus for inputs.
  BorderSide inputFocusBorderSide({double? width}) => BorderSide(
        color: primary,
        width: width ?? tokens.borderWidth + 0.5,
      );

  static PortalUiTheme? maybeOf(BuildContext context) {
    return Theme.of(context).extension<PortalUiTheme>();
  }

  static PortalUiTheme of(BuildContext context) {
    final theme = maybeOf(context);
    assert(theme != null, 'PortalUiTheme not found on ThemeData.extensions');
    return theme!;
  }

  @override
  PortalUiTheme copyWith({
    DesignTokens? tokens,
    Color? primary,
    Color? onPrimary,
    Color? secondary,
    Color? onSecondary,
    Color? surface,
    Color? onSurface,
    Color? surfaceVariant,
    Color? onSurfaceVariant,
    Color? outline,
    Color? destructive,
    Color? onDestructive,
    Color? muted,
    Color? onMuted,
    Color? focusRing,
    Color? accent,
    Color? onAccent,
    Color? card,
    Color? onCard,
    Color? popover,
    Color? onPopover,
    Color? border,
    Color? input,
    PortalSurfaceTreatment? surfaceTreatment,
    PortalGlassStyle? glassStyle,
    bool clearGlassStyle = false,
  }) {
    return PortalUiTheme(
      tokens: tokens ?? this.tokens,
      primary: primary ?? this.primary,
      onPrimary: onPrimary ?? this.onPrimary,
      secondary: secondary ?? this.secondary,
      onSecondary: onSecondary ?? this.onSecondary,
      surface: surface ?? this.surface,
      onSurface: onSurface ?? this.onSurface,
      surfaceVariant: surfaceVariant ?? this.surfaceVariant,
      onSurfaceVariant: onSurfaceVariant ?? this.onSurfaceVariant,
      outline: outline ?? this.outline,
      destructive: destructive ?? this.destructive,
      onDestructive: onDestructive ?? this.onDestructive,
      muted: muted ?? this.muted,
      onMuted: onMuted ?? this.onMuted,
      focusRing: focusRing ?? this.focusRing,
      accent: accent ?? this.accent,
      onAccent: onAccent ?? this.onAccent,
      card: card ?? this.card,
      onCard: onCard ?? this.onCard,
      popover: popover ?? this.popover,
      onPopover: onPopover ?? this.onPopover,
      border: border ?? this.border,
      input: input ?? this.input,
      surfaceTreatment: surfaceTreatment ?? this.surfaceTreatment,
      glassStyle: clearGlassStyle ? null : (glassStyle ?? this.glassStyle),
    );
  }

  @override
  ThemeExtension<PortalUiTheme> lerp(
    covariant ThemeExtension<PortalUiTheme>? other,
    double t,
  ) {
    if (other is! PortalUiTheme) return this;
    return PortalUiTheme(
      tokens: t < 0.5 ? tokens : other.tokens,
      primary: Color.lerp(primary, other.primary, t)!,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      onSecondary: Color.lerp(onSecondary, other.onSecondary, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      onSurface: Color.lerp(onSurface, other.onSurface, t)!,
      surfaceVariant: Color.lerp(surfaceVariant, other.surfaceVariant, t)!,
      onSurfaceVariant:
          Color.lerp(onSurfaceVariant, other.onSurfaceVariant, t)!,
      outline: Color.lerp(outline, other.outline, t)!,
      destructive: Color.lerp(destructive, other.destructive, t)!,
      onDestructive: Color.lerp(onDestructive, other.onDestructive, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      onMuted: Color.lerp(onMuted, other.onMuted, t)!,
      focusRing: Color.lerp(focusRing, other.focusRing, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      onAccent: Color.lerp(onAccent, other.onAccent, t)!,
      card: Color.lerp(card, other.card, t)!,
      onCard: Color.lerp(onCard, other.onCard, t)!,
      popover: Color.lerp(popover, other.popover, t)!,
      onPopover: Color.lerp(onPopover, other.onPopover, t)!,
      border: Color.lerp(border, other.border, t)!,
      input: Color.lerp(input, other.input, t)!,
      surfaceTreatment:
          t < 0.5 ? surfaceTreatment : other.surfaceTreatment,
      glassStyle: t < 0.5 ? glassStyle : other.glassStyle,
    );
  }
}
