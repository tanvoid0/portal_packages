import 'package:flutter/services.dart';

/// The haptic a control asks for, by name rather than by method so a widget
/// can take it as a parameter (`PortalPressable(haptic: …)`).
enum PortalHapticKind { selection, light, medium, heavy, success, warning, error }

/// How strongly a fired haptic renders. [full] plays the kind's own pattern;
/// [light] flattens every kind to one soft tap, for a user who wants the
/// confirmation without the thump.
enum PortalHapticIntensity { light, full }

/// The fleet's haptic vocabulary over the stdlib [HapticFeedback] — one place
/// to switch it off, one set of patterns so "success" feels the same in every
/// app.
///
/// [enabled] and [intensity] are global on purpose: haptics are a device
/// preference, not a per-widget one. Set them from the user's own setting
/// (`PortalSettingsPage`'s Haptics row persists it) rather than per screen.
abstract final class PortalHaptics {
  /// Settings-driven; defaults on. `PortalThemeConfig.haptics`, when given
  /// explicitly, also writes this — leave that param unset so a theme rebuild
  /// (e.g. switching accent colour) does not stomp the user's choice.
  static bool enabled = true;

  /// Settings-driven; defaults to [PortalHapticIntensity.full].
  static PortalHapticIntensity intensity = PortalHapticIntensity.full;

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

  static Future<void> _fire(Future<void> Function() haptic) {
    if (!enabled) return Future.value();
    if (intensity == PortalHapticIntensity.light) {
      return HapticFeedback.selectionClick();
    }
    return haptic();
  }

  /// A compound pattern (success/warning/error) collapses to its single
  /// lightest tap at [PortalHapticIntensity.light] rather than playing every
  /// step quietly — the point of "light" is less buzzing, not the same buzz
  /// pattern turned down.
  static Future<void> _sequence(List<Future<void> Function()> steps) async {
    if (!enabled) return;
    if (intensity == PortalHapticIntensity.light) {
      await HapticFeedback.selectionClick();
      return;
    }
    for (var i = 0; i < steps.length; i++) {
      if (i > 0) await Future<void>.delayed(gap);
      await steps[i]();
    }
  }
}
