import 'package:flutter/material.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

enum PortalBadgeVariant { neutral, primary, destructive }

class PortalBadge extends StatelessWidget {
  const PortalBadge({
    required this.label,
    super.key,
    this.variant = PortalBadgeVariant.neutral,
  });

  final String label;
  final PortalBadgeVariant variant;

  @override
  Widget build(BuildContext context) {
    final portal = PortalUiTheme.of(context);
    final t = portal.tokens;
    final (bg, fg) = _colors(portal);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(t.radii.full),
        border: Border.fromBorderSide(portal.mutedBorderSide()),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: t.spacing.md, vertical: t.spacing.xs),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: fg,
                fontWeight: FontWeight.w600,
                fontSize: t.typeScale.xs,
              ),
        ),
      ),
    );
  }

  (Color, Color) _colors(PortalUiTheme portal) {
    switch (variant) {
      case PortalBadgeVariant.neutral:
        return (portal.muted, portal.onMuted);
      case PortalBadgeVariant.primary:
        return (portal.primary.withValues(alpha: 0.12), portal.primary);
      case PortalBadgeVariant.destructive:
        return (portal.destructive.withValues(alpha: 0.12), portal.destructive);
    }
  }
}
