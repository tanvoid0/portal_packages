import 'package:flutter/material.dart';

import '../format/portal_currency.dart';
import '../theme/portal_ui_theme.dart';
import 'portal_currency_field.dart';
import 'portal_pressable.dart';
import 'portal_text_field.dart';

/// Amount + currency as one grouped input: a numeric field with the currency
/// [symbol] drawn as a prefix and a tappable currency chip (flag + code) at the
/// end that opens the searchable picker. One control, shared by finance and
/// travel, so a money input reads and behaves the same everywhere.
///
/// The caller owns the amount [controller] and the [currency] code (the same
/// shape the forms already use, so no view-model changes). Read the result as a
/// [PortalMoney] — exact minor units plus the code — via [money], and map it to
/// the app's own type (e.g. travel's ledger `Money`).
///
/// A null [onCurrencyChanged] locks the currency: the chip shows the code but
/// does not open the picker.
class PortalMoneyField extends StatelessWidget {
  const PortalMoneyField({
    super.key,
    required this.controller,
    required this.currency,
    this.onCurrencyChanged,
    this.label = 'Amount',
    this.hint,
    this.helper,
    this.errorText,
    this.validator,
    this.onChanged,
    this.enabled = true,
    this.signed = false,
    this.required = false,
    this.autofocus = false,
    this.currencies = kPortalCurrencies,
  });

  final TextEditingController controller;
  final String currency;

  /// Null locks the currency (chip shown, not tappable).
  final ValueChanged<String>? onCurrencyChanged;
  final String? label;
  final String? hint;
  final String? helper;
  final String? errorText;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final bool enabled;
  final bool signed;
  final bool required;
  final bool autofocus;
  final List<PortalCurrency> currencies;

  /// The field's current value as exact minor units + code, or null when there
  /// is no number yet.
  PortalMoney? get money => PortalMoney.parse(controller.text, currency);

  @override
  Widget build(BuildContext context) {
    final c = portalCurrencyOf(currency);
    final symbol = c?.symbol ?? currency;
    // A hint keeps the currency symbol (a prefix) visible even when the field
    // is empty and unfocused — Material hides a bare prefix otherwise — and
    // shows the expected format. Zero-decimal currencies drop the fraction.
    final amountHint = hint ?? ((c?.exponent ?? 2) == 0 ? '0' : '0.00');
    return PortalTextField.amount(
      controller: controller,
      label: label,
      hint: amountHint,
      helper: helper,
      errorText: errorText,
      validator: validator,
      onChanged: onChanged,
      enabled: enabled,
      signed: signed,
      required: required,
      autofocus: autofocus,
      currencySymbol: symbol,
      suffix: _CurrencyChip(
        currency: currency,
        enabled: enabled && onCurrencyChanged != null,
        currencies: currencies,
        onChanged: onCurrencyChanged,
      ),
    );
  }
}

class _CurrencyChip extends StatelessWidget {
  const _CurrencyChip({
    required this.currency,
    required this.enabled,
    required this.currencies,
    this.onChanged,
  });

  final String currency;
  final bool enabled;
  final List<PortalCurrency> currencies;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final portal = PortalUiTheme.of(context);
    final tokens = portal.tokens;
    final cs = Theme.of(context).colorScheme;
    final c = portalCurrencyOf(currency);
    final code = currency.toUpperCase();
    final label = [
      if (c != null && c.flag.isNotEmpty) c.flag,
      code,
    ].join(' ');

    final content = Padding(
      padding: EdgeInsets.symmetric(horizontal: tokens.spacing.sm),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: tokens.textStyles.body.copyWith(
                  fontWeight: FontWeight.w600,
                  color: enabled ? cs.onSurface : cs.onSurfaceVariant)),
          if (enabled)
            Icon(Icons.expand_more_rounded,
                size: tokens.iconSizes.sm, color: cs.onSurfaceVariant),
        ],
      ),
    );

    if (!enabled) {
      return Semantics(label: 'Currency $code', child: content);
    }
    return PortalPressable(
      button: true,
      borderRadius: BorderRadius.circular(tokens.radii.sm),
      onTap: () async {
        final picked = await showPortalCurrencyPicker(
          context,
          selected: currency,
          currencies: currencies,
        );
        if (picked != null) onChanged!(picked);
      },
      child: Semantics(
        button: true,
        label: 'Currency, $code',
        excludeSemantics: true,
        child: content,
      ),
    );
  }
}
