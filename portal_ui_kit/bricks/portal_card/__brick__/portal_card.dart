import 'package:flutter/material.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

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

    final effectiveVariant =
        variant == PortalCardVariant.standard && portal.isGlass
            ? PortalCardVariant.glass
            : variant;

    final canUseThemedSurface = effectiveVariant == PortalCardVariant.glass ||
        (effectiveVariant == PortalCardVariant.standard &&
            gradient == null &&
            shadows.isEmpty);

    if (canUseThemedSurface) {
      return PortalThemedSurface(
        margin: margin,
        padding: padding,
        borderRadius: radius,
        color: backgroundColor ?? portal.card,
        onTap: onTap,
        clipBehavior: clipBehavior,
        child: content,
      );
    }

    Widget decorated;
    switch (effectiveVariant) {
      case PortalCardVariant.hero:
        decorated = ClipRRect(
          borderRadius: radius,
          child: _surfaceBox(
            radius: radius,
            color: backgroundColor ?? portal.card,
            border: portal.borderSide(),
            shadows: shadows,
            gradient: gradient,
            child: _maybeInk(content, onTap, radius),
          ),
        );
      case PortalCardVariant.asymmetric:
        final shape = t.radii.continuousBorder(
          borderRadius: radius,
          side: portal.borderSide(),
        );
        decorated = Material(
          color: gradient == null ? (backgroundColor ?? portal.card) : Colors.transparent,
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
      case PortalCardVariant.glass:
        final shape = portal.tokens.expressiveCorners
            ? t.radii.continuousBorder(
                borderRadius: radius,
                side: portal.borderSide(),
              )
            : RoundedRectangleBorder(
                borderRadius: radius,
                side: portal.borderSide(),
              );
        decorated = Material(
          color: gradient == null ? (backgroundColor ?? portal.card) : Colors.transparent,
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
