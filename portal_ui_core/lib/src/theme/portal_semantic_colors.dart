import 'package:flutter/material.dart';
import 'package:material_color_utilities/material_color_utilities.dart';

/// Status colours the [ColorScheme] does not carry: success, warning, info —
/// plus `danger*`, which mirrors `ColorScheme.error*` so every status reads
/// from one place. Four M3 roles each (`x`, `onX`, `xContainer`,
/// `onXContainer`), tones matching the scheme's own `error` set.
///
/// Attached to [ThemeData.extensions] by `buildPortalTheme`; read with [of].
/// Defaults come from [fromScheme]: fixed hues (green 145°, amber 65°, blue
/// 215°). Success and info are rotated up to 15° toward the scheme's primary
/// by [Blend.harmonize], so they sit inside the brand instead of fighting it.
/// Warning is not harmonised and its hue is held at amber: a primary in
/// blue/violet or red pulled it to within 20° of the app's error, and a
/// warning that reads as negative is worse than one outside the brand (K3).
/// Override per brightness through the existing
/// `PortalThemeConfig.extensionsBuilder` — a later extension of the same type
/// replaces the default:
///
/// ```dart
/// extensionsBuilder: (ctx) => [
///   ctx.theme.extension<PortalSemanticColors>()!.copyWith(
///     info: ctx.brightness == Brightness.dark ? Colors.cyan : Colors.indigo,
///   ),
/// ],
/// ```
@immutable
class PortalSemanticColors extends ThemeExtension<PortalSemanticColors> {
  const PortalSemanticColors({
    required this.success,
    required this.onSuccess,
    required this.successContainer,
    required this.onSuccessContainer,
    required this.warning,
    required this.onWarning,
    required this.warningContainer,
    required this.onWarningContainer,
    required this.info,
    required this.onInfo,
    required this.infoContainer,
    required this.onInfoContainer,
    required this.danger,
    required this.onDanger,
    required this.dangerContainer,
    required this.onDangerContainer,
  });

  /// Harmonised defaults for [scheme]'s brightness and primary.
  factory PortalSemanticColors.fromScheme(ColorScheme scheme) {
    final dark = scheme.brightness == Brightness.dark;
    final primary = scheme.primary.toARGB32();
    // M3 tone recipe — the same one ColorScheme.fromSeed uses for error.
    final (tone, onTone, container, onContainer) =
        dark ? (80, 20, 30, 90) : (40, 100, 90, 10);

    TonalPalette palette(double hue, {bool harmonise = true}) {
      final seed = Hct.from(hue, _chroma, 40);
      if (!harmonise) return TonalPalette.of(seed.hue, seed.chroma);
      final hct = Hct.fromInt(Blend.harmonize(seed.toInt(), primary));
      return TonalPalette.of(hct.hue, hct.chroma);
    }

    final green = palette(_greenHue);
    final amber = palette(_amberHue, harmonise: false);
    final blue = palette(_blueHue);

    return PortalSemanticColors(
      success: Color(green.get(tone)),
      onSuccess: Color(green.get(onTone)),
      successContainer: Color(green.get(container)),
      onSuccessContainer: Color(green.get(onContainer)),
      warning: Color(amber.get(tone)),
      onWarning: Color(amber.get(onTone)),
      warningContainer: Color(amber.get(container)),
      onWarningContainer: Color(amber.get(onContainer)),
      info: Color(blue.get(tone)),
      onInfo: Color(blue.get(onTone)),
      infoContainer: Color(blue.get(container)),
      onInfoContainer: Color(blue.get(onContainer)),
      danger: scheme.error,
      onDanger: scheme.onError,
      dangerContainer: scheme.errorContainer,
      onDangerContainer: scheme.onErrorContainer,
    );
  }

  static const double _greenHue = 145;

  /// Amber, far enough from every app's error to never read as negative:
  /// 65° clears the closest (journey/lifestyle, 36°) by 28° in HCT. Not
  /// harmonised — see the class doc. Pinned by
  /// `test/portal_semantic_colors_test.dart`.
  static const double _amberHue = 65;
  static const double _blueHue = 215;
  static const double _chroma = 48;

  final Color success;
  final Color onSuccess;
  final Color successContainer;
  final Color onSuccessContainer;
  final Color warning;
  final Color onWarning;
  final Color warningContainer;
  final Color onWarningContainer;
  final Color info;
  final Color onInfo;
  final Color infoContainer;
  final Color onInfoContainer;

  /// Alias of `ColorScheme.error`; kept here so status code reads one type.
  final Color danger;
  final Color onDanger;
  final Color dangerContainer;
  final Color onDangerContainer;

  /// The theme's semantic colours, or harmonised defaults from its
  /// [ColorScheme] when the theme was not built by `buildPortalTheme`.
  static PortalSemanticColors of(BuildContext context) {
    final theme = Theme.of(context);
    return theme.extension<PortalSemanticColors>() ??
        PortalSemanticColors.fromScheme(theme.colorScheme);
  }

  @override
  PortalSemanticColors copyWith({
    Color? success,
    Color? onSuccess,
    Color? successContainer,
    Color? onSuccessContainer,
    Color? warning,
    Color? onWarning,
    Color? warningContainer,
    Color? onWarningContainer,
    Color? info,
    Color? onInfo,
    Color? infoContainer,
    Color? onInfoContainer,
    Color? danger,
    Color? onDanger,
    Color? dangerContainer,
    Color? onDangerContainer,
  }) {
    return PortalSemanticColors(
      success: success ?? this.success,
      onSuccess: onSuccess ?? this.onSuccess,
      successContainer: successContainer ?? this.successContainer,
      onSuccessContainer: onSuccessContainer ?? this.onSuccessContainer,
      warning: warning ?? this.warning,
      onWarning: onWarning ?? this.onWarning,
      warningContainer: warningContainer ?? this.warningContainer,
      onWarningContainer: onWarningContainer ?? this.onWarningContainer,
      info: info ?? this.info,
      onInfo: onInfo ?? this.onInfo,
      infoContainer: infoContainer ?? this.infoContainer,
      onInfoContainer: onInfoContainer ?? this.onInfoContainer,
      danger: danger ?? this.danger,
      onDanger: onDanger ?? this.onDanger,
      dangerContainer: dangerContainer ?? this.dangerContainer,
      onDangerContainer: onDangerContainer ?? this.onDangerContainer,
    );
  }

  @override
  PortalSemanticColors lerp(
    covariant ThemeExtension<PortalSemanticColors>? other,
    double t,
  ) {
    if (other is! PortalSemanticColors) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return PortalSemanticColors(
      success: l(success, other.success),
      onSuccess: l(onSuccess, other.onSuccess),
      successContainer: l(successContainer, other.successContainer),
      onSuccessContainer: l(onSuccessContainer, other.onSuccessContainer),
      warning: l(warning, other.warning),
      onWarning: l(onWarning, other.onWarning),
      warningContainer: l(warningContainer, other.warningContainer),
      onWarningContainer: l(onWarningContainer, other.onWarningContainer),
      info: l(info, other.info),
      onInfo: l(onInfo, other.onInfo),
      infoContainer: l(infoContainer, other.infoContainer),
      onInfoContainer: l(onInfoContainer, other.onInfoContainer),
      danger: l(danger, other.danger),
      onDanger: l(onDanger, other.onDanger),
      dangerContainer: l(dangerContainer, other.dangerContainer),
      onDangerContainer: l(onDangerContainer, other.onDangerContainer),
    );
  }
}
