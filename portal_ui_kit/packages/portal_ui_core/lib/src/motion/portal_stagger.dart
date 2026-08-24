import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

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

    return child
        .animate()
        .fadeIn(duration: reveal, delay: delay * index)
        .slideY(begin: slideBegin, duration: reveal, delay: delay * index);
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
