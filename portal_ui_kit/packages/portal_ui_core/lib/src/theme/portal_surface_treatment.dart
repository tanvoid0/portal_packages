import 'package:flutter/foundation.dart';

/// How Portal components render elevated panels and containers.
enum PortalSurfaceTreatment {
  /// Opaque surfaces — Material, Clean, Atomic.
  solid,

  /// Frosted glass with backdrop blur, tint, and specular edge.
  glass,
}

/// Tunable glassmorphism parameters carried on [PortalUiTheme].
@immutable
class PortalGlassStyle {
  const PortalGlassStyle({
    this.blurSigma = 16,
    this.tintAlpha = 0.48,
    this.borderAlpha = 0.38,
    this.specularAlpha = 0.22,
  });

  final double blurSigma;
  final double tintAlpha;
  final double borderAlpha;
  final double specularAlpha;

  static const PortalGlassStyle defaults = PortalGlassStyle();

  static PortalGlassStyle forBrightness(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return PortalGlassStyle(
      blurSigma: isDark ? 20 : 14,
      tintAlpha: isDark ? 0.36 : 0.52,
      borderAlpha: isDark ? 0.42 : 0.32,
      specularAlpha: isDark ? 0.14 : 0.26,
    );
  }
}
