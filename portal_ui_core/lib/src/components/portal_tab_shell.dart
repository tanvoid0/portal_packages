import 'package:flutter/material.dart';

import '../responsive/portal_breakpoints.dart';
import 'portal_bottom_nav_bar.dart';
import 'portal_nav_rail.dart';

/// The fleet's root tab shell: back on any tab but the first returns to the
/// first instead of leaving the app, the tabs are `IndexedStack` siblings so
/// each keeps its scroll position and in-progress state, and
/// [PortalBottomNavBar] drives the selection.
///
/// Extracted from five hand-built copies (gym, journey, shopping, lifestyle,
/// recipe) that all wrote the same `PopScope(canPop: i == 0)` +
/// `IndexedStack` + `Scaffold` + `PortalBottomNavBar` wiring around their own
/// state. [appBar] and [floatingActionButtonBuilder] are optional because
/// some of those shells have neither; [floatingActionButtonBuilder] is
/// index-aware because a FAB (gym, lifestyle) is often only shown on some
/// tabs.
class PortalTabShell extends StatelessWidget {
  const PortalTabShell({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
    required this.children,
    this.appBar,
    this.floatingActionButtonBuilder,
    this.backgroundColor,
    this.extendBody = false,
    this.resizeToAvoidBottomInset,
  }) : assert(children.length == destinations.length);

  /// The selected tab. Also the `IndexedStack` index.
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<PortalNavDestination> destinations;

  /// One body per destination, kept alive in an `IndexedStack` — never
  /// rebuilt on tab switch, so a half-typed search box or a scroll offset
  /// survives hopping away and back.
  final List<Widget> children;

  final PreferredSizeWidget? appBar;

  /// Called with [selectedIndex] on every build; return null to show no FAB
  /// on that tab.
  final Widget? Function(int index)? floatingActionButtonBuilder;

  final Color? backgroundColor;
  final bool extendBody;
  final bool? resizeToAvoidBottomInset;

  @override
  Widget build(BuildContext context) {
    final body = IndexedStack(index: selectedIndex, children: children);
    final fab = floatingActionButtonBuilder?.call(selectedIndex);

    // Past the expanded breakpoint a bottom pill wastes a tablet's width and
    // puts navigation under the thumb that isn't there; a side rail is the
    // adaptive form. Compact and medium keep the floating pill unchanged.
    final Widget scaffold = context.isExpandedOrWider
        ? Scaffold(
            appBar: appBar,
            backgroundColor: backgroundColor,
            resizeToAvoidBottomInset: resizeToAvoidBottomInset,
            floatingActionButton: fab,
            body: Row(
              children: [
                PortalNavRail(
                  selectedIndex: selectedIndex,
                  onDestinationSelected: onDestinationSelected,
                  destinations: destinations,
                  extended: context.portalSizeClass == PortalSizeClass.large,
                ),
                const VerticalDivider(width: 1, thickness: 1),
                Expanded(child: body),
              ],
            ),
          )
        : Scaffold(
            appBar: appBar,
            backgroundColor: backgroundColor,
            extendBody: extendBody,
            resizeToAvoidBottomInset: resizeToAvoidBottomInset,
            body: body,
            bottomNavigationBar: PortalBottomNavBar(
              selectedIndex: selectedIndex,
              onDestinationSelected: onDestinationSelected,
              destinations: destinations,
            ),
            floatingActionButton: fab,
          );

    return PopScope(
      canPop: selectedIndex == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) onDestinationSelected(0);
      },
      child: scaffold,
    );
  }
}
