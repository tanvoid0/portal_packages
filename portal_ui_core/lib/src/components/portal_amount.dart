import 'package:flutter/material.dart';

import '../format/portal_format.dart';
import '../theme/portal_semantic_colors.dart';
import '../theme/portal_ui_theme.dart';

enum PortalAmountSize { hero, row }

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
class PortalAmountDelta {
  const PortalAmountDelta({
    required this.icon,
    required this.text,
    this.positive = true,
  });

  final IconData icon;
  final String text;

  /// Good news is green, bad news the error colour, independent of the sign:
  /// falling spend is good.
  final bool positive;
}

/// A formatted money value: tabular figures, never wraps (a long value scales
/// its font down to fit).
///
/// [PortalAmountSize.hero] is the page's headline number, 44 pt at display
/// weight; one per page, everything else is a row value. With [signed], money
/// in is `+` and `success`, money out stays ink with a hyphen-minus.
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
  });

  final num value;
  final String currency;
  final PortalAmountSize size;
  final bool signed;

  /// Follows a space, set at .5em, w600, muted: `8,420 kg`.
  final String? unit;

  /// Hero only: the change under the number.
  final PortalAmountDelta? delta;

  /// Ink colour; [foregroundColor] wins over it.
  final PortalAmountTone tone;
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
    final v = decimals ? value : value.roundToDouble();
    final text = compact
        ? (signed && v > 0 ? '+' : '') + f.compact(v, currency: currency)
        : signed
            ? (decimals
                ? f.signed(v, currency)
                : (v > 0 ? '+' : '') + f.money(v, currency))
            : f.money(v, currency, padded: !hero && decimals);

    final base = hero
        ? tokens.textStyles.display.copyWith(
            fontSize: 44,
            height: 1.1,
            letterSpacing: -1,
          )
        : tokens.textStyles.body.copyWith(
            fontSize: 16,
            height: 1.35,
            fontWeight: FontWeight.w500,
          );
    final toneColor = switch (tone) {
      PortalAmountTone.neutral => signed && value > 0 ? success : cs.onSurface,
      PortalAmountTone.credit => success,
      PortalAmountTone.alert => cs.error,
      PortalAmountTone.muted => cs.onSurfaceVariant,
      PortalAmountTone.onPlate => cs.onInverseSurface,
    };
    final style = base.copyWith(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: foregroundColor ?? toneColor,
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
    final dColor = d.positive ? success : cs.error;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        fitted,
        SizedBox(height: tokens.spacing.xs),
        Row(mainAxisSize: MainAxisSize.min, children: [
          ExcludeSemantics(child: Icon(d.icon, size: 18, color: dColor)),
          SizedBox(width: tokens.spacing.xs),
          Text(
            d.text,
            style: tokens.textStyles.caption.copyWith(
              fontSize: 14,
              height: 1.3,
              fontWeight: FontWeight.w600,
              color: dColor,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ]),
      ],
    );
  }
}
