import 'package:flutter/material.dart';

import '../state/portal_load_state.dart';
import '../theme/portal_ui_theme.dart';

/// Crossfades [child] whenever [state] changes instead of swapping it in on
/// the same frame. Every `switch (load) { ... }` body in the fleet used to
/// teleport straight from a skeleton to data (or into an error/empty state) —
/// wrap that switch's result in this once per screen.
///
/// Keys the transition on [state] itself, so a `loading` -> `data` swap (or
/// any other state change) always crossfades even when two different states
/// happen to build visually similar widgets. Skips the animation entirely
/// when the platform asks to reduce motion, same guard as [PortalStaggeredChild].
class PortalLoadFade extends StatelessWidget {
  const PortalLoadFade({super.key, required this.state, required this.child});

  final PortalLoadState state;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return child;

    final motion = PortalUiTheme.of(context).tokens.motion;
    return AnimatedSwitcher(
      duration: motion.medium,
      switchInCurve: motion.standard,
      switchOutCurve: motion.standard,
      child: KeyedSubtree(key: ValueKey(state), child: child),
    );
  }
}
