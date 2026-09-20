import 'package:flutter/material.dart';

import '../theme/portal_ui_theme.dart';
import '../tokens/portal_radii_utils.dart';

/// A [Hero] whose flight keeps rounded corners.
///
/// A bare `Hero` shows the *destination* widget for the whole flight, so a
/// card lifting off toward a full-bleed page snaps to square corners on the
/// first frame. This shuttle clips the flight to a radius that lerps from the
/// departing end's [borderRadius] to the arriving end's, both ways.
///
/// [borderRadius] is the corner at *this* end: the card radius (`radii.lg`)
/// when omitted; `BorderRadius.zero` on a full-bleed destination. Use
/// `PortalCard(heroTag:)` to get the card's own radius for free.
class PortalHero extends StatelessWidget {
  const PortalHero({
    super.key,
    required this.tag,
    required this.child,
    this.borderRadius,
  });

  final Object tag;
  final Widget child;
  final BorderRadius? borderRadius;

  static BorderRadius _radiusAt(BuildContext heroContext) {
    final hero = heroContext.findAncestorWidgetOfExactType<PortalHero>();
    final radii = PortalUiTheme.of(heroContext).tokens.radii;
    return hero?.borderRadius ?? radii.circular();
  }

  // Same begin/end flip as Flutter's default shuttle: the animation runs 0→1
  // on push and 1→0 on pop, and `from` is always the route being left.
  static Widget _shuttle(
    BuildContext flightContext,
    Animation<double> animation,
    HeroFlightDirection direction,
    BuildContext fromContext,
    BuildContext toContext,
  ) {
    final from = _radiusAt(fromContext);
    final to = _radiusAt(toContext);
    final push = direction == HeroFlightDirection.push;
    final radius = BorderRadiusTween(
      begin: push ? from : to,
      end: push ? to : from,
    ).animate(animation);
    // The flight lives in the Navigator overlay, under MaterialApp's
    // error-text DefaultTextStyle; a child with no Material of its own (a hero
    // card, a bare Text) would fly yellow-underlined without this wrap.
    final child = Material(
      type: MaterialType.transparency,
      child: (toContext.widget as Hero).child,
    );
    return AnimatedBuilder(
      animation: animation,
      builder: (_, __) => ClipRRect(borderRadius: radius.value!, child: child),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Hero(tag: tag, flightShuttleBuilder: _shuttle, child: child);
  }
}
