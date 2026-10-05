import 'package:flutter/material.dart';

import '../theme/portal_form_field.dart';
import '../theme/portal_ui_theme.dart';

/// One choice of a [PortalSelect]: [label] is what is shown and announced,
/// [icon] a leading glyph.
@immutable
class PortalSelectItem<T> {
  const PortalSelectItem({required this.value, required this.label, this.icon});

  final T value;
  final String label;
  final IconData? icon;
}

/// The one dropdown: label above, [hint] until something is chosen,
/// [helper] and [errorText] below, on [PortalFormField] like
/// `PortalTextField`. The control takes its fill and borders from the app's
/// `InputDecorationTheme` and is at least `minTapTarget` tall.
///
/// A null [onChanged] disables it. The label names the control for a screen
/// reader, which then reads the chosen item. For a choice of two or three,
/// `PortalSegmentedTabs` shows them all at once and is quicker to use.
class PortalSelect<T> extends StatelessWidget {
  const PortalSelect({
    super.key,
    required this.items,
    required this.onChanged,
    this.value,
    this.label,
    this.hint,
    this.helper,
    this.errorText,
    this.required = false,
  });

  final List<PortalSelectItem<T>> items;

  /// Null disables the field.
  final ValueChanged<T?>? onChanged;

  /// The chosen item's value; null shows [hint].
  final T? value;
  final String? label;
  final String? hint;
  final String? helper;

  /// A message the caller already has; wins over [helper].
  final String? errorText;

  /// Draws the `*` beside the label.
  final bool required;

  @override
  Widget build(BuildContext context) {
    final portal = PortalUiTheme.of(context);
    final tokens = portal.tokens;
    final enabled = onChanged != null;
    final cs = Theme.of(context).colorScheme;
    final ink = enabled ? cs.onSurface : cs.onSurface.withValues(alpha: 0.38);

    return PortalFormField(
      label: label,
      description: helper,
      error: errorText,
      required: required,
      child: Semantics(
        label: label,
        child: DropdownButtonFormField<T>(
          initialValue: value,
          // The field keeps its own copy of the value; a new one rebuilds it.
          key: ValueKey(value),
          isExpanded: true,
          onChanged: onChanged,
          hint: hint == null
              ? null
              : Text(hint!,
                  style: tokens.textStyles.body
                      .copyWith(color: cs.onSurfaceVariant)),
          style: tokens.textStyles.body.copyWith(color: ink),
          decoration: InputDecoration(
            constraints: BoxConstraints(minHeight: tokens.minTapTarget),
          ).applyDefaults(Theme.of(context).inputDecorationTheme),
          items: [
            for (final item in items)
              DropdownMenuItem<T>(
                value: item.value,
                child: Row(children: [
                  if (item.icon != null) ...[
                    Icon(item.icon, size: tokens.iconSizes.md, color: ink),
                    SizedBox(width: tokens.spacing.sm),
                  ],
                  Flexible(
                    child: Text(item.label, overflow: TextOverflow.ellipsis),
                  ),
                ]),
              ),
          ],
        ),
      ),
    );
  }
}
