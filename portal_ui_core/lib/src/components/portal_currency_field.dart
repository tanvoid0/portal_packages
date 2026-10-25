import 'package:flutter/material.dart';

import '../format/portal_currency.dart';
import '../theme/portal_ui_theme.dart';
import 'portal_pressable.dart';
import 'portal_search_field.dart';
import 'portal_select.dart';
import 'portal_sheet.dart';

/// A tap-to-open currency selector: a [PortalSelect.picker] field showing the
/// chosen currency (flag, code and name) that opens a searchable sheet of
/// [PortalCurrency]s. Shared by finance and travel so both offer the same
/// full list with flags and symbols instead of a short hard-coded dropdown.
///
/// [value] is the current ISO code; [onChanged] fires with the picked code. A
/// null [onChanged] disables the field.
class PortalCurrencyField extends StatelessWidget {
  const PortalCurrencyField({
    super.key,
    required this.value,
    required this.onChanged,
    this.label = 'Currency',
    this.hint,
    this.helper,
    this.required = false,
    this.currencies = kPortalCurrencies,
  });

  final String value;
  final ValueChanged<String>? onChanged;
  final String? label;
  final String? hint;
  final String? helper;
  final bool required;

  /// The list offered in the sheet. Defaults to the whole fleet set.
  final List<PortalCurrency> currencies;

  @override
  Widget build(BuildContext context) {
    final c = portalCurrencyOf(value);
    // Collapsed label stays compact: flag + symbol (adds the code when the
    // symbol is just the code, so it is never bare). Full name is in the
    // picker. Compact so it fits a narrow field without truncating.
    final shown = c == null
        ? (value.isEmpty ? null : value)
        : [
            if (c.flag.isNotEmpty) c.flag,
            c.symbol,
          ].join(' ');
    return PortalSelect.picker(
      label: label,
      hint: hint,
      helper: helper,
      required: required,
      value: shown,
      icon: Icons.expand_more_rounded,
      onTap: onChanged == null
          ? null
          : () async {
              final picked = await showPortalCurrencyPicker(
                context,
                selected: value,
                currencies: currencies,
              );
              if (picked != null) onChanged!(picked);
            },
    );
  }
}

/// Opens the searchable currency sheet and resolves to the picked ISO code,
/// or null if dismissed. Filters by code, name or symbol as the user types.
Future<String?> showPortalCurrencyPicker(
  BuildContext context, {
  String? selected,
  List<PortalCurrency> currencies = kPortalCurrencies,
}) async {
  final picked = await PortalSheet.show<String>(
    context,
    builder: (_) => _CurrencyPickerSheet(
      currencies: currencies,
      selected: selected?.toUpperCase(),
    ),
  );
  // Remember the choice so the next money field can default to it.
  if (picked != null) portalLastUsedCurrency = picked;
  return picked;
}

class _CurrencyPickerSheet extends StatefulWidget {
  const _CurrencyPickerSheet({required this.currencies, this.selected});

  final List<PortalCurrency> currencies;
  final String? selected;

  @override
  State<_CurrencyPickerSheet> createState() => _CurrencyPickerSheetState();
}

class _CurrencyPickerSheetState extends State<_CurrencyPickerSheet> {
  String _query = '';

  List<PortalCurrency> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return widget.currencies;
    return widget.currencies
        .where((c) =>
            c.code.toLowerCase().contains(q) ||
            c.name.toLowerCase().contains(q) ||
            c.symbol.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final portal = PortalUiTheme.of(context);
    final tokens = portal.tokens;
    final cs = Theme.of(context).colorScheme;
    final pad = EdgeInsets.symmetric(horizontal: tokens.layout.pageHorizontal);
    final rows = _filtered;

    // A fixed-height sheet so the Expanded list has a bounded height. The
    // modal's own max is the screen; 0.72 of it leaves the trip above visible.
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.72,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: pad.copyWith(
              top: tokens.spacing.sm,
              bottom: tokens.spacing.md,
            ),
            child: Semantics(
              header: true,
              child: Text('Currency', style: tokens.textStyles.title),
            ),
          ),
          Padding(
            padding: pad.copyWith(bottom: tokens.spacing.sm),
            child: PortalSearchField(
              autofocus: true,
              hintText: 'Search currency',
              onChanged: (v) => setState(() => _query = v),
              onClear: () => setState(() => _query = ''),
            ),
          ),
          Expanded(
            child: rows.isEmpty
                ? Center(
                    child: Text('No currencies match “$_query”',
                        style: tokens.textStyles.body
                            .copyWith(color: portal.mutedForeground)),
                  )
                : ListView.builder(
                    controller: PrimaryScrollController.maybeOf(context),
                    itemCount: rows.length,
                    itemBuilder: (context, i) {
                      final c = rows[i];
                      final sel = c.code == widget.selected;
                      return PortalPressable(
                        button: true,
                        onTap: () => Navigator.pop(context, c.code),
                        child: Semantics(
                          selected: sel,
                          label: '${c.name}, ${c.code}',
                          excludeSemantics: true,
                          child: Padding(
                            padding: pad.copyWith(
                              top: tokens.spacing.sm,
                              bottom: tokens.spacing.sm,
                            ),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: tokens.spacing.xl,
                                  child: Text(
                                    c.flag.isEmpty ? c.symbol : c.flag,
                                    style: tokens.textStyles.title,
                                  ),
                                ),
                                SizedBox(width: tokens.spacing.md),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text('${c.code} · ${c.symbol}',
                                          style: tokens.textStyles.body
                                              .copyWith(
                                                  fontWeight: FontWeight.w600)),
                                      Text(c.name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: tokens.textStyles.caption
                                              .copyWith(
                                                  color:
                                                      portal.mutedForeground)),
                                    ],
                                  ),
                                ),
                                if (sel)
                                  Icon(Icons.check_rounded,
                                      color: cs.primary,
                                      size: tokens.iconSizes.md),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
