import 'package:flutter/material.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

/// Determinate or indeterminate linear progress (shadcn Progress).
class PortalProgress extends StatelessWidget {
  const PortalProgress({
    super.key,
    this.value,
    this.minHeight = 6,
  }) : assert(value == null || (value >= 0 && value <= 1));

  /// Null for indeterminate; 0–1 for determinate.
  final double? value;
  final double minHeight;

  @override
  Widget build(BuildContext context) {
    final portal = PortalUiTheme.of(context);
    final t = portal.tokens;

    return ClipRRect(
      borderRadius: BorderRadius.circular(t.radii.full),
      child: LinearProgressIndicator(
        value: value,
        minHeight: minHeight,
        backgroundColor: portal.muted,
        color: portal.primary,
      ),
    );
  }
}
