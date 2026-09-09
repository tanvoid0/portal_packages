import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../theme/portal_ui_theme.dart';

/// Themed shimmer sweep for loading placeholders.
///
/// Respects [MediaQuery.disableAnimationsOf]. Colors come from [PortalUiTheme].
class PortalShimmer extends StatelessWidget {
  const PortalShimmer({
    required this.child,
    super.key,
    this.baseColor,
    this.highlightColor,
    this.period,
  });

  final Widget child;
  final Color? baseColor;
  final Color? highlightColor;

  /// Overrides the default 1200 ms shimmer cycle.
  final Duration? period;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) {
      return child;
    }

    final portal = PortalUiTheme.of(context);
    final base = baseColor ?? portal.muted;
    final highlight =
        highlightColor ?? portal.surfaceVariant.withValues(alpha: 0.92);

    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: highlight,
      period: period ?? const Duration(milliseconds: 1200),
      child: child,
    );
  }
}
