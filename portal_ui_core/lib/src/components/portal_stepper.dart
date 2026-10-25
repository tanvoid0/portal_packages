import 'package:flutter/material.dart';

import '../theme/portal_icons.dart';
import '../theme/portal_ui_theme.dart';
import 'portal_button.dart';
import '../theme/portal_theme_helpers.dart';

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
/// The text is a live region, so a change is announced -- unless
/// [semanticLabel] names what is counted ('Servings'), when it is one
/// adjustable node ("Servings, 4 pcs") that swipes up and down by [step].
/// [grouped] seats both buttons and the value in one high pill, as the search
/// field and the composer are. [enabled] false (while its form saves) dims the
/// buttons and stops the value adjusting. State stays with the caller: it
/// passes [value] and takes [onChanged]. Whole numbers only (fractions:
/// `PortalDecimalStepper`); not a typed-in number field, which is
/// `PortalTextField`.
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
    this.format,
    this.valueStyle,
    this.decreaseTooltip = 'Decrease',
    this.increaseTooltip = 'Increase',
    this.size = PortalButtonSize.md,
    this.variant = PortalButtonVariant.ghost,
    this.foregroundColor,
    this.semanticLabel,
    this.grouped = false,
    this.enabled = true,
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

  /// How a value is written, shown and spoken; defaults to the plain integer.
  /// [PortalDecimalStepper] uses it to count in whole steps and write them as
  /// fractions.
  final String Function(int value)? format;

  /// Defaults to the body style, tabular figures.
  final TextStyle? valueStyle;

  final String decreaseTooltip;
  final String increaseTooltip;

  /// Button size: 36 / 48 / 56 painted, hit area at least `minTapTarget`.
  final PortalButtonSize size;
  final PortalButtonVariant variant;

  /// Ink of both buttons; defaults to the variant's.
  final Color? foregroundColor;

  /// What is being counted, sentence case ('Servings', 'Weight'). The value
  /// text then becomes one adjustable node under this name instead of a live
  /// region; write the tooltips from it too ("Decrease servings").
  final String? semanticLabel;

  /// One high pill around the buttons and the value, so they read as one
  /// control.
  final bool grouped;

  /// False disables both buttons and the adjustable value (while a form
  /// saves).
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final tokens = PortalUiTheme.of(context).tokens;
    final cs = Theme.of(context).colorScheme;
    // The body role is muted ink; a set value is not a hint.
    final style = (valueStyle ?? tokens.textStyles.body.copyWith(color: cs.onSurface))
        .copyWith(
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    String figure(int v) => format?.call(v) ?? '$v';
    final shown = label ?? figure(value);
    final down = enabled && value > min
        ? () => onChanged((value - step).clamp(min, max))
        : null;
    final up = enabled && value < max
        ? () => onChanged((value + step).clamp(min, max))
        : null;
    String say(int v) => unit == null ? figure(v) : '${figure(v)} $unit';

    // Shrinks to the room between the buttons rather than overflowing a narrow
    // slot: the figure stays whole, which an ellipsis would not keep.
    final text = FittedBox(
      fit: BoxFit.scaleDown,
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
    );

    final row = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        PortalButton.icon(
          icon: PortalIcons.remove_rounded,
          tooltip: decreaseTooltip,
          variant: variant,
          size: size,
          foregroundColor: foregroundColor,
          onPressed: down,
        ),
        SizedBox(width: tokens.spacing.xs),
        Flexible(
          child: semanticLabel == null
              ? Semantics(liveRegion: true, child: text)
              : Semantics(
                  label: semanticLabel,
                  value: label ?? say(value),
                  // With [label] in the number's place there is no figure to
                  // say the next value with: the platform reads it as it lands.
                  increasedValue: up == null || label != null
                      ? null
                      : say((value + step).clamp(min, max)),
                  decreasedValue: down == null || label != null
                      ? null
                      : say((value - step).clamp(min, max)),
                  onIncrease: up,
                  onDecrease: down,
                  child: ExcludeSemantics(child: text),
                ),
        ),
        SizedBox(width: tokens.spacing.xs),
        PortalButton.icon(
          icon: PortalIcons.add_rounded,
          tooltip: increaseTooltip,
          variant: variant,
          size: size,
          foregroundColor: foregroundColor,
          onPressed: up,
        ),
      ],
    );
    return grouped
        ? DecoratedBox(
            decoration: BoxDecoration(
              color: portalOffPage(context, cs.surfaceContainerHigh),
              borderRadius: BorderRadius.circular(tokens.radii.full),
            ),
            child: row,
          )
        : row;
  }
}
