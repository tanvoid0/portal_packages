import 'package:flutter/material.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

/// Checkbox with label, using [PortalUiTheme] (shadcn Checkbox).
class PortalCheckbox extends StatelessWidget {
  const PortalCheckbox({
    required this.label,
    required this.value,
    required this.onChanged,
    super.key,
    this.subtitle,
    this.tristate = false,
  });

  final String label;
  final bool? value;
  final ValueChanged<bool?>? onChanged;
  final String? subtitle;
  final bool tristate;

  @override
  Widget build(BuildContext context) {
    final portal = PortalUiTheme.of(context);
    final t = portal.tokens;

    return InkWell(
      onTap: onChanged == null
          ? null
          : () {
              if (tristate) {
                if (value == null) {
                  onChanged!(true);
                } else if (value == true) {
                  onChanged!(false);
                } else {
                  onChanged!(null);
                }
              } else {
                onChanged!(!(value ?? false));
              }
            },
      borderRadius: BorderRadius.circular(t.radii.sm),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: t.spacing.xs),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: value,
                tristate: tristate,
                onChanged: onChanged,
                activeColor: portal.primary,
                checkColor: portal.onPrimary,
                side: BorderSide(color: portal.outline, width: t.borderWidth),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
            ),
            SizedBox(width: t.spacing.sm),
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
