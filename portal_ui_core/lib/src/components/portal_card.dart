import 'dart:ui';

import 'package:flutter/material.dart';
import '../theme/portal_component_extensions.dart';
import '../theme/portal_ui_theme.dart';
import '../tokens/design_tokens.dart';
import '../tokens/portal_radii_utils.dart';
import '../motion/portal_hero.dart';
import 'portal_pressable.dart';

enum PortalCardVariant {
  /// The card theme's tone on the page, no border. The default.
  tonal,

  /// `surface` with a hairline outline — for a card that must read as a
  /// boundary on a surface-coloured page.
  outlined,

  /// `surface` lifted by a shadow ([PortalCardElevation.card] unless
  /// [PortalCard.elevation] says otherwise), no border.
  elevated,
  glass,
  hero,
  asymmetric,

  /// The pre-tonal default: `surface` with an outline. Same as [outlined],
  /// which new code should name.
  standard,
}

enum PortalCardElevation { flat, soft, card }

class PortalCard extends StatelessWidget {
  const PortalCard({
    required this.child,
    super.key,
    this.padding,
    this.margin,
    this.onTap,
    this.variant = PortalCardVariant.tonal,
    this.elevation,
    this.clipBehavior = Clip.antiAlias,
    this.heroAccent,
    this.heroOffset = const Offset(12, 12),
    this.gradient,
    this.sheen = false,
    this.backgroundColor,
    this.borderRadius,
    this.heroTag,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final PortalCardVariant variant;

  /// Defaults to [PortalCardTheme.elevation], then flat.
  final PortalCardElevation? elevation;
  final Clip clipBehavior;

  /// Decorative widget behind content (hero variant), e.g. illustration.
  final Widget? heroAccent;
  final Offset heroOffset;

  final Gradient? gradient;

  /// Lays [PortalGradients.surfaceSheen] over the surface colour, behind the
  /// content — a faint top-left light that lifts a card off a flat page.
  final bool sheen;

  final Color? backgroundColor;
  final BorderRadius? borderRadius;

  /// Wraps the card in a [PortalHero] with this tag, so it flies to a
  /// matching hero on the next route keeping its corners on the way.
  final Object? heroTag;

  @override
  Widget build(BuildContext context) {
    final portal = PortalUiTheme.of(context);
    final t = portal.tokens;
    final brightness = Theme.of(context).brightness;
    final skin = PortalCardTheme.of(context);
    final radius =
        borderRadius ?? skin.borderRadius ?? _borderRadius(t.radii, variant);
    final fillColor = backgroundColor ?? skin.backgroundColor;
    final borderSide = skin.border ??
        BorderSide(
          color: portal.outline.withValues(
              alpha: variant == PortalCardVariant.glass ? 0.2 : 0.65),
          width: t.borderWidth,
        );
    final level = elevation ?? skin.elevation ?? PortalCardElevation.flat;
    final shadows = _shadows(
      t.elevation,
      variant == PortalCardVariant.elevated && level == PortalCardElevation.flat
          ? PortalCardElevation.card
          : level,
      brightness,
    );

    final inner = Padding(
      padding: padding ?? skin.padding ?? EdgeInsets.all(t.spacing.lg),
      child: child,
    );

    Widget content = inner;
    if (variant == PortalCardVariant.hero && heroAccent != null) {
      content = Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -heroOffset.dx,
            bottom: -heroOffset.dy,
            child: heroAccent!,
          ),
          inner,
        ],
      );
    }

    if (sheen) {
      content = DecoratedBox(
        decoration: BoxDecoration(
          gradient: t.gradients.surfaceSheen(Theme.of(context).colorScheme),
          borderRadius: radius,
        ),
        child: content,
      );
    }

