import 'dart:ui';

import 'package:flutter/material.dart';

import 'portal_surface_treatment.dart';
import 'portal_ui_theme.dart';

/// Theme-aware panel surface — solid, glass (blur + tint), driven by [PortalUiTheme].
///
/// Portal bricks should use this instead of [Material] with a hard-coded
/// [PortalUiTheme.surface] so visual themes (Glass, etc.) apply automatically.
class PortalThemedSurface extends StatelessWidget {
  const PortalThemedSurface({
    required this.child,
    super.key,
    this.padding,
    this.margin,
    this.borderRadius,
    this.borderSide,
    this.color,
    this.onTap,
    this.clipBehavior = Clip.antiAlias,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final BorderSide? borderSide;
  final Color? color;
  final VoidCallback? onTap;
  final Clip clipBehavior;

  @override
  Widget build(BuildContext context) {
    final portal = PortalUiTheme.of(context);
    final t = portal.tokens;
    final radius = borderRadius ?? BorderRadius.circular(t.radii.md);
    final resolvedSide = borderSide ?? portal.borderSide();

    Widget content = child;
    if (padding != null) {
      content = Padding(padding: padding!, child: content);
    }

    Widget surface;
    if (portal.surfaceTreatment == PortalSurfaceTreatment.glass) {
      surface = _GlassSurface(
        portal: portal,
        borderRadius: radius,
        borderSide: resolvedSide,
        color: color,
        clipBehavior: clipBehavior,
        child: content,
      );
    } else {
      surface = Material(
        color: color ?? portal.surface,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: radius, side: resolvedSide),
        clipBehavior: clipBehavior,
        child: content,
      );
    }

    if (onTap != null) {
      surface = InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: surface,
      );
    }

    if (margin != null) {
      surface = Padding(padding: margin!, child: surface);
    }
    return surface;
  }
}

class _GlassSurface extends StatelessWidget {
  const _GlassSurface({
    required this.portal,
    required this.borderRadius,
    required this.borderSide,
    required this.child,
    required this.clipBehavior,
    this.color,
  });

  final PortalUiTheme portal;
  final BorderRadius borderRadius;
  final BorderSide borderSide;
  final Color? color;
  final Widget child;
  final Clip clipBehavior;

  @override
  Widget build(BuildContext context) {
    final glass = portal.glassStyle ?? PortalGlassStyle.defaults;
    final tint = color ?? portal.surface;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: borderRadius,
      clipBehavior: clipBehavior,
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: glass.blurSigma,
          sigmaY: glass.blurSigma,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            border: Border.fromBorderSide(borderSide),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                tint.withValues(alpha: glass.tintAlpha + glass.specularAlpha),
                tint.withValues(alpha: glass.tintAlpha * 0.85),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: portal.primary.withValues(alpha: isDark ? 0.08 : 0.06),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Decorative backdrop so glass surfaces have content to blur against.
class PortalThemeBackdrop extends StatelessWidget {
  const PortalThemeBackdrop({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final portal = PortalUiTheme.of(context);
    if (portal.surfaceTreatment != PortalSurfaceTreatment.glass) {
      return child;
    }

    final cs = Theme.of(context).colorScheme;
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                cs.primary.withValues(alpha: 0.18),
                cs.tertiary.withValues(alpha: 0.14),
                cs.surface.withValues(alpha: 0.95),
              ],
              stops: const [0.0, 0.45, 1.0],
            ),
          ),
        ),
        child,
      ],
    );
  }
}
