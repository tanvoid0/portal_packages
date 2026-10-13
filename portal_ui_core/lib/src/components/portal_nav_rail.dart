import 'package:flutter/material.dart';

import '../theme/portal_ui_theme.dart';
import 'portal_bottom_nav_bar.dart' show PortalNavDestination;
import 'portal_text.dart';

/// Side navigation for wide windows — the tablet/desktop counterpart of
/// [PortalBottomNavBar], driven by the same [PortalNavDestination] list.
///
/// Wraps Flutter's [NavigationRail] rather than re-drawing the floating pill
/// sideways: the rail already gives the selected-indicator well, always-on
/// labels and keyboard focus the fleet wants, themed from [PortalUiTheme] so
/// it inherits each app's world. [PortalTabShell] swaps to this past the
/// expanded breakpoint; apps rarely construct it directly.
class PortalNavRail extends StatelessWidget {
  const PortalNavRail({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
    this.leading,
    this.trailing,
    this.extended = false,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<PortalNavDestination> destinations;

  /// Shown above the destinations (an app mark); below them ([trailing]) a
  /// settings or profile affordance.
  final Widget? leading;
  final Widget? trailing;

  /// Labels beside the icons in a wider rail instead of stacked beneath.
  /// Needs the extra width — [PortalTabShell] only sets it on `large`.
  final bool extended;

  @override
  Widget build(BuildContext context) {
    final portal = PortalUiTheme.of(context);
    return NavigationRail(
      selectedIndex: selectedIndex,
      onDestinationSelected: onDestinationSelected,
      extended: extended,
      // NavigationRail forbids a labelType while extended; the extended rail
      // shows its labels inline instead.
      labelType: extended ? null : NavigationRailLabelType.all,
      backgroundColor: portal.card,
      indicatorColor: portal.muted,
      leading: leading,
      trailing: trailing,
      destinations: [
        for (final d in destinations)
          NavigationRailDestination(
            icon: _badged(d, Icon(d.icon)),
            selectedIcon: _badged(d, Icon(d.selectedIcon ?? d.icon)),
            label: PortalText(d.label),
          ),
      ],
    );
  }

  Widget _badged(PortalNavDestination d, Widget icon) {
    final count = d.badgeCount ?? 0;
    if (count <= 0) return icon;
    return Badge(label: Text('$count'), child: icon);
  }
}
