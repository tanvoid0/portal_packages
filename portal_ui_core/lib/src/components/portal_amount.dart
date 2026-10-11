import 'package:flutter/material.dart';

import '../format/portal_format.dart';
import '../theme/portal_semantic_colors.dart';
import '../theme/portal_sentiment.dart';
import '../theme/portal_ui_theme.dart';

/// [figure] (34 / 1.15) is a "scales to fit" cell in a figure strip; [summary]
/// (28 / 1.2) the one figure a card is about. Both are display-face, like
/// [hero], and take no delta.
enum PortalAmountSize { hero, row, figure, summary }

/// How an amount reads when it is not plain ink.
enum PortalAmountTone {
  /// Ink. The default; with `signed`, money in still turns `success`.
  neutral,

  /// `success`: money in.
  credit,

  /// `error`: overdue, over budget.
  alert,

  /// `onSurfaceVariant`: context figures, not the subject.
  muted,

  /// `onInverseSurface`: on a dark plate.
  onPlate,
}

/// A change under a hero number: a glyph and signed text in the sentiment
/// colour (14 / 1.3, w600). Never colour alone.
///
/// A widget too: [PortalAmount] hero draws it, and it stands alone under any
/// figure (a detail page's `-8% on August`).
class PortalAmountDelta extends StatelessWidget {
  const PortalAmountDelta({
    super.key,
    required this.icon,
    required this.text,
    this.positive = true,
  })  : sentiment =
            positive ? PortalSentiment.positive : PortalSentiment.negative,
        _glyph = true;

  /// [text] in any [sentiment]'s colour, the glyph optional. The text carries
  /// the sign, so colour is never the only signal.
  const PortalAmountDelta.toned(
    this.text, {
    super.key,
    this.sentiment = PortalSentiment.neutral,
    IconData? icon,
  })  : icon = icon ?? Icons.circle,
        positive = identical(sentiment, PortalSentiment.positive),
        _glyph = icon != null;

  /// Unused (a placeholder) when [PortalAmountDelta.toned] is given none.
  final IconData icon;
  final String text;

  /// Good news is green, bad news the error colour, independent of the sign:
  /// falling spend is good.
  final bool positive;

  /// What colours it; [positive] picks positive or negative.
  final PortalSentiment sentiment;
  final bool _glyph;

