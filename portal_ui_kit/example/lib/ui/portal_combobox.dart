import 'package:flutter/material.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

class PortalComboboxItem<T extends Object> {
  const PortalComboboxItem({required this.value, required this.label});

  final T value;
  final String label;
}

/// Searchable dropdown with filter-as-you-type (shadcn Combobox).
class PortalCombobox<T extends Object> extends StatelessWidget {
  const PortalCombobox({
    required this.items,
    required this.onSelected,
    super.key,
    this.label,
    this.hint,
    this.initialValue,
  });

  final List<PortalComboboxItem<T>> items;
  final ValueChanged<T> onSelected;
  final String? label;
  final String? hint;
  final String? initialValue;

  @override
  Widget build(BuildContext context) {
    final portal = PortalUiTheme.of(context);
    final t = portal.tokens;

    final useFormShell = label != null;

    final field = RawAutocomplete<PortalComboboxItem<T>>(
      initialValue: initialValue == null ? null : TextEditingValue(text: initialValue!),
      optionsBuilder: (value) {
        final q = value.text.trim().toLowerCase();
        if (q.isEmpty) return items;
        return items.where((e) => e.label.toLowerCase().contains(q));
      },
      displayStringForOption: (item) => item.label,
      onSelected: (item) => onSelected(item.value),
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        return TextField(
          controller: controller,
          focusNode: focusNode,
          onSubmitted: (_) => onFieldSubmitted(),
          style: Theme.of(context).textTheme.bodyMedium,
          cursorColor: portal.primary,
          decoration: portalInputDecoration(
            context,
            label: useFormShell ? null : label,
            hint: hint ?? 'Search…',
          ),
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            color: Colors.transparent,
            child: PortalThemedSurface(
              color: portal.popover,
              borderRadius: BorderRadius.circular(t.radii.md),
              margin: EdgeInsets.only(top: t.spacing.xs),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 240, minWidth: 200),
                child: ListView.builder(
                  padding: EdgeInsets.symmetric(vertical: t.spacing.xs),
                  shrinkWrap: true,
                  itemCount: options.length,
                  itemBuilder: (context, index) {
                    final item = options.elementAt(index);
                    return ListTile(
                      dense: true,
                      title: Text(item.label),
                      onTap: () => onSelected(item),
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );

    if (!useFormShell) return field;
    return PortalFormField(label: label, child: field);
  }
}
