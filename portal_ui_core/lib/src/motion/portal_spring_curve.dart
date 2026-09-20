import 'package:flutter/animation.dart';
import 'package:flutter/physics.dart';

/// A [Curve] that plays a [SpringSimulation] from 0 to 1, so the implicit
/// animations (`AnimatedContainer`, `AnimatedScale`, `TweenAnimationBuilder`)
/// can spring. Pass [duration] as the animation's duration: it is the time the
/// spring takes to settle, and `t = 1` maps onto it.
///
/// An under-damped spring (ratio < 1) overshoots past 1 — clamp before handing
/// the value to anything that asserts on `0..1`, such as `Opacity`, or use an
/// effects spring (ratio 1), which never passes its target.
class PortalSpringCurve extends Curve {
  PortalSpringCurve(this.spring);

  final SpringDescription spring;

  late final SpringSimulation _sim = SpringSimulation(spring, 0, 1, 0);

  /// Time for the spring to come to rest within [Tolerance.defaultTolerance].
  late final Duration duration = _settle();

  Duration _settle() {
    var t = 0.0;
    // ponytail: frame-step sampling; the 10 s cap keeps an undamped spring
    // from looping forever.
    while (!_sim.isDone(t) && t < 10) {
      t += 1 / 60;
    }
    return Duration(microseconds: (t * Duration.microsecondsPerSecond).round());
  }

  @override
  double transformInternal(double t) =>
      _sim.x(t * duration.inMicroseconds / Duration.microsecondsPerSecond);

  // Value equality so a curve built in `build` does not make every
  // ImplicitlyAnimatedWidget rebuild its CurvedAnimation each frame.
  @override
  bool operator ==(Object other) =>
      other is PortalSpringCurve &&
      other.spring.mass == spring.mass &&
      other.spring.stiffness == spring.stiffness &&
      other.spring.damping == spring.damping;

  @override
  int get hashCode => Object.hash(spring.mass, spring.stiffness, spring.damping);
}
