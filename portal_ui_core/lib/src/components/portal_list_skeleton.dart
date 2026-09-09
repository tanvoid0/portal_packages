import 'package:flutter/material.dart';

import '../theme/portal_ui_theme.dart';
import 'portal_skeleton.dart';

/// Vertical run of [PortalSkeleton] blocks, shaped like the list it stands in
/// for.
///
/// Use it while a list loads. A spinner tells the user to wait; this tells
/// them what is arriving.
class PortalListSkeleton extends StatelessWidget {
  const PortalListSkeleton({
    super.key,
    this.itemCount = 6,
    this.itemHeight = 72,
    this.padding,
    this.shrinkWrap = false,
    this.physics,
  });

  final int itemCount;
  final double itemHeight;
  final EdgeInsetsGeometry? padding;

  /// Set when the skeleton sits inside another scrollable.
  final bool shrinkWrap;
  final ScrollPhysics? physics;

  @override
  Widget build(BuildContext context) {
    final tokens = PortalUiTheme.of(context).tokens;

    return ListView.separated(
      padding:
          padding ?? EdgeInsets.symmetric(vertical: tokens.spacing.sm),
      shrinkWrap: shrinkWrap,
      physics: physics ?? (shrinkWrap
          ? const NeverScrollableScrollPhysics()
          : null),
      itemCount: itemCount,
      separatorBuilder: (_, __) => SizedBox(height: tokens.spacing.md),
      itemBuilder: (_, __) => PortalSkeleton(
        height: itemHeight,
        borderRadius: BorderRadius.circular(tokens.radii.md),
      ),
    );
  }
}
