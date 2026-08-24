import 'package:flutter/material.dart';
import '../theme/portal_ui_theme.dart';

/// Pulsing placeholder block (shadcn Skeleton).
class PortalSkeleton extends StatefulWidget {
  const PortalSkeleton({
    super.key,
    this.width,
    this.height = 14,
    this.borderRadius,
    this.shape = BoxShape.rectangle,
  });

  final double? width;
  final double height;
  final BorderRadius? borderRadius;
  final BoxShape shape;

  @override
  State<PortalSkeleton> createState() => _PortalSkeletonState();
}

class _PortalSkeletonState extends State<PortalSkeleton> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final portal = PortalUiTheme.of(context);
    final t = portal.tokens;
    final radius = widget.shape == BoxShape.circle 
        ? null 
        : widget.borderRadius ?? BorderRadius.circular(t.radii.sm);

    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final a = Curves.easeInOut.transform(_c.value);
        final base = portal.muted;
        final hi = portal.surfaceVariant.withValues(alpha: 0.9);
        final c = Color.lerp(base, hi, a)!;
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: c,
            borderRadius: radius,
            shape: widget.shape,
          ),
        );
      },
    );
  }
}
