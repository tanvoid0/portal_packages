/// Serialises the kit's theme values to JSON for the UI kit preview
/// (`docs/ui-kit/data/`), so the preview reads what the Flutter code builds
/// instead of hand-copied hex. Imported only by the `test/kit_export_test.dart`
/// files in ui_core and each app (`scripts/export-kit-data.sh` runs them);
/// deliberately not part of the `portal_ui_core.dart` barrel.
library;

import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'portal_ui_core.dart';

/// Where the export tests write. Empty unless the test run passes
/// `--dart-define=KIT_EXPORT_DIR=<abs path to docs/ui-kit/data>`; each test
/// is `skip: kitExportDir.isEmpty`, so a plain `flutter test` writes nothing.
const String kitExportDir = String.fromEnvironment('KIT_EXPORT_DIR');

/// `#RRGGBB`, or `#AARRGGBB` when not opaque.
String kitHex(Color c) {
  final argb = c.toARGB32();
  final hex = argb.toRadixString(16).padLeft(8, '0').toUpperCase();
  return '#${argb >>> 24 == 0xFF ? hex.substring(2) : hex}';
}

/// Pretty-printed, newline-terminated. Key order is insertion order, which
/// every map here fixes, so a re-run with no code change is a no-op diff.
String kitJson(Object? json) =>
    '${const JsonEncoder.withIndent('  ').convert(_plain(json))}\n';

Object? _plain(Object? v) => switch (v) {
      Color c => kitHex(c),
      List<Object?> l => [for (final x in l) _plain(x)],
      Map<String, Object?> m => {
          for (final e in m.entries) e.key: _plain(e.value),
        },
      _ => v,
    };

/// Colour is left out: token styles carry none, and a theme's roles are
/// coloured from its scheme.
Map<String, Object?> kitTextStyle(TextStyle? s) => {
      'fontFamily': s?.fontFamily,
      'fontSize': s?.fontSize,
      'fontWeight': s?.fontWeight?.value,
      'height': s?.height,
      'letterSpacing': s?.letterSpacing,
      'fontFeatures': {
        for (final f in s?.fontFeatures ?? const <FontFeature>[])
          f.feature: f.value,
      },
    };

List<Object?> _shadows(List<BoxShadow> shadows) => [
      for (final s in shadows)
        {
          'color': s.color,
          'offsetX': s.offset.dx,
          'offsetY': s.offset.dy,
          'blurRadius': s.blurRadius,
          'spreadRadius': s.spreadRadius,
        },
    ];

Map<String, Object?> _spring(SpringDescription s) => {
      'mass': s.mass,
      'stiffness': s.stiffness,
      'damping': s.damping,
      'dampingRatio': double.parse(
        (s.damping / (2 * math.sqrt(s.mass * s.stiffness))).toStringAsFixed(3),
      ),
      'settleMs': PortalSpringCurve(s).duration.inMilliseconds,
    };

Map<String, Object?> _gradient(LinearGradient g) {
  final begin = g.begin.resolve(TextDirection.ltr);
  final end = g.end.resolve(TextDirection.ltr);
  return {
    'begin': [begin.x, begin.y],
    'end': [end.x, end.y],
    'colors': g.colors,
    'stops': g.stops,
  };
}

