import 'package:flutter/material.dart';

import '../motion/portal_haptics.dart';
import '../theme/portal_ui_theme.dart';

/// Full-width segmented control — two to four peer views of the same data.
///
/// More than four segments will not fit a phone; use tabs or a filter row
/// instead.
///
/// Each segment is heard as selected or not, mutually exclusive with the rest;
/// [semanticLabel] names the group ('Period', 'Direction'). [enabled] false
/// (its form is saving) dims it to 38%, inert and heard as disabled.
class PortalSegmentedTabs extends StatelessWidget {
  const PortalSegmentedTabs({
    super.key,
    required this.labels,
    required this.index,
    required this.onChanged,
    this.accentColor,
    this.scrollable = false,
    this.semanticLabel,
    this.enabled = true,
  }) : assert(labels.length >= 2, 'A segmented control needs two segments');

  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;

  /// Selected segment tint. Defaults to the app's primary.
  final Color? accentColor;

  /// Segments at their natural width in a sideways-scrolling row, instead of
  /// equal shares of the width. The default look is unchanged.
  final bool scrollable;

  /// What the choice is, announced as the name of the group.
  final String? semanticLabel;

  /// False refuses taps, dims to 38% and announces disabled.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final portal = PortalUiTheme.of(context);
    final tokens = portal.tokens;
    final tint = accentColor ?? portal.primary;
    final radius = BorderRadius.circular(tokens.radii.md);

    Widget share({required Widget child}) => scrollable ? child : Expanded(child: child);

    void select(int i) {
      if (i != index) PortalHaptics.selection();
      onChanged(i);
    }

    final row = Row(
      children: [
        for (var i = 0; i < labels.length; i++) ...[
          if (i > 0) SizedBox(width: tokens.spacing.sm),
          share(
            // The segment is one node, named and acting for the ink inside it.
            child: Semantics(
              container: true,
              selected: index == i,
              inMutuallyExclusiveGroup: true,
              enabled: enabled ? null : false,
              label: labels[i],
              onTap: enabled ? () => select(i) : null,
              child: ExcludeSemantics(
                // Fill under, ink over: a Material paints its ink features
                // before its child, so the tint must sit outside the
                // InkWell's Material or the ripple is hidden by the (opaque)
                // segment colour.
                child: AnimatedContainer(
                  duration: tokens.motion.fast,
                  curve: tokens.motion.standard,
                  decoration: BoxDecoration(
                    color: index == i
                        ? tint.withValues(alpha: 0.15)
                        : portal.surfaceVariant,
                    borderRadius: radius,
                  ),
                  child: Material(
                    type: MaterialType.transparency,
                    child: InkWell(
                      onTap: enabled ? () => select(i) : null,
                      borderRadius: radius,
                      child: Container(
                        constraints:
                            BoxConstraints(minHeight: tokens.minTapTarget),
                        alignment: Alignment.center,
                        padding: EdgeInsets.symmetric(
                            horizontal: scrollable
                                ? tokens.spacing.lg
                                : tokens.spacing.sm),
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
              ),
            ),
          ),
        ],
      ],
    );
    final dimmed = enabled ? row : Opacity(opacity: 0.38, child: row);
    final body = scrollable
        ? SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: dimmed,
          )
        : dimmed;
    return semanticLabel == null
        ? body
        : Semantics(
            container: true,
            explicitChildNodes: true,
            label: semanticLabel,
            child: body,
          );
  }
}
