import 'package:flutter/material.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

enum PortalAlertVariant { neutral, primary, destructive }

/// Inline alert / callout (shadcn Alert).
class PortalAlert extends StatelessWidget {
  const PortalAlert({
    required this.title,
    super.key,
    this.description,
    this.variant = PortalAlertVariant.neutral,
    this.icon,
    this.actions,
  });

  final String title;
  final String? description;
  final PortalAlertVariant variant;
  final IconData? icon;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    final portal = PortalUiTheme.of(context);
    final t = portal.tokens;
    final (bg, fg, border) = _palette(portal);

    final effectiveIcon = icon ?? _defaultIcon();

    return DecoratedBox(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(t.radii.md),
        border: Border.all(color: border, width: t.borderWidth),
      ),
      child: Padding(
        padding: EdgeInsets.all(t.spacing.lg),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(effectiveIcon, size: 20, color: fg),
            SizedBox(width: t.spacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: portal.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  if (description != null) ...[
                    SizedBox(height: t.spacing.xs),
                    Text(
                      description!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: portal.onSurfaceVariant,
                          ),
                    ),
                  ],
                  if (actions != null && actions!.isNotEmpty) ...[
                    SizedBox(height: t.spacing.md),
                    Wrap(spacing: t.spacing.sm, runSpacing: t.spacing.sm, children: actions!),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _defaultIcon() {
    switch (variant) {
      case PortalAlertVariant.neutral:
        return Icons.info_outline;
      case PortalAlertVariant.primary:
        return Icons.notifications_none_outlined;
      case PortalAlertVariant.destructive:
        return Icons.error_outline;
    }
  }

  (Color, Color, Color) _palette(PortalUiTheme portal) {
    switch (variant) {
      case PortalAlertVariant.neutral:
        return (
          portal.muted.withValues(alpha: 0.45),
          portal.onMuted,
          portal.subtleBorderSide().color,
        );
      case PortalAlertVariant.primary:
        return (
          portal.primary.withValues(alpha: 0.08),
          portal.primary,
          portal.primary.withValues(alpha: 0.25),
        );
      case PortalAlertVariant.destructive:
        return (
          portal.destructive.withValues(alpha: 0.1),
          portal.destructive,
          portal.destructive.withValues(alpha: 0.35),
        );
    }
  }
}
