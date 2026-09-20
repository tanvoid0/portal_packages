import 'package:animations/animations.dart';
import 'package:flutter/material.dart';

import '../theme/portal_ui_theme.dart';
import '../tokens/design_tokens.dart';

/// The fleet's default page transition: horizontal shared-axis on a spring.
///
/// `buildPortalTheme` installs one for every platform, so a plain
/// `MaterialPageRoute` (or a `MaterialPage` under Navigator 2.0) slides like
/// [PortalPageTransitions.sharedAxis] with no call-site change. Only routes
/// that consult `pageTransitionsTheme` are reached — dialogs and sheets are
/// `PopupRoute`s with their own transition. [duration] is the theme's
/// `tokens.motion.medium`.
///
/// Root destinations that should fade through instead (a tab bar switching
/// via `pushReplacement`) keep using [PortalPageTransitions.fadeThrough] at
/// the call site — a page transitions theme is per platform, not per route.
class PortalPageTransitionsBuilder extends PageTransitionsBuilder {
  const PortalPageTransitionsBuilder({required this.duration});

  final Duration duration;

  @override
  Duration get transitionDuration => duration;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return PortalPageTransitions._sharedAxis(
      animation,
      secondaryAnimation,
      SharedAxisTransitionType.horizontal,
      child,
    );
  }
}

/// Material motion page routes using the official [animations] package.
///
/// Pass [context] from the navigator so durations resolve from [PortalMotion.medium].
class PortalPageTransitions {
  PortalPageTransitions._();

  static Duration _duration(BuildContext context, Duration? override) {
    return override ?? PortalUiTheme.of(context).tokens.motion.medium;
  }

  static Widget _sharedAxis(
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    SharedAxisTransitionType type,
    Widget child,
  ) {
    return _Curved(
      animation: animation,
      builder: (curved) => SharedAxisTransition(
        animation: curved,
        secondaryAnimation: secondaryAnimation,
        transitionType: type,
        child: child,
      ),
    );
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
      transitionsBuilder: (_, animation, secondaryAnimation, child) =>
          _sharedAxis(animation, secondaryAnimation, type, child),
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
      transitionsBuilder: (_, animation, secondaryAnimation, child) => _Curved(
        animation: animation,
        builder: (curved) => FadeThroughTransition(
          animation: curved,
          secondaryAnimation: secondaryAnimation,
          child: child,
        ),
      ),
    );
  }
}

/// Owns the one [CurvedAnimation] a route's transition needs.
///
/// `buildTransitions` runs once per frame for the route and the one beneath
/// it, and a `CurvedAnimation` built there adds a status listener to the
/// route's animation that only `dispose()` removes — ~36 leaked per push under
/// the theme. The element outlives those rebuilds, so the curve is made once
/// and disposed with the route (the way the SDK's zoom transition does it).
///
/// `effects`, not `spatial`: the animations package asserts on 0..1 and a
/// spatial spring overshoots. Flipped on pop so back decelerates like push
/// did; without it a decelerating spring run backwards is an accelerate-out.
class _Curved extends StatefulWidget {
  const _Curved({required this.animation, required this.builder});

  final Animation<double> animation;
  final Widget Function(Animation<double> curved) builder;

  @override
  State<_Curved> createState() => _CurvedState();
}

class _CurvedState extends State<_Curved> {
  late CurvedAnimation _curved = _make();

  CurvedAnimation _make() => CurvedAnimation(
        parent: widget.animation,
        curve: PortalMotion.effects,
        reverseCurve: PortalMotion.effects.flipped,
      );

  @override
  void didUpdateWidget(_Curved oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animation != widget.animation) {
      _curved.dispose();
      _curved = _make();
    }
  }

  @override
  void dispose() {
    _curved.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(_curved);
}
