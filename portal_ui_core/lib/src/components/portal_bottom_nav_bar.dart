import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../contrast_gate.dart';
import '../motion/portal_haptics.dart';
import '../motion/portal_spring_curve.dart';
import '../theme/portal_component_extensions.dart';
import '../theme/portal_ui_theme.dart';
import 'portal_text.dart';

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
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<PortalNavDestination> destinations;

  final Color? backgroundColor;
  final Color? borderColor;

  /// Icon and label color. Unselected destinations render it at reduced
  /// opacity — still above the 4.5:1 floor for the label.
  final Color? markColor;

  /// The capsule behind the selected tab.
  final Color? selectedWellColor;

  /// Mark color when selected, if it must differ from [markColor] — e.g. an
  /// ink well needs a paper-colored mark.
  final Color? selectedMarkColor;

  final List<BoxShadow>? boxShadow;
  final double height;

  static const double barHeight = 68;
  static const double outerBottomPadding = 10;
  static const double outerHorizontalPadding = 20;
  static const double overlayClearance = barHeight + outerBottomPadding + 8;

  /// Bottom padding for a FAB so it clears the floating pill.
  static const double fabBottomPadding = overlayClearance + 12;

  /// Bottom padding for a scrolling body so the last row clears the pill.
  static const double contentBottomInset = overlayClearance + 12;

  /// Bottom padding for a scrolling body that also has a FAB.
  static const double contentBottomInsetWithFab = fabBottomPadding + 56 + 12;

  @override
  Widget build(BuildContext context) {
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
    final well = selectedWellColor ??
        skin.selectedWellColor ??
        portalWellOn(bg, selectedMark);
    final n = destinations.length;
    final still = MediaQuery.disableAnimationsOf(context);
    final duration = still ? Duration.zero : tokens.motion.medium;
    // The capsule *moves*, so it takes the spatial spring (a slight settle)
    // on that spring's own settle time; fill and colour keep `standard`.
    final slide = tokens.motion.emphasized;
    final slideDuration = still
        ? Duration.zero
        : slide is PortalSpringCurve
            ? slide.duration
            : tokens.motion.medium;
    final page = theme.scaffoldBackgroundColor;
    // Clear a gesture-nav handle the way the old docked bar did; the bar
    // removes the inset below so nothing else pads for it twice.
    final lift = bottom - floor + MediaQuery.paddingOf(context).bottom * .35;
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
                        builder: (_, fill, __) => Transform.scale(
                          // A small bump on the way in; never on the way out.
                          scale: on
                              ? 1 + .08 * math.sin(math.pi * fill.clamp(0.0, 1.0))
                              : 1,
                          child: Icon(
                            on ? d.selectedIcon ?? d.icon : d.icon,
                            fill: fill.clamp(0.0, 1.0),
                            size: 24,
                            color: fg,
                          ),
                        ),
                      ),
                      Positioned(
                        right: -8,
                        top: -4,
                        child: AnimatedSwitcher(
                          duration: duration,
                          switchInCurve: tokens.motion.emphasized,
                          transitionBuilder: (child, a) =>
                              ScaleTransition(scale: a, child: child),
                          child: count > 0
                              ? _Badge(key: ValueKey(count), count: count)
                              : const SizedBox.shrink(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  PortalText(
                    d.label,
                    maxLines: 1,
                    // One weight both ways: a bolder selected label is wider
                    // and nudges its neighbours on every switch.
                    style: tokens.textStyles.caption.copyWith(
                      fontSize: 12,
                      height: 1.1,
                      letterSpacing: 0,
                      fontWeight: FontWeight.w600,
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
        padding: EdgeInsets.only(bottom: lift),
        child: Stack(
          // The pill's shadow must show past the Stack.
          clipBehavior: Clip.none,
          children: [
            // Content fades out under the pill; never takes a tap.
            Positioned(
              left: 0,
              right: 0,
              top: -scrim,
              bottom: -lift,
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
                  // The spring settles a few px past an end tab; the pill's
                  // inner padding has room for it.
                  clipBehavior: Clip.none,
                  children: [
                    // One capsule slides to the selected tab.
                    Positioned.fill(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: thumbInset,
                        ),
                        child: AnimatedAlign(
                          duration: slideDuration,
                          curve: slide,
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

class _Badge extends StatelessWidget {
  const _Badge({super.key, required this.count});

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
        style: portal.tokens.textStyles.caption.copyWith(
          color: portal.onDestructive,
          fontSize: 10,
          letterSpacing: 0,
          height: 1.2,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
