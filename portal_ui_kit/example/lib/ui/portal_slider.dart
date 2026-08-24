import 'package:flutter/material.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

/// Themed slider (shadcn Slider).
class PortalSlider extends StatelessWidget {
  const PortalSlider({
    required this.value,
    required this.onChanged,
    super.key,
    this.min = 0,
    this.max = 1,
    this.divisions,
    this.label,
  });

  final double value;
  final ValueChanged<double> onChanged;
  final double min;
  final double max;
  final int? divisions;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final portal = PortalUiTheme.of(context);

    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        activeTrackColor: portal.primary,
        inactiveTrackColor: portal.muted,
        thumbColor: portal.primary,
        overlayColor: portal.primary.withValues(alpha: 0.12),
        valueIndicatorColor: portal.primary,
        showValueIndicator:
            label != null ? ShowValueIndicator.onDrag : ShowValueIndicator.onlyForContinuous,
      ),
      child: Slider(
        value: value,
        min: min,
        max: max,
        divisions: divisions,
        label: label,
        onChanged: onChanged,
      ),
    );
  }
}
