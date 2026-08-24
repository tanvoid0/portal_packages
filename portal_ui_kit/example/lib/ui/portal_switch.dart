import 'package:flutter/material.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

/// Switch with label (shadcn Switch).
class PortalSwitch extends StatelessWidget {
  const PortalSwitch({
    required this.label,
    required this.value,
    required this.onChanged,
    super.key,
    this.subtitle,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final portal = PortalUiTheme.of(context);
    final t = portal.tokens;

    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(t.radii.sm),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: t.spacing.xs),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: portal.onSurface,
                        ),
                  ),
                  if (subtitle != null) ...[
                    SizedBox(height: t.spacing.xs),
                    Text(
                      subtitle!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: portal.onSurfaceVariant,
                          ),
                    ),
                  ],
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeThumbColor: portal.onPrimary,
              activeTrackColor: portal.primary,
              inactiveThumbColor: portal.onSurfaceVariant,
              inactiveTrackColor: portal.muted,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ],
        ),
      ),
    );
  }
}
