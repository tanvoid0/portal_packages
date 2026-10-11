import 'package:flutter/material.dart';

import '../../contrast_gate.dart';
import '../motion/portal_haptics.dart';
import '../theme/portal_component_extensions.dart';
import '../theme/portal_ui_theme.dart';

/// A destination in [PortalBottomNavBar].
@immutable
class PortalNavDestination {
  const PortalNavDestination({
    required this.icon,
    this.selectedIcon,
    required this.label,
    this.badgeCount,
  });

  /// A `Symbols.*_rounded` glyph. Selection fills it (`fill` 0 → 1) on
  /// `tokens.motion.standard`, so no second icon is needed.
  final IconData icon;

  /// Glyph to swap in while selected. Only for a set that still uses
  /// Material's outlined / filled icon pair; leave null for Symbols.
  final IconData? selectedIcon;
  final String label;

  /// Renders a count on the icon. Null or zero shows nothing.
  final int? badgeCount;
}

/// [PortalBottomNavBar.variant]: [standard] is the shipped docked-well bar
/// (unchanged); [pill] is the 2026-10 redesign — a fully-rounded pill with a
/// single capsule that slides to the selected tab (covering icon *and*
/// label) and a scrim that fades page content out behind it.
enum PortalBottomNavVariant { standard, pill }

