import 'package:flutter/material.dart';

import '../theme/portal_icons.dart';
import '../theme/portal_ui_theme.dart';
import 'portal_button.dart';

/// A quantity with a minus and a plus: `-  2 pcs  +`.
///
/// Each button is a `PortalButton.icon` (ghost by default), so the hit area is
/// at least `minTapTarget` whatever [size]; the button for a bound already
/// reached is disabled rather than hidden. [step] moves the value by more than
/// one and the result is clamped to [min]..[max].
///
/// [label] replaces the number with your own text (`2/4`, `Level 3`); [unit]
/// follows the number in the caption style. The tooltips are the buttons'
/// only names: pass them localised and from what the tap does ("Remove one").
/// The text is a live region, so a change is announced. State stays with the
/// caller: it passes [value] and takes [onChanged]. Not a typed-in number
/// field, which is `PortalTextField`.
class PortalStepper extends StatelessWidget {
  const PortalStepper({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max = 999,
    this.step = 1,
    this.label,
    this.unit,
    this.valueStyle,
    this.decreaseTooltip = 'Decrease',
    this.increaseTooltip = 'Increase',
    this.size = PortalButtonSize.md,
    this.variant = PortalButtonVariant.ghost,
    this.foregroundColor,
  })  : assert(step > 0, 'step moves the value; it must be positive'),
        assert(min <= max, 'min must not exceed max');

  final int value;
  final ValueChanged<int> onChanged;
  final int min;
  final int max;
  final int step;

  /// Text between the buttons in place of the number.
  final String? label;

  /// Caption after the number (`pcs`, `kg`); ignored with [label].
  final String? unit;

  /// Defaults to the body style, tabular figures.
  final TextStyle? valueStyle;

  final String decreaseTooltip;
  final String increaseTooltip;

  /// Button size: 36 / 48 / 56 painted, hit area at least `minTapTarget`.
  final PortalButtonSize size;
  final PortalButtonVariant variant;

  /// Ink of both buttons; defaults to the variant's.
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    final tokens = PortalUiTheme.of(context).tokens;
    final cs = Theme.of(context).colorScheme;
    final style = (valueStyle ?? tokens.textStyles.body).copyWith(
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    final shown = label ?? '$value';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        PortalButton.icon(
          icon: PortalIcons.remove_rounded,
          tooltip: decreaseTooltip,
          variant: variant,
          size: size,
          foregroundColor: foregroundColor,
          onPressed:
              value > min ? () => onChanged((value - step).clamp(min, max)) : null,
        ),
        SizedBox(width: tokens.spacing.xs),
        Semantics(
          liveRegion: true,
          child: Text.rich(
            TextSpan(children: [
              TextSpan(text: shown, style: style),
              if (label == null && unit != null)
                TextSpan(
                  text: ' $unit',
                  style: tokens.textStyles.caption
                      .copyWith(color: cs.onSurfaceVariant),
                ),
            ]),
          ),
        ),
        SizedBox(width: tokens.spacing.xs),
        PortalButton.icon(
          icon: PortalIcons.add_rounded,
          tooltip: increaseTooltip,
          variant: variant,
          size: size,
          foregroundColor: foregroundColor,
          onPressed:
              value < max ? () => onChanged((value + step).clamp(min, max)) : null,
        ),
      ],
    );
  }
}
