import 'package:flutter/material.dart';

import '../motion/portal_haptics.dart';
import '../theme/portal_component_extensions.dart';
import '../theme/portal_ui_theme.dart';
import 'portal_pressable.dart';

/// Selectable pill.
///
/// Selected state is carried by fill *and* border, never by fill alone — a
/// chip that only changes tint disappears for anyone who cannot separate the
/// two colours.
class PortalFilterChip extends StatelessWidget {
  const PortalFilterChip({
    super.key,
    required this.label,
    required this.selected,
    this.onTap,
    this.icon,
    this.leading,
    this.onLongPress,
    this.selectedColor,
    this.onSelectedColor,
    this.unselectedColor,
    this.onUnselectedColor,
    this.borderColor,
    this.compact = false,
  });

  final String label;
  final bool selected;

  /// Null for a chip that only displays state -- a metadata label rendered as
  /// a pill. It then takes no ink and does not announce as a button.
  final VoidCallback? onTap;

  final IconData? icon;

  /// Takes precedence over [icon] — an avatar, a colour swatch, a count.
  final Widget? leading;

  final VoidCallback? onLongPress;

  final Color? selectedColor;

  /// Label and glyph colour when selected. Must contrast with
  /// [selectedColor] — a bright brand takes an ink label, not white.
  final Color? onSelectedColor;

  final Color? unselectedColor;

  /// Label and glyph colour when not selected. Defaults to
  /// `onSurfaceVariant`; set it where the unselected fill is tinted per
  /// item rather than being the one neutral surface.
  final Color? onUnselectedColor;

  final Color? borderColor;

  /// A 32 dp painted chip for dense rows. The hit area stays `minTapTarget`
  /// (an outer box, not taller paint). Re-skin colours and height app-wide
  /// with [PortalFilterChipTheme].
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final portal = PortalUiTheme.of(context);
    final tokens = portal.tokens;

    final skin = PortalFilterChipTheme.of(context);
    final fill = selected
        ? (selectedColor ?? skin.selectedColor ?? portal.primary)
        : (unselectedColor ?? skin.unselectedColor ?? portal.surfaceVariant);
    final ink = selected
        ? (onSelectedColor ?? skin.onSelectedColor ?? portal.onPrimary)
        : (onUnselectedColor ??
            skin.onUnselectedColor ??
            portal.onSurfaceVariant);
    final painted = skin.minHeight ?? (compact ? 32.0 : tokens.minTapTarget);
    final radius = BorderRadius.circular(tokens.radii.full);
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : tokens.motion.fast;

    // Selection has to reach a screen reader too: the pressable announces
    // the button, but the state the fill and border carry visually would
    // otherwise be invisible to TalkBack.
    return Semantics(
      selected: selected,
      child: PortalPressable(
        onTap: onTap,
        onLongPress: onLongPress,
        haptic: PortalHapticKind.selection,
        borderRadius: radius,
        child: _hitArea(
          tokens.minTapTarget,
          painted,
          AnimatedContainer(
            duration: duration,
            curve: tokens.motion.standard,
            constraints: BoxConstraints(minHeight: painted),
            padding: EdgeInsets.symmetric(horizontal: tokens.spacing.md),
            decoration: BoxDecoration(
              color: fill,
              borderRadius: radius,
              border: Border.all(
                color: selected
                    ? fill
                    : (borderColor ?? skin.borderColor ?? portal.outline),
                width: tokens.borderWidth,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (leading != null) ...[
                  leading!,
                  SizedBox(width: tokens.spacing.xs),
                ] else if (icon != null) ...[
                  TweenAnimationBuilder<double>(
                    tween: Tween(end: selected ? 1 : 0),
                    duration: duration,
                    curve: tokens.motion.standard,
                    builder: (_, fillAxis, __) => Icon(
                      icon,
                      fill: fillAxis.clamp(0.0, 1.0),
                      size: tokens.typeScale.md,
                      color: ink,
                    ),
                  ),
                  SizedBox(width: tokens.spacing.xs),
                ],
                Text(
                  label,
                  style: tokens.textStyles.caption.copyWith(color: ink),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// A paint under the minimum tap target gets a box around it, so the hit
  /// area is not painted height (`UI_PATTERNS.md`).
  static Widget _hitArea(double tap, double painted, Widget chip) =>
      painted >= tap ? chip : SizedBox(height: tap, child: Center(child: chip));
}

/// Horizontally scrolling row of [PortalFilterChip]s, inset to the page
/// gutter so the first chip aligns with the content column.
class PortalFilterChipRow extends StatelessWidget {
  const PortalFilterChipRow({
    super.key,
    required this.children,
    this.padding,
  });

  final List<Widget> children;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final tokens = PortalUiTheme.of(context).tokens;
    final gap = tokens.spacing.sm;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: padding ??
          EdgeInsets.fromLTRB(
            tokens.layout.pageHorizontal,
            0,
            tokens.layout.pageHorizontal,
            tokens.spacing.md,
          ),
      child: Row(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) SizedBox(width: gap),
            children[i],
          ],
        ],
      ),
    );
  }
}
