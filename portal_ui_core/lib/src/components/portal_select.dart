import 'package:flutter/material.dart';

import '../theme/portal_component_extensions.dart';
import '../theme/portal_form_field.dart';
import '../theme/portal_ui_theme.dart';
import 'portal_pressable.dart';
import 'portal_prompt.dart';
import '../theme/portal_theme_helpers.dart';

// What PortalSelect.picker is built from: the value is already a string and
// the caller opens its own picker.
typedef _Picker = ({
  String? shown,
  VoidCallback? onTap,
  IconData icon,
  String? warning,
  String? readOnlyReason,
});

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
///
/// [PortalSelect.picker] is the same frame as a button: it shows a string and
/// the caller opens its own picker (a sheet, a date dialog) on tap.
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
  }) : _picker = null;

  /// A tap-to-open field. [value] is preformatted ('Monzo, current',
  /// '28 Sept 2026'); null shows [hint]. A null [onTap] disables it, dimmed.
  /// [icon] is the end glyph (the calendar, for dates). [warning] sits under
  /// the field and leaves it valid; [errorText] wins over it, then [helper],
  /// then [readOnlyReason]. [readOnlyReason] is a value set elsewhere: muted,
  /// a lock for [icon], no tap, still read, and the reason under it.
  /// Read as one button, '<label>, <value>'. Items and [onChanged] do not
  /// apply, and nothing ties [T] here.
  PortalSelect.picker({
    super.key,
    required VoidCallback? onTap,
    String? value,
    this.label,
    this.hint,
    this.helper,
    this.errorText,
    this.required = false,
    IconData icon = Icons.expand_more_rounded,
    String? warning,
    String? readOnlyReason,
  })  : items = [],
        onChanged = null,
        value = null,
        _picker = (
          shown: value,
          onTap: onTap,
          icon: icon,
          warning: warning,
          readOnlyReason: readOnlyReason,
        );

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
  final _Picker? _picker;

  Widget _buildPicker(BuildContext context, _Picker p) {
    final portal = PortalUiTheme.of(context);
    final tokens = portal.tokens;
    final cs = Theme.of(context).colorScheme;
    final enabled = p.onTap != null;
    final readOnly = p.readOnlyReason != null;
    final off = cs.onSurface.withValues(alpha: tokens.motion.disabledOpacity);
    final ink = readOnly
        ? cs.onSurfaceVariant
        : enabled
            ? cs.onSurface
            : off;
    final spoken = [label, p.shown ?? hint].whereType<String>().join(', ');
    // The line under the field is one slot: error > warning > helper > reason.
    final warning = errorText == null ? p.warning : null;

    final frame = InputDecorator(
      isEmpty: p.shown == null,
      textAlignVertical: TextAlignVertical.center,
      decoration: InputDecoration(
        fillColor: _fill(context),
        enabled: enabled || readOnly,
        hintText: hint,
        hintStyle:
            tokens.textStyles.body.copyWith(color: cs.onSurfaceVariant),
        // The error edge; the words are the form field's line under it.
        error: errorText == null ? null : const SizedBox.shrink(),
        constraints: BoxConstraints(minHeight: tokens.minTapTarget),
        suffixIcon: Icon(
          readOnly ? Icons.lock_outline_rounded : p.icon,
          size: tokens.iconSizes.md,
        ),
        suffixIconColor: enabled || readOnly ? cs.onSurfaceVariant : off,
      ).applyDefaults(Theme.of(context).inputDecorationTheme),
      child: Text(
        p.shown ?? '',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: tokens.textStyles.body.copyWith(color: ink),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        PortalFormField(
          label: label,
          description: warning == null ? helper ?? p.readOnlyReason : null,
          error: errorText,
          required: required,
          excludeLabelSemantics: true,
          child: readOnly
              ? Semantics(
                  container: true,
                  readOnly: true,
                  label: spoken,
                  child: ExcludeSemantics(child: frame),
                )
              : PortalPressable(
                  onTap: p.onTap,
                  enabled: enabled,
                  button: true,
                  borderRadius: PortalTextFieldTheme.of(context).borderRadius ??
                      BorderRadius.circular(tokens.radii.md),
                  child: Semantics(
                    label: spoken,
                    excludeSemantics: true,
                    child: frame,
                  ),
                ),
        ),
        if (warning != null) ...[
          SizedBox(height: tokens.spacing.xs),
          PortalPrompt(
            message: warning,
            sentiment: PortalSentiment.warning,
            size: PortalPromptSize.inline,
          ),
        ],
      ],
    );
  }

  /// The theme's field fill, stepped off the page it sits on.
  static Color? _fill(BuildContext context) {
    final fill = Theme.of(context).inputDecorationTheme.fillColor;
    return fill == null ? null : portalOffPage(context, fill);
  }

  @override
  Widget build(BuildContext context) {
    if (_picker case final p?) return _buildPicker(context, p);
    final portal = PortalUiTheme.of(context);
    final tokens = portal.tokens;
    final enabled = onChanged != null;
    final cs = Theme.of(context).colorScheme;
    final ink =
        enabled ? cs.onSurface : cs.onSurface.withValues(alpha: tokens.motion.disabledOpacity);

    return PortalFormField(
      label: label,
      description: helper,
      error: errorText,
      required: required,
      excludeLabelSemantics: true,
      child: Semantics(
        label: label,
        child: DropdownButtonFormField<T>(
          // The field asserts on a value that is not exactly one item; it takes
          // a changed one itself, so no key (a key rebuilt it and dropped focus).
          initialValue:
              items.where((i) => i.value == value).length == 1 ? value : null,
          isExpanded: true,
          onChanged: onChanged,
          hint: hint == null
              ? null
              : Text(hint!,
                  style: tokens.textStyles.body
                      .copyWith(color: cs.onSurfaceVariant)),
          // DropdownButton replaces the ambient style, so merge into it: the
          // body role names no family, the ambient style carries it.
          style: DefaultTextStyle.of(context)
              .style
              .merge(tokens.textStyles.body)
              .copyWith(color: ink),
          decoration: InputDecoration(
            fillColor: _fill(context),
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
