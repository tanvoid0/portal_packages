import 'dart:ui';

import 'package:flutter/material.dart';
import '../theme/portal_ui_theme.dart';
import '../tokens/design_tokens.dart';
import '../tokens/portal_radii_utils.dart';

enum PortalCardVariant { standard, glass, hero, asymmetric }

enum PortalCardElevation { flat, soft, card }

class PortalCard extends StatelessWidget {
  const PortalCard({
    required this.child,
    super.key,
    this.padding,
    this.margin,
    this.onTap,
    this.variant = PortalCardVariant.standard,
    this.elevation = PortalCardElevation.flat,
    this.clipBehavior = Clip.antiAlias,
    this.heroAccent,
    this.heroOffset = const Offset(12, 12),
    this.gradient,
    this.backgroundColor,
    this.borderRadius,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final PortalCardVariant variant;
  final PortalCardElevation elevation;
  final Clip clipBehavior;

  /// Decorative widget behind content (hero variant), e.g. illustration.
  final Widget? heroAccent;
  final Offset heroOffset;

  final Gradient? gradient;
  final Color? backgroundColor;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final portal = PortalUiTheme.of(context);
    final t = portal.tokens;
    final brightness = Theme.of(context).brightness;
    final radius = borderRadius ?? _borderRadius(t.radii, variant);
    final borderSide = BorderSide(
      color: portal.outline.withValues(alpha: variant == PortalCardVariant.glass ? 0.2 : 0.65),
      width: t.borderWidth,
    );
    final shadows = _shadows(t.elevation, elevation, brightness);

    final inner = Padding(
      padding: padding ?? EdgeInsets.all(t.spacing.lg),
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

    Widget decorated;
    switch (variant) {
      case PortalCardVariant.glass:
        decorated = ClipRRect(
          borderRadius: radius,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: _surfaceBox(
              radius: radius,
              color: (backgroundColor ?? portal.surface).withValues(alpha: 0.4),
              border: borderSide,
              shadows: shadows,
              gradient: gradient,
              child: _maybeInk(content, onTap, radius),
            ),
          ),
        );
      case PortalCardVariant.hero:
        decorated = ClipRRect(
          borderRadius: radius,
          child: _surfaceBox(
            radius: radius,
            color: backgroundColor ?? portal.surface,
            border: borderSide,
            shadows: shadows,
            gradient: gradient,
            child: _maybeInk(content, onTap, radius),
          ),
        );
      case PortalCardVariant.asymmetric:
        final shape = t.radii.continuousBorder(
          borderRadius: radius,
          side: borderSide,
        );
        decorated = Material(
          color: gradient == null ? (backgroundColor ?? portal.surface) : Colors.transparent,
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
            child: _maybeInk(content, onTap, radius),
          ),
        );
      case PortalCardVariant.standard:
        final shape = portal.tokens.expressiveCorners
            ? t.radii.continuousBorder(borderRadius: radius, side: borderSide)
            : RoundedRectangleBorder(borderRadius: radius, side: borderSide);
        decorated = Material(
          color: gradient == null ? (backgroundColor ?? portal.surface) : Colors.transparent,
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
            child: _maybeInk(content, onTap, radius),
          ),
        );
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

  Widget _maybeInk(Widget child, VoidCallback? onTap, BorderRadius radius) {
    if (onTap == null) return child;
    return InkWell(onTap: onTap, borderRadius: radius, child: child);
  }
}
