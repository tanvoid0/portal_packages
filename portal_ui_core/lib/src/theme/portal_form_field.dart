import 'package:flutter/material.dart';

import 'portal_ui_theme.dart';

/// Composable form field shell — label, control, description, and error message.
///
/// Mirrors shadcn's `FormItem` / `FormLabel` / `FormDescription` / `FormMessage`.
class PortalFormField extends StatelessWidget {
  const PortalFormField({
    required this.child,
    super.key,
    this.label,
    this.description,
    this.error,
    this.required = false,
    this.excludeLabelSemantics = false,
    this.stretch = false,
  });

  final Widget child;
  final String? label;
  final String? description;
  final String? error;
  final bool required;

  /// For a [child] that names itself with [label]: the visible label is then
  /// not read a second time.
  final bool excludeLabelSemantics;

  /// Gives [child] the full width, for a control that is not width-greedy
  /// itself (a stepper, a choice grid) and names itself, so pair it with
  /// [excludeLabelSemantics]. [description] is the note under it.
  final bool stretch;

  @override
  Widget build(BuildContext context) {
    final portal = PortalUiTheme.of(context);
    final t = portal.tokens;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment:
          stretch ? CrossAxisAlignment.stretch : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          ExcludeSemantics(
            excluding: excludeLabelSemantics,
            child: Row(
              children: [
                // Flexible: a long label wraps instead of overflowing.
                Flexible(
                  child: Text(
                    label!,
                    style: textTheme.labelLarge?.copyWith(
                      color: portal.foreground,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (required)
                  Text(
                    ' *',
                    style: textTheme.labelLarge
                        ?.copyWith(color: portal.destructive),
                  ),
              ],
            ),
          ),
          SizedBox(height: t.spacing.sm),
        ],
        child,
        if (description != null && error == null) ...[
          SizedBox(height: t.spacing.xs),
          Text(
            description!,
            style: textTheme.bodySmall?.copyWith(color: portal.mutedForeground),
          ),
        ],
        if (error != null) ...[
          SizedBox(height: t.spacing.xs),
          Text(
            error!,
            style: textTheme.bodySmall?.copyWith(color: portal.destructive),
          ),
        ],
      ],
    );
  }
}