  @override
  Widget build(BuildContext context) {
    final tokens = PortalUiTheme.of(context).tokens;
    final color = sentiment.base(context);
    return Row(mainAxisSize: MainAxisSize.min, children: [
      if (_glyph) ...[
        ExcludeSemantics(child: Icon(icon, size: 18, color: color)),
        SizedBox(width: tokens.spacing.xs),
      ],
      Flexible(
        child: Text(
          text,
          style: tokens.textStyles.caption.copyWith(
            fontSize: 14,
            height: 1.3,
            fontWeight: FontWeight.w600,
            color: color,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ),
    ]);
  }
}

/// A formatted money value: tabular figures, never wraps (a long value scales
/// its font down to fit).
///
/// [PortalAmountSize.hero] is the page's headline number, 44 pt at display
/// weight; one per page, everything else is a row value. With [signed], money
/// in is `+` and `success`, money out stays ink with a hyphen-minus.
///
/// [PortalAmount.text] takes a value that is already formatted, for what the
/// money formatter cannot make (`8,420`, `1h 05m`).
class PortalAmount extends StatelessWidget {
  const PortalAmount(
    this.value,
    this.currency, {
    super.key,
    this.size = PortalAmountSize.row,
    this.signed = false,
    this.unit,
    this.delta,
    this.tone = PortalAmountTone.neutral,
    this.foregroundColor,
    this.fontSize,
    this.fontWeight,
    this.compact = false,
    this.decimals = true,
    this.sentiment,
  }) : _text = null;

  /// [text] as given, sign and currency included, in the amount's tabular
  /// type that never wraps. [value], [currency], [signed], [compact] and
  /// [decimals] do not apply.
  const PortalAmount.text(
    String this._text, {
    super.key,
    this.size = PortalAmountSize.row,
    this.unit,
    this.delta,
    this.tone = PortalAmountTone.neutral,
    this.sentiment,
    this.foregroundColor,
    this.fontSize,
    this.fontWeight,
  })  : value = 0,
        currency = '',
        signed = false,
        compact = false,
        decimals = true;

  final num value;
  final String currency;
  final String? _text;
  final PortalAmountSize size;
  final bool signed;

  /// Follows a space, set at .5em, w600, muted: `8,420 kg`.
  final String? unit;

  /// Hero only: the change under the number.
  final PortalAmountDelta? delta;

  /// Ink colour; [foregroundColor] wins over it.
  final PortalAmountTone tone;

  /// Ink from the status scale instead of [tone]; neutral is plain ink.
  /// [foregroundColor] still wins.
  final PortalSentiment? sentiment;
  final Color? foregroundColor;

  /// Override the size's font size / weight.
  final double? fontSize;
  final FontWeight? fontWeight;

  /// `£12.4K` (English K / M / B), for axis labels and dense chips.
  final bool compact;

  /// False rounds to whole units: `£13`, never `£12.60`.
  final bool decimals;

  @override
  Widget build(BuildContext context) {
    final tokens = PortalUiTheme.of(context).tokens;
    final cs = Theme.of(context).colorScheme;
    final success = PortalSemanticColors.of(context).success;
    final f = PortalFormat.of(context);
    final hero = size == PortalAmountSize.hero;
    final row = size == PortalAmountSize.row;
    // Rounded to what is shown, so a sub-penny value is neither signed nor green.
    final v = decimals ? (value * 100).round() / 100 : value.roundToDouble();
    final text = _text ??
        (compact
            ? (signed && v > 0 ? '+' : '') + f.compact(v, currency: currency)
            : signed
                ? (decimals
                    ? f.signed(v, currency)
                    : (v > 0 ? '+' : '') + f.money(v, currency))
                : f.money(v, currency, padded: row && decimals));

    final display = tokens.textStyles.display;
    final base = switch (size) {
      PortalAmountSize.hero =>
        display.copyWith(fontSize: 44, height: 1.1, letterSpacing: -1),
      PortalAmountSize.figure => display.copyWith(fontSize: 34, height: 1.15),
      PortalAmountSize.summary => display.copyWith(fontSize: 28, height: 1.2),
      PortalAmountSize.row => tokens.textStyles.body.copyWith(
          fontSize: 16,
          height: 1.35,
          fontWeight: FontWeight.w500,
        ),
    };
    final toneColor = switch (tone) {
      PortalAmountTone.neutral => signed && v > 0 ? success : cs.onSurface,
      PortalAmountTone.credit => success,
      PortalAmountTone.alert => cs.error,
      PortalAmountTone.muted => cs.onSurfaceVariant,
      PortalAmountTone.onPlate => cs.onInverseSurface,
    };
    final s = sentiment;
    final style = base.copyWith(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: foregroundColor ??
          (s == null || s == PortalSentiment.neutral
              ? toneColor
              : s.base(context)),
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    final fitted = FittedBox(
      fit: BoxFit.scaleDown,
      alignment: AlignmentDirectional.centerStart,
      child: Text.rich(
        TextSpan(children: [
          TextSpan(text: text),
          if (unit != null)
            TextSpan(
              text: ' $unit',
              style: TextStyle(
                fontSize: (style.fontSize ?? 16) * .5,
                fontWeight: FontWeight.w600,
                letterSpacing: 0,
                color: cs.onSurfaceVariant,
              ),
            ),
        ]),
        style: style,
        maxLines: 1,
        softWrap: false,
      ),
    );

    final d = delta;
    if (!hero || d == null) return fitted;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [fitted, SizedBox(height: tokens.spacing.xs), d],
    );
  }
}