/// Every value in [t]. Springs are static on [PortalMotion], so they are the
/// same in every preset; gradients need a scheme and live in [kitScheme].
Map<String, Object?> kitTokens(DesignTokens t) {
  final sp = t.spacing;
  final r = t.radii;
  final ts = t.typeScale;
  final st = t.textStyles;
  final m = t.motion;
  return {
    'spacing': {
      'xs': sp.xs, 'sm': sp.sm, 'md': sp.md, 'lg': sp.lg, 'xl': sp.xl, //
      'xxl': sp.xxl, 'xxxl': sp.xxxl, 'grid': sp.grid,
    },
    'radii': {'sm': r.sm, 'md': r.md, 'lg': r.lg, 'xl': r.xl, 'full': r.full},
    'borderWidth': t.borderWidth,
    'minTapTarget': t.minTapTarget,
    'expressiveCorners': t.expressiveCorners,
    'avatarSizes': {
      'sm': t.avatarSizes.sm,
      'md': t.avatarSizes.md,
      'lg': t.avatarSizes.lg,
    },
    'layout': {
      'pageHorizontal': t.layout.pageHorizontal,
      'sectionGap': t.layout.sectionGap,
      'listBottomInset': t.layout.listBottomInset,
    },
    'typeScale': {
      'fontFamily': ts.fontFamily,
      'xs': ts.xs, 'sm': ts.sm, 'md': ts.md, 'lg': ts.lg, 'xl': ts.xl, //
      'xxl': ts.xxl,
    },
    'textStyles': {
      'hero': kitTextStyle(st.hero),
      'display': kitTextStyle(st.display),
      'headline': kitTextStyle(st.headline),
      'title': kitTextStyle(st.title),
      'subtitle': kitTextStyle(st.subtitle),
      'body': kitTextStyle(st.body),
      'caption': kitTextStyle(st.caption),
      'overline': kitTextStyle(st.overline),
    },
    'motion': {
      'durationsMs': {
        'fast': m.fast.inMilliseconds,
        'medium': m.medium.inMilliseconds,
        'slow': m.slow.inMilliseconds,
        'staggerStep': m.staggerStep.inMilliseconds,
        'listRevealDuration': m.listRevealDuration.inMilliseconds,
      },
      'pressScale': m.pressScale,
      'springs': {
        'spatialFast': _spring(PortalMotion.spatialFast),
        'spatialDefault': _spring(PortalMotion.spatialDefault),
        'spatialSlow': _spring(PortalMotion.spatialSlow),
        'effectsFast': _spring(PortalMotion.effectsFast),
        'effectsDefault': _spring(PortalMotion.effectsDefault),
        'effectsSlow': _spring(PortalMotion.effectsSlow),
      },
    },
    'elevation': {
      for (final b in Brightness.values)
        b.name: {
          'soft': _shadows(t.elevation.soft(b)),
          'card': _shadows(t.elevation.card(b)),
          'medium': _shadows(t.elevation.medium(b)),
        },
    },
  };
}

Map<String, Object?> _brightness(ThemeData t, Map<String, Object?> skin) {
  final cs = t.colorScheme;
  final p = t.extension<PortalUiTheme>();
  // What `PortalSemanticColors.of` resolves to at runtime, fallback included
  // (finance does not attach the extension).
  final s = t.extension<PortalSemanticColors>() ??
      PortalSemanticColors.fromScheme(cs);
  return {
    'scaffoldBackgroundColor': t.scaffoldBackgroundColor,
    'colorScheme': {
      'primary': cs.primary,
      'onPrimary': cs.onPrimary,
      'primaryContainer': cs.primaryContainer,
      'onPrimaryContainer': cs.onPrimaryContainer,
      'primaryFixed': cs.primaryFixed,
      'primaryFixedDim': cs.primaryFixedDim,
      'onPrimaryFixed': cs.onPrimaryFixed,
      'onPrimaryFixedVariant': cs.onPrimaryFixedVariant,
      'secondary': cs.secondary,
      'onSecondary': cs.onSecondary,
      'secondaryContainer': cs.secondaryContainer,
      'onSecondaryContainer': cs.onSecondaryContainer,
      'secondaryFixed': cs.secondaryFixed,
      'secondaryFixedDim': cs.secondaryFixedDim,
      'onSecondaryFixed': cs.onSecondaryFixed,
      'onSecondaryFixedVariant': cs.onSecondaryFixedVariant,
      'tertiary': cs.tertiary,
      'onTertiary': cs.onTertiary,
      'tertiaryContainer': cs.tertiaryContainer,
      'onTertiaryContainer': cs.onTertiaryContainer,
      'tertiaryFixed': cs.tertiaryFixed,
      'tertiaryFixedDim': cs.tertiaryFixedDim,
      'onTertiaryFixed': cs.onTertiaryFixed,
      'onTertiaryFixedVariant': cs.onTertiaryFixedVariant,
      'error': cs.error,
      'onError': cs.onError,
      'errorContainer': cs.errorContainer,
      'onErrorContainer': cs.onErrorContainer,
      'surface': cs.surface,
      'onSurface': cs.onSurface,
      'surfaceDim': cs.surfaceDim,
      'surfaceBright': cs.surfaceBright,
      'surfaceContainerLowest': cs.surfaceContainerLowest,
      'surfaceContainerLow': cs.surfaceContainerLow,
      'surfaceContainer': cs.surfaceContainer,
      'surfaceContainerHigh': cs.surfaceContainerHigh,
      'surfaceContainerHighest': cs.surfaceContainerHighest,
      'onSurfaceVariant': cs.onSurfaceVariant,
      'outline': cs.outline,
      'outlineVariant': cs.outlineVariant,
      'shadow': cs.shadow,
      'scrim': cs.scrim,
      'inverseSurface': cs.inverseSurface,
      'onInverseSurface': cs.onInverseSurface,
      'inversePrimary': cs.inversePrimary,
      'surfaceTint': cs.surfaceTint,
    },
    'portal': p == null
        ? null
        : {
            'primary': p.primary,
            'onPrimary': p.onPrimary,
            'secondary': p.secondary,
            'onSecondary': p.onSecondary,
            'surface': p.surface,
            'onSurface': p.onSurface,
            'surfaceVariant': p.surfaceVariant,
            'onSurfaceVariant': p.onSurfaceVariant,
            'outline': p.outline,
            'destructive': p.destructive,
            'onDestructive': p.onDestructive,
            'muted': p.muted,
            'onMuted': p.onMuted,
            'focusRing': p.focusRing,
            'accent': p.accent,
            'onAccent': p.onAccent,
            'card': p.card,
            'onCard': p.onCard,
            'popover': p.popover,
            'onPopover': p.onPopover,
            'border': p.border,
            'input': p.input,
          },
    'semantic': {
      'success': s.success,
      'onSuccess': s.onSuccess,
      'successContainer': s.successContainer,
      'onSuccessContainer': s.onSuccessContainer,
      'warning': s.warning,
      'onWarning': s.onWarning,
      'warningContainer': s.warningContainer,
      'onWarningContainer': s.onWarningContainer,
      'info': s.info,
      'onInfo': s.onInfo,
      'infoContainer': s.infoContainer,
      'onInfoContainer': s.onInfoContainer,
      'danger': s.danger,
      'onDanger': s.onDanger,
      'dangerContainer': s.dangerContainer,
      'onDangerContainer': s.onDangerContainer,
    },
    'gradients': p == null
        ? null
        : {
            'surfaceSheen': _gradient(p.tokens.gradients.surfaceSheen(cs)),
            'accent': _gradient(p.tokens.gradients.accent(cs)),
            'imageScrim': _gradient(p.tokens.gradients.imageScrim(cs)),
          },
    'skin': skin,
  };
}

