import 'package:flutter/material.dart';

import '../theme/portal_ui_theme.dart';

/// Full-width segmented control — two to four peer views of the same data.
///
/// More than four segments will not fit a phone; use tabs or a filter row
/// instead.
class PortalSegmentedTabs extends StatelessWidget {
  const PortalSegmentedTabs({
    super.key,
    required this.labels,
    required this.index,
    required this.onChanged,
    this.accent,
  }) : assert(labels.length >= 2, 'A segmented control needs two segments');

  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;

  /// Selected segment tint. Defaults to the app's primary.
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final portal = PortalUiTheme.of(context);
    final tokens = portal.tokens;
    final tint = accent ?? portal.primary;
    final radius = BorderRadius.circular(tokens.radii.md);

    return Row(
      children: [
        for (var i = 0; i < labels.length; i++) ...[
          if (i > 0) SizedBox(width: tokens.spacing.sm),
          Expanded(
            child: Material(
              color: index == i
                  ? tint.withValues(alpha: 0.15)
                  : portal.surfaceVariant,
              borderRadius: radius,
              child: InkWell(
                onTap: () => onChanged(i),
                borderRadius: radius,
                child: Container(
                  constraints:
                      BoxConstraints(minHeight: tokens.minTapTarget),
                  alignment: Alignment.center,
                  padding:
                      EdgeInsets.symmetric(horizontal: tokens.spacing.sm),
                  child: Text(
                    labels[i],
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: tokens.textStyles.caption.copyWith(
                      color: index == i ? tint : portal.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
