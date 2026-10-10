import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../motion/portal_haptics.dart';
import '../theme/portal_icons.dart';
import '../theme/portal_ui_theme.dart';
import '../tokens/design_tokens.dart';
import 'portal_pressable.dart';

/// One cell of a [PortalChoiceGrid]: a colour disc, a glyph, an emoji or any
/// widget, and the [label] that is its only accessible name.
@immutable
class PortalChoiceOption {
  const PortalChoiceOption.color(this.label, Color color)
      : _color = color,
        _icon = null,
        _emoji = null,
        _child = null;

  const PortalChoiceOption.icon(this.label, IconData icon)
      : _color = null,
        _icon = icon,
        _emoji = null,
        _child = null;

  const PortalChoiceOption.emoji(this.label, String emoji)
      : _color = null,
        _icon = null,
        _emoji = emoji,
        _child = null;

  const PortalChoiceOption.custom(this.label, Widget child)
      : _color = null,
        _icon = null,
        _emoji = null,
        _child = child;

  /// What a screen reader says for the cell ("Red", "Groceries"). Written from
  /// what the cell is, not what it looks like.
  final String label;

  final Color? _color;
  final IconData? _icon;
  final String? _emoji;
  final Widget? _child;

  Widget _glyph(DesignTokens tokens) {
    if (_color case final color?) {
      return DecoratedBox(
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: SizedBox.square(dimension: tokens.iconSizes.xl),
      );
    }
    if (_icon case final icon?) return Icon(icon);
    if (_emoji case final emoji?) return Text(emoji);
    return _child!;
  }
}

/// A grid of square cells, one selected: a colour, icon or emoji picker.
///
/// The selected cell is drawn with an inset outline *and* a check badge, never
/// by fill alone, and is announced as selected in one mutually exclusive
/// group. Columns are as many as fit at `minTapTarget`, the cells stretched
/// (square) to share the width, so the grid runs gutter to gutter.
///
/// [selectedColor] is the outline and badge fill (the scheme primary by
/// default). [ground] is what the grid sits on, for the badge's cut-out ring:
/// pass the sheet's colour on a sheet. [enabled] false (its form is saving)
/// dims the grid, ignores taps and announces it disabled. State stays with the
/// caller: it passes [selected] and takes [onSelected].
class PortalChoiceGrid extends StatelessWidget {
  const PortalChoiceGrid({
    super.key,
    required this.choices,
    required this.selected,
    required this.onSelected,
    this.selectedColor,
    this.ground,
    this.enabled = true,
  });

  final List<PortalChoiceOption> choices;

  /// Index into [choices], or null for none selected.
  final int? selected;
  final ValueChanged<int> onSelected;

  /// The selected cell's outline and badge fill. Null is the theme primary.
  final Color? selectedColor;

  /// The colour behind the grid, for the check badge's cut-out ring. Null is
  /// the scaffold background.
  final Color? ground;

  final bool enabled;

  // Same dim as PortalSelect's disabled ink.
  static const _disabledOpacity = 0.38;

  @override
  Widget build(BuildContext context) {
    final tokens = PortalUiTheme.of(context).tokens;
    final tap = tokens.minTapTarget;
    final gap = tokens.spacing.sm;
    return LayoutBuilder(
      builder: (context, c) {
        var cell = tap;
        if (c.maxWidth.isFinite) {
          final n = math.max(1, ((c.maxWidth + gap) / (tap + gap)).floor());
          // Floored to 1/100 so float error never wraps the last column.
          cell = math.max(
            tap,
            ((c.maxWidth - (n - 1) * gap) / n * 100).floorToDouble() / 100,
          );
        }
        return _grid(context, cell, gap);
      },
    );
  }

  Widget _grid(BuildContext context, double cell, double gap) {
    final portal = PortalUiTheme.of(context);
    final tokens = portal.tokens;
    final accent = selectedColor ?? portal.primary;
    final onAccent = selectedColor == null
        ? portal.onPrimary
        : (ThemeData.estimateBrightnessForColor(accent) == Brightness.dark
            ? Colors.white
            : Colors.black);
    final radius = BorderRadius.circular(tokens.radii.md);
    final glyph = TextStyle(fontSize: IconTheme.of(context).size, height: 1);
    return Opacity(
      opacity: enabled ? 1 : _disabledOpacity,
      child: Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [
          for (final (i, choice) in choices.indexed)
            // No `enabled:` here: PortalPressable's own node carries it, and
            // two nodes both setting it would split the cell in two for a
            // screen reader.
            Semantics(
              selected: i == selected,
              inMutuallyExclusiveGroup: true,
              label: choice.label,
              child: PortalPressable(
                enabled: enabled,
                onTap: () => onSelected(i),
                haptic: PortalHapticKind.selection,
                borderRadius: radius,
                child: ExcludeSemantics(
                  child: SizedBox.square(
                    dimension: cell,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: portal.surfaceVariant,
                              borderRadius: radius,
                              border: i == selected
                                  ? Border.all(
                                      color: accent,
                                      width: tokens.borderWidth + 0.5,
                                      strokeAlign: BorderSide.strokeAlignInside,
                                    )
                                  : null,
                            ),
                            child: Center(
                              child: DefaultTextStyle.merge(
                                style: glyph,
                                child: choice._glyph(tokens),
                              ),
                            ),
                          ),
                        ),
                        if (i == selected)
                          PositionedDirectional(
                            top: -tokens.spacing.xs,
                            end: -tokens.spacing.xs,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: accent,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: ground ??
                                      Theme.of(context).scaffoldBackgroundColor,
                                  width: tokens.borderWidth * 2,
                                ),
                              ),
                              child: SizedBox.square(
                                dimension: tokens.iconSizes.md,
                                child: Icon(
                                  PortalIcons.check_rounded,
                                  size: tokens.iconSizes.xs,
                                  color: onAccent,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
