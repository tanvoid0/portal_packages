import 'package:flutter/material.dart';

import '../format/portal_format.dart';
import '../theme/portal_semantic_colors.dart';
import '../theme/portal_ui_theme.dart';

enum PortalAmountSize { hero, row }

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
  });

  final num value;
  final String currency;
  final PortalAmountSize size;
  final bool signed;

  /// Follows a space, set at .5em, w600, muted: `8,420 kg`.
  final String? unit;

  /// Hero only: the change under the number.
  final PortalAmountDelta? delta;

  @override
  Widget build(BuildContext context) {
    final tokens = PortalUiTheme.of(context).tokens;
    final cs = Theme.of(context).colorScheme;
    final success = PortalSemanticColors.of(context).success;
    final f = PortalFormat.of(context);
    final hero = size == PortalAmountSize.hero;
    final text = signed
        ? f.signed(value, currency)
        : f.money(value, currency, padded: !hero);

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
    final style = base.copyWith(
      color: signed && value > 0 ? success : cs.onSurface,
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
