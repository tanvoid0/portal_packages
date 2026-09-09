import 'package:flutter/material.dart';

import '../theme/portal_ui_theme.dart';

/// Wraps [child] with a list reveal animation (fade + slide) when motion is enabled.
class PortalStaggeredChild extends StatelessWidget {
  const PortalStaggeredChild({
    required this.child,
    super.key,
    this.index = 0,
    this.baseDelay,
    this.duration,
    this.slideBegin = 0.06,
  });

  final Widget child;
  final int index;

  /// Overrides [PortalMotion.staggerStep] between items.
  final Duration? baseDelay;

  /// Overrides [PortalMotion.listRevealDuration].
  final Duration? duration;

  /// Vertical slide offset fraction at start (0.06 = 6% of height).
  final double slideBegin;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) {
      return child;
    }

    final motion = PortalUiTheme.of(context).tokens.motion;
    final delay = baseDelay ?? motion.staggerStep;
    final reveal = duration ?? motion.listRevealDuration;

    // The stagger is an Interval inside one animation rather than a real delay
    // because the tween's target never moves: a reorder changes this widget's
    // index, and therefore its duration and curve, but not its `end`, so
    // TweenAnimationBuilder carries on instead of restarting. flutter_animate
    // folded the delay into its own duration and replayed whenever that
    // duration changed — which meant ticking one row off re-revealed every row
    // beneath it.
    final step = delay * index;
    final total = reveal + step;
    final startFraction = total.inMicroseconds == 0
        ? 0.0
        : step.inMicroseconds / total.inMicroseconds;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: total,
      curve: Interval(startFraction, 1, curve: motion.standard),
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, (1 - t) * slideBegin * 100),
          child: child,
        ),
      ),
      child: child,
    );
  }
}

/// Applies staggered reveal to each child in [children].
List<Widget> wrapStaggeredList(
  List<Widget> children, {
  Duration? baseDelay,
  Duration? duration,
  double slideBegin = 0.06,
}) {
  return [
    for (var i = 0; i < children.length; i++)
      PortalStaggeredChild(
        index: i,
        baseDelay: baseDelay,
        duration: duration,
        slideBegin: slideBegin,
        child: children[i],
      ),
  ];
}