/// Floating pill navigation — icon over an **always-visible** label.
///
/// Extracted from portal_recipe so every Portal app navigates the same way.
/// The label is never hidden on unselected destinations: a first-timer has
/// to be able to read the whole map, not just where they already are.
///
/// Colors resolve from [PortalUiTheme] so the bar inherits each app's world;
/// the overrides exist for a surface that deliberately differs. A widget
/// argument beats [PortalNavBarTheme], which beats the default.
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
    this.variant = PortalBottomNavVariant.standard,
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

  /// Defaults to [PortalBottomNavVariant.standard] — every existing caller
  /// renders exactly as before. Pass `.pill` for the redesign.
  final PortalBottomNavVariant variant;

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
  Widget build(BuildContext context) => switch (variant) {
        PortalBottomNavVariant.standard => _buildStandard(context),
        PortalBottomNavVariant.pill => _buildPill(context),
      };

  Widget _buildStandard(BuildContext context) {
    final portal = PortalUiTheme.of(context);
    final tokens = portal.tokens;
    final brightness = Theme.of(context).brightness;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    final skin = PortalNavBarTheme.of(context);
    final bg = backgroundColor ?? skin.backgroundColor ?? portal.card;
    final border = borderColor ?? skin.borderColor ?? portal.border;
    final mark = markColor ?? skin.markColor ?? portal.onCard;
    final well = selectedWellColor ?? skin.selectedWellColor ?? portal.muted;
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : tokens.motion.medium;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        outerHorizontalPadding,
        0,
        outerHorizontalPadding,
        outerBottomPadding + bottomInset * 0.35,
      ),
      child: AnimatedContainer(
        duration: duration,
        curve: tokens.motion.standard,
        height: height,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(tokens.radii.xl),
          border: Border.all(color: border),
          boxShadow:
              boxShadow ?? skin.boxShadow ?? tokens.elevation.medium(brightness),
        ),
        child: Row(
          children: [
            for (var i = 0; i < destinations.length; i++)
              Expanded(
                child: _NavItem(
                  destination: destinations[i],
                  isSelected: i == selectedIndex,
                  onTap: () {
                    if (i != selectedIndex) PortalHaptics.selection();
                    onDestinationSelected(i);
                  },
                  mark: mark,
                  selectedMark: selectedMarkColor ?? skin.selectedMarkColor ?? mark,
                  well: well,
                  radius: tokens.radii.lg,
                  duration: duration,
                  curve: tokens.motion.standard,
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// The redesign: one capsule slides behind the selected tab and holds its
  /// icon *and* label (the standard variant's well sits behind the icon
  /// alone); the selected glyph fills and its label goes bold, in the
  /// selected mark color. A scrim fades page content out behind the pill so
  /// rows no longer hit a hard edge under it.
  Widget _buildPill(BuildContext context) {
    final portal = PortalUiTheme.of(context);
    final tokens = portal.tokens;
    final theme = Theme.of(context);
    final skin = PortalNavBarTheme.of(context);
    const side = outerHorizontalPadding;
    const floor = outerBottomPadding;
    const bottom = 18.0;
    const inner = 8.0;
    const thumbInset = 8.0;
    const scrim = 28.0;
    final mark = markColor ?? skin.markColor ?? portal.onCard;
    final selectedMark = selectedMarkColor ?? skin.selectedMarkColor ?? mark;
    final bg = backgroundColor ?? skin.backgroundColor ?? portal.card;
    final well =
        selectedWellColor ??
        skin.selectedWellColor ??
        portalWellOn(bg, selectedMark);
    final n = destinations.length;
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : tokens.motion.medium;
    final page = theme.scaffoldBackgroundColor;
    final x = n < 2 ? 0.0 : -1 + 2 * selectedIndex / (n - 1);

    Widget tab(int i) {
      final d = destinations[i];
      final on = i == selectedIndex;
      final count = d.badgeCount ?? 0;
      final fg = on ? selectedMark : mark.withValues(alpha: 0.68);
      return Expanded(
        child: Semantics(
          button: true,
          selected: on,
          label: count > 0 ? '${d.label}, $count' : d.label,
          excludeSemantics: true,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                if (!on) PortalHaptics.selection();
                onDestinationSelected(i);
              },
              borderRadius: BorderRadius.circular(tokens.radii.full),
              splashColor: mark.withValues(alpha: 0.12),
              highlightColor: mark.withValues(alpha: 0.08),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      TweenAnimationBuilder<double>(
                        tween: Tween(end: on ? 1.0 : 0.0),
                        duration: duration,
                        curve: tokens.motion.standard,
                        builder: (_, fill, __) => Icon(
                          on ? d.selectedIcon ?? d.icon : d.icon,
                          fill: fill,
                          size: 24,
                          color: fg,
                        ),
                      ),
                      if (count > 0)
                        Positioned(
                          right: -8,
                          top: -4,
                          child: _Badge(count: count),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    d.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: tokens.textStyles.caption.copyWith(
                      fontSize: 12,
                      height: 1.1,
                      letterSpacing: 0,
                      fontWeight: on ? FontWeight.w700 : FontWeight.w500,
                      color: fg,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return MediaQuery.removePadding(
      context: context,
      removeBottom: true,
      child: Padding(
        padding: const EdgeInsets.only(bottom: bottom - floor),
        child: Stack(
          // The pill's shadow must show past the Stack.
          clipBehavior: Clip.none,
          children: [
            // Content fades out under the pill; never takes a tap.
            Positioned(
              left: 0,
              right: 0,
              top: -scrim,
              bottom: -(bottom - floor),
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        page.withValues(alpha: 0),
                        page.withValues(alpha: .94),
                      ],
                      stops: const [0, .55],
                    ),
                  ),
                ),
              ),
            ),
            Positioned.fill(
              left: side,
              right: side,
              bottom: floor,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(tokens.radii.full),
                  border: Border.all(
                    color: borderColor ?? skin.borderColor ?? portal.border,
                  ),
                  boxShadow: boxShadow ??
                      skin.boxShadow ??
                      tokens.elevation.medium(theme.brightness),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                side + inner,
                0,
                side + inner,
                floor,
              ),
              child: SizedBox(
                height: height,
                child: Stack(
                  children: [
                    // One capsule slides to the selected tab.
                    Positioned.fill(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: thumbInset,
                        ),
                        child: AnimatedAlign(
                          duration: duration,
                          curve: tokens.motion.standard,
                          alignment: AlignmentDirectional(x, 0),
                          child: FractionallySizedBox(
                            widthFactor: 1 / n,
                            heightFactor: 1,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 2,
                              ),
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: well,
                                  borderRadius: BorderRadius.circular(
                                    tokens.radii.full,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Row(children: [for (var i = 0; i < n; i++) tab(i)]),
                  ],
                ),
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
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(end: isSelected ? 1 : 0),
                      duration: duration,
                      curve: curve,
                      builder: (_, fill, __) => Icon(
                        isSelected
                            ? destination.selectedIcon ?? destination.icon
                            : destination.icon,
                        fill: fill.clamp(0.0, 1.0),
                        size: 22,
                        color: fg,
                      ),
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