    Widget decorated;
    switch (variant) {
      case PortalCardVariant.glass:
        decorated = ClipRRect(
          borderRadius: radius,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: _surfaceBox(
              radius: radius,
              color: (fillColor ?? portal.surface).withValues(alpha: 0.4),
              border: borderSide,
              shadows: shadows,
              gradient: gradient,
              // Ink hosts (ListTile, InkWell, ...) need a real Material
              // ancestor above the BackdropFilter, or splashes paint at a
              // desynced offset on scroll/rebuild -- matches the Material
              // wrap every other variant already has.
              child: Material(
                type: MaterialType.transparency,
                child: content,
              ),
            ),
          ),
        );
      case PortalCardVariant.hero:
        decorated = ClipRRect(
          borderRadius: radius,
          child: _surfaceBox(
            radius: radius,
            color: fillColor ?? portal.surface,
            border: borderSide,
            shadows: shadows,
            gradient: gradient,
            child: content,
          ),
        );
      case PortalCardVariant.asymmetric:
        final shape = t.radii.continuousBorder(
          borderRadius: radius,
          side: borderSide,
        );
        decorated = Material(
          color: gradient == null
              ? (fillColor ?? portal.surface)
              : Colors.transparent,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: shape,
          clipBehavior: clipBehavior,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: gradient,
              boxShadow: shadows,
              borderRadius: radius,
            ),
            child: content,
          ),
        );
      case PortalCardVariant.tonal:
      case PortalCardVariant.outlined:
      case PortalCardVariant.elevated:
      case PortalCardVariant.standard:
        final tonal = variant == PortalCardVariant.tonal;
        final side = skin.border ??
            (tonal || variant == PortalCardVariant.elevated
                ? BorderSide.none
                : borderSide);
        final shape = t.expressiveCorners
            ? t.radii.continuousBorder(borderRadius: radius, side: side)
            : t.radii.roundedBorder(borderRadius: radius, side: side);
        final theme = Theme.of(context);
        final fill = fillColor ??
            (tonal
                ? theme.cardTheme.color ?? theme.colorScheme.surfaceContainerLow
                : portal.surface);
        // Shadow outside the Material: its clip would swallow one painted
        // inside, which is why `elevated` never lifted before.
        decorated = DecoratedBox(
          decoration: ShapeDecoration(shape: shape, shadows: shadows),
          child: Material(
            color: gradient == null ? fill : Colors.transparent,
            elevation: 0,
            shadowColor: Colors.transparent,
            shape: shape,
            clipBehavior: clipBehavior,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: radius,
              ),
              child: content,
            ),
          ),
        );
    }

    // The whole surface presses, shadow and border included; the scale is the
    // feedback, so no ripple.
    if (onTap != null) {
      decorated = PortalPressable(
        onTap: onTap,
        borderRadius: radius,
        child: decorated,
      );
    }
    if (heroTag != null) {
      decorated =
          PortalHero(tag: heroTag!, borderRadius: radius, child: decorated);
    }
    if (margin != null) {
      return Padding(padding: margin!, child: decorated);
    }
    return decorated;
  }

  BorderRadius _borderRadius(PortalRadii radii, PortalCardVariant variant) {
    if (borderRadius != null) return borderRadius!;
    switch (variant) {
      case PortalCardVariant.asymmetric:
        return radii.asymmetric();
      case PortalCardVariant.hero:
        return radii.circular(radii.xl);
      default:
        return radii.circular(radii.lg);
    }
  }

  List<BoxShadow> _shadows(
    PortalElevation elevationTokens,
    PortalCardElevation level,
    Brightness brightness,
  ) {
    switch (level) {
      case PortalCardElevation.soft:
        return elevationTokens.soft(brightness);
      case PortalCardElevation.card:
        return elevationTokens.card(brightness);
      case PortalCardElevation.flat:
        return const [];
    }
  }

  Widget _surfaceBox({
    required BorderRadius radius,
    required Color color,
    required BorderSide border,
    required List<BoxShadow> shadows,
    required Widget child,
    Gradient? gradient,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: gradient == null ? color : null,
        gradient: gradient,
        borderRadius: radius,
        border: Border.fromBorderSide(border),
        boxShadow: shadows,
      ),
      child: child,
    );
  }
}
