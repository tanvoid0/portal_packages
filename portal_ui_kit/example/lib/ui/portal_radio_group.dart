import 'package:flutter/material.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

/// One option in a radio group — use the same [groupValue] / [onChanged] for each (shadcn Radio Group).
class PortalRadioOption<T> extends StatelessWidget {
  const PortalRadioOption({
    required this.value,
    required this.groupValue,
    required this.onChanged,
    required this.label,
    super.key,
    this.subtitle,
  });

  final T value;
  final T? groupValue;
  final ValueChanged<T?>? onChanged;
  final String label;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final portal = PortalUiTheme.of(context);
    final t = portal.tokens;

    return InkWell(
      onTap: onChanged == null ? null : () => onChanged!(value),
      borderRadius: BorderRadius.circular(t.radii.sm),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: t.spacing.xs),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Radio<T>(
              value: value,
              // ignore: deprecated_member_use
              groupValue: groupValue,
              // ignore: deprecated_member_use
              onChanged: onChanged,
              activeColor: portal.primary,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
            SizedBox(width: t.spacing.xs),
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
          ],
        ),
      ),
    );
  }
}
