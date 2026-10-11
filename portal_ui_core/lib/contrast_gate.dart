/// The contrast floors the kit holds, as a function every app's test can call
/// with its own themes (F6). ui_core's `contrast_gate_test.dart` runs it over
/// `PortalThemeCatalog`; each app runs it over the scheme it hand-writes, so a
/// hand-tuned value cannot drift under the floor again.
///
/// Pure Dart on purpose — no `flutter_test` — so it can live in `lib/` beside
/// `kit_export.dart`. The caller does the asserting:
///
/// ```dart
/// test('finance schemes clear the contrast floors', () {
///   final failures = portalContrastFailures(
///     app: 'finance', light: AppTheme.light(), dark: AppTheme.dark(),
///   );
///   expect(failures, isEmpty, reason: describeContrastFailures(failures));
/// });
/// ```
library;

import 'package:flutter/material.dart';

import 'portal_ui_core.dart';

/// Text reads at 4.5:1 (WCAG AA for body sizes).
const double kPortalTextContrast = 4.5;

/// An icon, outline, focus ring or control border reads at 3:1 against the
/// surface behind it (WCAG 1.4.11).
const double kPortalNonTextContrast = 3.0;

/// [fg] kept readable on [bg]: drawn as is when it already clears AA text
/// ([kPortalTextContrast]), else stepped toward [toward] (the page ink)
/// until it does. A brand primary that is fine on a button (3.9:1 on a grey
/// page) is too light for a text-only action.
Color portalReadable(Color fg, Color bg, Color toward) {
  var c = fg;
  for (var i = 1; i <= 10 && portalContrastRatio(c, bg) < kPortalTextContrast; i++) {
    c = Color.lerp(fg, toward, i / 10)!;
  }
  return c;
}

/// How far a selection capsule must stand off the pill it sits on. The
/// capsule is reinforcement, not a slab, so it only needs to clear this —
/// not full text contrast.
const double portalWellContrast = 1.5;

/// A selection capsule that can actually be seen on [pill]: a wash of
/// [mark], deepened until it clears [portalWellContrast].
Color portalWellOn(Color pill, Color mark) {
  var c = pill;
  for (var a = 8; a <= 44 && portalContrastRatio(c, pill) < portalWellContrast; a += 4) {
    c = Color.alphaBlend(mark.withValues(alpha: a / 100), pill);
  }
  return c;
}

/// True when two fills would be taken for each other at badge size: the
/// same hue family, near enough in tone. Hue is what carries the meaning
/// here, so it is the hue that is compared.
bool portalTooAlike(Color a, Color b) {
  final x = HSVColor.fromColor(a), y = HSVColor.fromColor(b);
  final d = (x.hue - y.hue).abs();
  return (d < 40 || d > 320) && (x.saturation > .05 || y.saturation > .05);
}

/// A fill for a state that is *not* done, guaranteed not to be read as
/// done. [done] is the hue to steer away from; [accent] stands in when
/// [pending] is too alike, and [plain] (a neutral fill) when [accent] is too.
Color portalNotDone(Color pending, Color done, Color accent, Color plain) {
  if (!portalTooAlike(pending, done)) return pending;
  if (!portalTooAlike(accent, done)) return accent;
  return plain;
}

/// A neutral fill (secondary button, neutral badge, neutral prompt): the
/// high tone, or the card's where the surface under it is already high —
/// a grouped light page draws neutral fills on `portal.card`.
Color neutralFill(BuildContext context) {
  final cs = Theme.of(context).colorScheme;
  return Material.maybeOf(context)?.color == cs.surfaceContainerHigh
      ? PortalUiTheme.of(context).card
      : cs.surfaceContainerHigh;
}

/// Tint alphas for [categoryColors]: a category colour reads as a tint of
/// the surface, not a solid fill.
const double _tintLight = .18;
const double _tintDark = .32;
const double _glyphContrast = 3;

/// (fill, glyph) for a category colour [c]: [c] tinted over the surface, and
/// a glyph from [c] toward onSurface in tenths until it holds
/// [_glyphContrast] (non-text contrast) on that tint.
(Color, Color) categoryColors(BuildContext context, Color c) {
  final cs = Theme.of(context).colorScheme;
  final dark = Theme.of(context).brightness == Brightness.dark;
  final fill = Color.alphaBlend(
    c.withValues(alpha: dark ? _tintDark : _tintLight),
    cs.surface,
  );
  var ink = c;
  for (var i = 1;
      i <= 10 && portalContrastRatio(ink, fill) < _glyphContrast;
      i++) {
    ink = Color.lerp(c, cs.onSurface, i / 10)!;
  }
  return (fill, ink);
}

/// WCAG 2.x contrast ratio between two opaque colours.
double portalContrastRatio(Color fg, Color bg) {
  final a = fg.computeLuminance(), b = bg.computeLuminance();
  final (hi, lo) = a > b ? (a, b) : (b, a);
  return (hi + 0.05) / (lo + 0.05);
}

String _hex(Color c) =>
    '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

/// One pair that reads under its floor. Fix it in the palette it came from —
/// never by lowering the floor here.
class ContrastFailure {
  const ContrastFailure({
    required this.scheme,
    required this.role,
    required this.foreground,
    required this.background,
    required this.ratio,
    required this.floor,
  });

