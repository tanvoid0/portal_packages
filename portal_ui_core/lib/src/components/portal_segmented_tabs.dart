import 'package:flutter/material.dart';

import '../motion/portal_haptics.dart';
import '../theme/portal_component_extensions.dart';
import '../theme/portal_theme_helpers.dart';
import '../theme/portal_ui_theme.dart';
import 'portal_text.dart';

/// How [PortalSegmentedTabs] marks the selected segment.
enum PortalSegmentedTabsStyle {
  /// A solid fill with on-colour text, the selected state of
  /// [PortalFilterChip] (and re-skinned by the same [PortalFilterChipTheme]);
  /// the rest sit outlined on a neutral surface. The default, so the choice
  /// reads at a glance and never looks disabled.
  solid,

  /// A soft tint of the accent with accent text. Quieter, but the selected
  /// segment is only a shade away from the rest.
  tinted,
}

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
    this.style = PortalSegmentedTabsStyle.solid,
    this.scrollable = false,
    this.semanticLabel,
    this.enabled = true,
  }) : assert(labels.length >= 2, 'A segmented control needs two segments');

  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;

  /// Selected segment colour: the fill when [style] is solid, the tint when
  /// tinted. Defaults to the chip theme's selected colour, then the app's
  /// primary.
  final Color? accentColor;

  /// How the selected segment is marked. Defaults to
  /// [PortalSegmentedTabsStyle.solid].
  final PortalSegmentedTabsStyle style;

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
    final skin = PortalFilterChipTheme.of(context);
    final solid = style == PortalSegmentedTabsStyle.solid;
    // Solid is the chip's selected state, so it takes the chip's skin; the
    // tinted look keeps its own, softer, reading of the accent.
    final tint =
        accentColor ?? (solid ? skin.selectedColor : null) ?? portal.primary;
    final onTint = accentColor != null
        ? portalInkOn(tint, (solid ? skin.onSelectedColor : null) ?? portal.onPrimary)
        : (solid ? skin.onSelectedColor : null) ?? portal.onPrimary;
    final restFill =
        (solid ? skin.unselectedColor : null) ?? portal.surfaceVariant;
    final restInk =
        (solid ? skin.onUnselectedColor : null) ?? portal.onSurfaceVariant;
    final restEdge = skin.borderColor ?? portal.outline;
    final radius = BorderRadius.circular(tokens.radii.md);

    Widget share({required Widget child}) =>
        scrollable ? child : Expanded(child: child);

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
                        ? (solid ? tint : tint.withValues(alpha: 0.15))
                        : restFill,
                    borderRadius: radius,
                  ),
                  // Painted over the segment, so the outline takes no room.
                  foregroundDecoration: solid
                      ? BoxDecoration(
                          borderRadius: radius,
                          border: Border.all(
                            color: index == i ? tint : restEdge,
                            width: tokens.borderWidth,
                          ),
                        )
                      : null,
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
                        child: PortalText(
                          labels[i],
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          style: tokens.textStyles.caption.copyWith(
                            color:
                                index == i ? (solid ? onTint : tint) : restInk,
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
    final dimmed = enabled
        ? row
        : Opacity(opacity: tokens.motion.disabledOpacity, child: row);
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
