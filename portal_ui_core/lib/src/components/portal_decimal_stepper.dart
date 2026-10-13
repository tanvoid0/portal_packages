import 'package:flutter/material.dart';

import 'portal_button.dart';
import 'portal_stepper.dart';

/// [PortalStepper] for fractional steps: `-  7.5 h  +` moving by [step] (0.5).
///
/// It is a [PortalStepper] counting in whole steps -- 7.5 is 15 half-steps --
/// and writing each count back as `count * step`, so the buttons, bounds, hit
/// area and semantics are the stepper's and 7.5 + 0.5 is exactly 8 with no
/// float drift. The figure carries no trailing `.0` ('7.5', '8'); [unit]
/// follows it, and [semanticLabel] makes it one adjustable node that swipes by
/// [step].
///
/// A null [value] is "not set": [emptyLabel] stands in for the figure and the
/// first tap of either button lands on [initial] rather than a step from it.
/// [min], [max] and [initial] are rounded onto the step grid.
class PortalDecimalStepper extends StatelessWidget {
  const PortalDecimalStepper({
    super.key,
    required this.value,
    required this.onChanged,
    this.step = 0.5,
    this.min = 0,
    this.max = 999,
    this.initial = 0,
    this.emptyLabel = '–',
    this.unit,
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

  final double? value;
  final ValueChanged<double> onChanged;
  final double step;
  final double min;
  final double max;

  /// Where an unset value starts.
  final double initial;

  /// The figure shown while [value] is null.
  final String emptyLabel;
  final String? unit;
  final TextStyle? valueStyle;
  final String decreaseTooltip;
  final String increaseTooltip;
  final PortalButtonSize size;
  final PortalButtonVariant variant;
  final Color? foregroundColor;
  final String? semanticLabel;
  final bool grouped;
  final bool enabled;

  // Digits after the point in [step] ('0.5' -> 1, '0.25' -> 2).
  int get _decimals {
    final s = step.toString();
    final dot = s.indexOf('.');
    return dot < 0 ? 0 : s.length - dot - 1;
  }

  String _format(int count) {
    final fixed = (count * step).toStringAsFixed(_decimals);
    // '7.50' -> '7.5', '8.0' -> '8'
    return fixed.contains('.')
        ? fixed.replaceFirst(RegExp(r'\.?0+$'), '')
        : fixed;
  }

  @override
  Widget build(BuildContext context) {
    int units(double v) => (v / step).round();
    final lo = (min / step - 1e-9).ceil();
    final hi = (max / step + 1e-9).floor();
    final start = units(initial).clamp(lo, hi);
    final current = value;
    return PortalStepper(
      value: current == null ? start : units(current).clamp(lo, hi),
      min: lo,
      max: hi,
      label: current == null ? emptyLabel : null,
      format: _format,
      // Via the text so 3 * 0.1 is 0.3, not 0.30000000000000004.
      onChanged: (n) => onChanged(double.parse(_format(current == null ? start : n))),
      unit: unit,
      valueStyle: valueStyle,
      decreaseTooltip: decreaseTooltip,
      increaseTooltip: increaseTooltip,
      size: size,
      variant: variant,
      foregroundColor: foregroundColor,
      // ponytail: unset is a live region, not an adjustable node -- the
      // stepper's label mode has no next value to say; swipe-adjust arrives
      // with the first tap.
      semanticLabel: current == null ? null : semanticLabel,
      grouped: grouped,
      enabled: enabled,
    );
  }
}