  /// e.g. `finance light`.
  final String scheme;

  /// e.g. `onSurfaceVariant on surfaceContainerHighest`.
  final String role;

  final Color foreground;
  final Color background;
  final double ratio;
  final double floor;

  @override
  String toString() => '$scheme · $role: ${_hex(foreground)} on '
      '${_hex(background)} is ${ratio.toStringAsFixed(2)}:1, under $floor';
}

/// A reason string for `expect(failures, isEmpty, reason: …)`.
String describeContrastFailures(List<ContrastFailure> failures) =>
    failures.isEmpty
        ? 'no contrast failures'
        : '${failures.length} pair(s) under the floor:\n'
            '${failures.map((f) => '  $f').join('\n')}';

/// Every pair in [theme] that reads under its floor, named [scheme] in the
/// messages. Pairs whose extension is absent are skipped, not failed.
List<ContrastFailure> portalThemeContrastFailures(
  ThemeData theme, {
  required String scheme,
}) {
  final cs = theme.colorScheme;
  final semantic = theme.extension<PortalSemanticColors>();
  final portal = theme.extension<PortalUiTheme>();
  final failures = <ContrastFailure>[];

  void gate(String role, Color fg, Color bg, double floor) {
    final ratio = portalContrastRatio(fg, bg);
    if (ratio < floor) {
      failures.add(ContrastFailure(
        scheme: scheme,
        role: role,
        foreground: fg,
        background: bg,
        ratio: ratio,
        floor: floor,
      ));
    }
  }

  final text = <String, (Color, Color)>{
    'onPrimary': (cs.onPrimary, cs.primary),
    'onPrimaryContainer': (cs.onPrimaryContainer, cs.primaryContainer),
    'onSecondary': (cs.onSecondary, cs.secondary),
    'onSecondaryContainer': (cs.onSecondaryContainer, cs.secondaryContainer),
    'onTertiary': (cs.onTertiary, cs.tertiary),
    'onTertiaryContainer': (cs.onTertiaryContainer, cs.tertiaryContainer),
    'onError': (cs.onError, cs.error),
    'onErrorContainer': (cs.onErrorContainer, cs.errorContainer),
    'onInverseSurface': (cs.onInverseSurface, cs.inverseSurface),
    if (semantic != null) ...{
      'onSuccess': (semantic.onSuccess, semantic.success),
      'onSuccessContainer':
          (semantic.onSuccessContainer, semantic.successContainer),
      'onWarning': (semantic.onWarning, semantic.warning),
      'onWarningContainer':
          (semantic.onWarningContainer, semantic.warningContainer),
      'onInfo': (semantic.onInfo, semantic.info),
      'onInfoContainer': (semantic.onInfoContainer, semantic.infoContainer),
    },
    if (portal != null) ...{
      'onCard': (portal.onCard, portal.card),
      'onPopover': (portal.onPopover, portal.popover),
      'onMuted': (portal.onMuted, portal.muted),
      'onAccent': (portal.onAccent, portal.accent),
    },
  };
  for (final MapEntry(key: role, value: (fg, bg)) in text.entries) {
    gate(role, fg, bg, kPortalTextContrast);
  }

  // Body text lands on the page and on every raised tone.
  final surfaces = <String, Color>{
    'surface': cs.surface,
    'surfaceContainerLowest': cs.surfaceContainerLowest,
    'surfaceContainerLow': cs.surfaceContainerLow,
    'surfaceContainer': cs.surfaceContainer,
    'surfaceContainerHigh': cs.surfaceContainerHigh,
    'surfaceContainerHighest': cs.surfaceContainerHighest,
    'scaffold': theme.scaffoldBackgroundColor,
  };
  for (final MapEntry(key: on, value: bg) in surfaces.entries) {
    gate('onSurface on $on', cs.onSurface, bg, kPortalTextContrast);
    // Muted text is still text: hints, placeholders, captions.
    gate('onSurfaceVariant on $on', cs.onSurfaceVariant, bg,
        kPortalTextContrast);
  }

  gate('outline', cs.outline, cs.surface, kPortalNonTextContrast);
  gate('outline on surfaceContainerHighest', cs.outline,
      cs.surfaceContainerHighest, kPortalNonTextContrast);
  gate('primary as a control', cs.primary, cs.surface, kPortalNonTextContrast);
  if (portal != null) {
    gate('focusRing', portal.focusRing, cs.surface, kPortalNonTextContrast);
  }
  if (semantic != null) {
    gate('success', semantic.success, cs.surface, kPortalNonTextContrast);
    gate('warning', semantic.warning, cs.surface, kPortalNonTextContrast);
    gate('info', semantic.info, cs.surface, kPortalNonTextContrast);
    gate('danger', semantic.danger, cs.surface, kPortalNonTextContrast);
  }
  return failures;
}

/// [portalThemeContrastFailures] over an app's light and dark themes.
List<ContrastFailure> portalContrastFailures({
  required String app,
  required ThemeData light,
  required ThemeData dark,
}) =>
    [
      ...portalThemeContrastFailures(light, scheme: '$app light'),
      ...portalThemeContrastFailures(dark, scheme: '$app dark'),
    ];
