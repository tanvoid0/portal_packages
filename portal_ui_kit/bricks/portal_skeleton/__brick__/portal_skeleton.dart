import 'package:flutter/material.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

/// Shimmer placeholder block (shadcn Skeleton).
class PortalSkeleton extends StatelessWidget {
  const PortalSkeleton({
    super.key,
    this.width,
    this.height = 14,
    this.borderRadius,
  });

  final double? width;
  final double height;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final portal = PortalUiTheme.of(context);
    final t = portal.tokens;
    final radius = borderRadius ?? BorderRadius.circular(t.radii.sm);

    return PortalShimmer(
      child: ClipRRect(
        borderRadius: radius,
        child: Container(
          width: width,
          height: height,
          color: portal.muted,
        ),
      ),
    );
  }
}
