import 'package:flutter/material.dart';

import '../theme/portal_ui_theme.dart';

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

  @override
  Widget build(BuildContext context) {
    final portal = PortalUiTheme.of(context);
    final tokens = portal.tokens;

    final fill = selected
        ? (selectedColor ?? portal.primary)
        : (unselectedColor ?? portal.surfaceVariant);
    final ink = selected
        ? (onSelectedColor ?? portal.onPrimary)
        : (onUnselectedColor ?? portal.onSurfaceVariant);
    final radius = BorderRadius.circular(tokens.radii.full);

    // Selection has to reach a screen reader too: an InkWell on its own
    // announces as neither a button nor a selected one, so the state the
    // fill and border carry visually would be invisible to TalkBack.
    return Semantics(
      button: onTap != null,
      selected: selected,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          onLongPress: onLongPress,
          child: AnimatedContainer(
            duration: tokens.motion.fast,
            curve: tokens.motion.standard,
            constraints: BoxConstraints(minHeight: tokens.minTapTarget),
            padding: EdgeInsets.symmetric(horizontal: tokens.spacing.md),
            decoration: BoxDecoration(
              color: fill,
              borderRadius: radius,
              border: Border.all(
                color: selected ? fill : (borderColor ?? portal.outline),
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
                  Icon(icon, size: tokens.typeScale.md, color: ink),
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
