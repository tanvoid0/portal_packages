import 'package:flutter/material.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

class PortalSelectItem<T> {
  const PortalSelectItem({required this.value, required this.label});

  final T value;
  final String label;
}

/// Dropdown styled with [PortalUiTheme] (shadcn Select).
class PortalSelect<T> extends StatelessWidget {
  const PortalSelect({
    required this.items,
    required this.value,
    required this.onChanged,
    super.key,
    this.label,
    this.hint,
    this.enabled = true,
  });

  final List<PortalSelectItem<T>> items;
  final T? value;
  final ValueChanged<T?>? onChanged;
  final String? label;
  final String? hint;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final portal = PortalUiTheme.of(context);
    final t = portal.tokens;
    final baseBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(t.radii.md),
      borderSide: portal.borderSide(),
    );

    final useFormShell = label != null;

    final select = InputDecorator(
      decoration: InputDecoration(
        isDense: true,
        labelText: useFormShell ? null : label,
        hintText: hint,
        filled: true,
        fillColor: portal.input,
        contentPadding: EdgeInsets.symmetric(
          horizontal: t.spacing.lg,
          vertical: t.spacing.md,
        ),
        border: baseBorder,
        enabledBorder: baseBorder,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(t.radii.md),
          borderSide: portal.inputFocusBorderSide(),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(t.radii.md),
          borderSide: portal.disabledBorderSide(),
        ),
        labelStyle: TextStyle(color: portal.onSurfaceVariant),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          isExpanded: true,
          value: value,
          hint: hint == null
              ? null
              : Text(hint!, style: TextStyle(color: portal.onSurfaceVariant)),
          items: items
              .map(
                (e) => DropdownMenuItem<T>(
                  value: e.value,
                  child: Text(e.label),
                ),
              )
              .toList(),
          onChanged: enabled ? onChanged : null,
          borderRadius: BorderRadius.circular(t.radii.md),
          dropdownColor: portal.popover,
          iconEnabledColor: portal.onSurfaceVariant,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );

    if (!useFormShell) return select;
    return PortalFormField(label: label, child: select);
  }
}