/// One app's themes, built by the app's own theme functions. [skin] returns
/// the app's own colour roles for a theme (Colors, lists and maps of them).
Map<String, Object?> kitScheme({
  required String app,
  required String generatedBy,
  required ThemeData light,
  ThemeData? dark,
  Map<String, Object?> Function(ThemeData theme)? skin,
}) {
  final themes = {'light': light, if (dark != null) 'dark': dark};
  final tt = light.textTheme;
  final tokens = light.extension<PortalUiTheme>()?.tokens;
  return {
    'app': app,
    'generatedBy': generatedBy,
    'brightnesses': themes.keys.toList(),
    'fonts': {
      'body': tt.bodyLarge?.fontFamily,
      'display': tt.displayLarge?.fontFamily,
    },
    'tokens': tokens == null ? null : kitTokens(tokens),
    'textTheme': {
      'displayLarge': kitTextStyle(tt.displayLarge),
      'displayMedium': kitTextStyle(tt.displayMedium),
      'displaySmall': kitTextStyle(tt.displaySmall),
      'headlineLarge': kitTextStyle(tt.headlineLarge),
      'headlineMedium': kitTextStyle(tt.headlineMedium),
      'headlineSmall': kitTextStyle(tt.headlineSmall),
      'titleLarge': kitTextStyle(tt.titleLarge),
      'titleMedium': kitTextStyle(tt.titleMedium),
      'titleSmall': kitTextStyle(tt.titleSmall),
      'bodyLarge': kitTextStyle(tt.bodyLarge),
      'bodyMedium': kitTextStyle(tt.bodyMedium),
      'bodySmall': kitTextStyle(tt.bodySmall),
      'labelLarge': kitTextStyle(tt.labelLarge),
      'labelMedium': kitTextStyle(tt.labelMedium),
      'labelSmall': kitTextStyle(tt.labelSmall),
    },
    for (final e in themes.entries)
      e.key: _brightness(e.value, skin?.call(e.value) ?? const {}),
  };
}
