import 'package:flutter/services.dart';

/// The haptic a control asks for, by name rather than by method so a widget
/// can take it as a parameter (`PortalPressable(haptic: …)`).
enum PortalHapticKind { selection, light, medium, heavy, success, warning, error }

/// The fleet's haptic vocabulary over the stdlib [HapticFeedback] — one place
/// to switch it off, one set of patterns so "success" feels the same in every
/// app.
///
/// [enabled] is global on purpose: haptics are a device preference, not a
/// per-widget one. `PortalThemeConfig.haptics` sets it when the theme builds.
abstract final class PortalHaptics {
  /// Owned by `PortalThemeConfig.haptics` when a config is in use: every
  /// `light()`/`dark()` rewrites it, so a runtime toggle must rebuild the
  /// theme via `copyWith(haptics:)` — a direct write here is overwritten by
  /// the next theme build.
  static bool enabled = true;

  /// Gap between the taps of a compound pattern. Short enough to read as one
  /// gesture, long enough that the motor renders two distinct pulses.
  static const gap = Duration(milliseconds: 40);

  static Future<void> selection() => _fire(HapticFeedback.selectionClick);
  static Future<void> light() => _fire(HapticFeedback.lightImpact);
  static Future<void> medium() => _fire(HapticFeedback.mediumImpact);
  static Future<void> heavy() => _fire(HapticFeedback.heavyImpact);

  /// Light then medium: a rising "done".
  static Future<void> success() => _sequence([light, medium]);

  /// Medium twice: "look at this".
  static Future<void> warning() => _sequence([medium, medium]);

  /// Heavy then two lights: a thud and a stumble.
  static Future<void> error() => _sequence([heavy, light, light]);

  static Future<void> play(PortalHapticKind kind) => switch (kind) {
        PortalHapticKind.selection => selection(),
        PortalHapticKind.light => light(),
        PortalHapticKind.medium => medium(),
        PortalHapticKind.heavy => heavy(),
        PortalHapticKind.success => success(),
        PortalHapticKind.warning => warning(),
        PortalHapticKind.error => error(),
      };

  static Future<void> _fire(Future<void> Function() haptic) =>
      enabled ? haptic() : Future.value();

  static Future<void> _sequence(List<Future<void> Function()> steps) async {
    if (!enabled) return;
    for (var i = 0; i < steps.length; i++) {
      if (i > 0) await Future<void>.delayed(gap);
      await steps[i]();
    }
  }
}
