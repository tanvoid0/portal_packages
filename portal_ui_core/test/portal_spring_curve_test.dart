import 'package:flutter_test/flutter_test.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

void main() {
  final samples = [for (var i = 1; i < 200; i++) i / 200];

  test('spatialDefault lands on 1', () {
    final curve = PortalSpringCurve(PortalMotion.spatialDefault);
    // transformInternal: Curve.transform short-circuits t == 1.0 to 1.0.
    expect(curve.transformInternal(1.0), closeTo(1.0, 1e-3));
    expect(curve.duration, greaterThan(Duration.zero));
  });

  test('spatialFast overshoots; effects never does', () {
    final fast = PortalSpringCurve(PortalMotion.spatialFast);
    expect(samples.map(fast.transform).any((x) => x > 1), isTrue);
    expect(
      samples.map(PortalMotion.effects.transform).every((x) => x >= 0 && x <= 1),
      isTrue,
    );
  });

  test('easing-era names are spring-backed and compare by value', () {
    const motion = PortalMotion();
    expect(motion.standard, PortalMotion.effects);
    expect(motion.emphasized, PortalSpringCurve(PortalMotion.spatialDefault));
  });
}
