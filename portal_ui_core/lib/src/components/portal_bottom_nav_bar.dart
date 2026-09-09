import 'package:flutter/material.dart';

import '../theme/portal_ui_theme.dart';

/// A destination in [PortalBottomNavBar].
@immutable
class PortalNavDestination {
  const PortalNavDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    this.badgeCount,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;

  /// Renders a count on the icon. Null or zero shows nothing.
  final int? badgeCount;
}

/// Floating pill navigation — icon over an **always-visible** label.
///
/// Extracted from portal_recipe so every Portal app navigates the same way.
/// The label is never hidden on unselected destinations: a first-timer has
/// to be able to read the whole map, not just where they already are.
///
/// Colors resolve from [PortalUiTheme] so the bar inherits each app's world;
/// the overrides exist for a surface that deliberately differs.
class PortalBottomNavBar extends StatelessWidget {
  const PortalBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
    this.backgroundColor,
    this.borderColor,
    this.markColor,
    this.selectedWellColor,
    this.selectedMarkColor,
    this.boxShadow,
    this.height = barHeight,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<PortalNavDestination> destinations;

  final Color? backgroundColor;
  final Color? borderColor;

  /// Icon and label color. Unselected destinations render it at reduced
  /// opacity — still above the 4.5:1 floor for the label.
  final Color? markColor;

  /// The well behind the selected icon.
  final Color? selectedWellColor;

  /// Mark color when selected, if it must differ from [markColor] — e.g. an
  /// ink well needs a paper-colored mark.
  final Color? selectedMarkColor;

  final List<BoxShadow>? boxShadow;
  final double height;

  static const double barHeight = 68;
  static const double outerBottomPadding = 10;
  static const double outerHorizontalPadding = 20;
  static const double overlayClearance =
      barHeight + outerBottomPadding + 8;

  /// Bottom padding for a FAB so it clears the floating pill.
  static const double fabBottomPadding = overlayClearance + 12;

  /// Bottom padding for a scrolling body so the last row clears the pill.
  static const double contentBottomInset = overlayClearance + 12;

  /// Bottom padding for a scrolling body that also has a FAB.
  static const double contentBottomInsetWithFab =
      fabBottomPadding + 56 + 12;

  @override
  Widget build(BuildContext context) {
    final portal = PortalUiTheme.of(context);
    final tokens = portal.tokens;
    final brightness = Theme.of(context).brightness;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    final bg = backgroundColor ?? portal.card;
    final border = borderColor ?? portal.border;
    final mark = markColor ?? portal.onCard;
    final well = selectedWellColor ?? portal.muted;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        outerHorizontalPadding,
        0,
        outerHorizontalPadding,
        outerBottomPadding + bottomInset * 0.35,
      ),
      child: AnimatedContainer(
        duration: tokens.motion.medium,
        curve: tokens.motion.standard,
        height: height,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(tokens.radii.xl),
          border: Border.all(color: border),
          boxShadow: boxShadow ?? tokens.elevation.medium(brightness),
        ),
        child: Row(
          children: [
            for (var i = 0; i < destinations.length; i++)
              Expanded(
                child: _NavItem(
                  destination: destinations[i],
                  isSelected: i == selectedIndex,
                  onTap: () => onDestinationSelected(i),
                  mark: mark,
                  selectedMark: selectedMarkColor ?? mark,
                  well: well,
                  radius: tokens.radii.lg,
                  duration: tokens.motion.medium,
                  curve: tokens.motion.standard,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.destination,
    required this.isSelected,
    required this.onTap,
    required this.mark,
    required this.selectedMark,
    required this.well,
    required this.radius,
    required this.duration,
    required this.curve,
  });

  final PortalNavDestination destination;
  final bool isSelected;
  final VoidCallback onTap;
  final Color mark;
  final Color selectedMark;
  final Color well;
  final double radius;
  final Duration duration;
  final Curve curve;

  @override
  Widget build(BuildContext context) {
    final count = destination.badgeCount ?? 0;
    final fg = isSelected ? selectedMark : mark.withValues(alpha: 0.68);

    return Semantics(
      button: true,
      selected: isSelected,
      label: count > 0
          ? '${destination.label}, $count'
          : destination.label,
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(radius),
          splashColor: mark.withValues(alpha: 0.12),
          highlightColor: mark.withValues(alpha: 0.08),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  AnimatedContainer(
                    duration: duration,
                    curve: curve,
                    width: 48,
                    height: 30,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected ? well : Colors.transparent,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Icon(
                      isSelected
                          ? destination.selectedIcon
                          : destination.icon,
                      size: 22,
                      color: fg,
                    ),
                  ),
                  if (count > 0)
                    Positioned(
                      right: 2,
                      top: -2,
                      child: _Badge(count: count),
                    ),
                ],
              ),
              const SizedBox(height: 3),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Text(
                  destination.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.1,
                    fontWeight:
                        isSelected ? FontWeight.w700 : FontWeight.w500,
                    // The label sits outside the well, on the bar itself, so
                    // it always takes the bar's mark color — never the well's
                    // foreground, which would be invisible out here.
                    color: mark.withValues(alpha: isSelected ? 1 : 0.68),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final portal = PortalUiTheme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      constraints: const BoxConstraints(minWidth: 16),
      decoration: BoxDecoration(
        color: portal.destructive,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: portal.card, width: 1.5),
      ),
      child: Text(
        count > 99 ? '99+' : '$count',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: portal.onDestructive,
          fontSize: 9,
          height: 1.2,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
