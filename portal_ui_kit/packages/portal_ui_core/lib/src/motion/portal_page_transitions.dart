import 'package:animations/animations.dart';
import 'package:flutter/material.dart';

import '../theme/portal_ui_theme.dart';

/// Material motion page routes using the official [animations] package.
///
/// Pass [context] from the navigator so durations resolve from [PortalMotion.medium].
class PortalPageTransitions {
  PortalPageTransitions._();

  static Duration _duration(BuildContext context, Duration? override) {
    return override ?? PortalUiTheme.of(context).tokens.motion.medium;
  }

  /// Horizontal, vertical, or scaled shared-axis transition between pages.
  static Route<T> sharedAxis<T>({
    required BuildContext context,
    required Widget page,
    SharedAxisTransitionType type = SharedAxisTransitionType.horizontal,
    Duration? duration,
    RouteSettings? settings,
  }) {
    final d = _duration(context, duration);
    return PageRouteBuilder<T>(
      settings: settings,
      transitionDuration: d,
      reverseTransitionDuration: d,
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, animation, secondaryAnimation, child) {
        return SharedAxisTransition(
          animation: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
          secondaryAnimation: secondaryAnimation,
          transitionType: type,
          child: child,
        );
      },
    );
  }

  /// Fade-through transition suited to switching between unrelated destinations.
  static Route<T> fadeThrough<T>({
    required BuildContext context,
    required Widget page,
    Duration? duration,
    RouteSettings? settings,
  }) {
    final d = _duration(context, duration);
    return PageRouteBuilder<T>(
      settings: settings,
      transitionDuration: d,
      reverseTransitionDuration: d,
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, animation, secondaryAnimation, child) {
        return FadeThroughTransition(
          animation: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
          secondaryAnimation: secondaryAnimation,
          child: child,
        );
      },
    );
  }
}
