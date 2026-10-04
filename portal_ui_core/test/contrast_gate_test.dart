import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

/// WCAG 2.x contrast ratio.
double _contrast(Color fg, Color bg) {
  final a = fg.computeLuminance(), b = bg.computeLuminance();
  final (hi, lo) = a > b ? (a, b) : (b, a);
  return (hi + 0.05) / (lo + 0.05);
}

String _hex(Color c) =>
    '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

/// F2 — the floors our docs asserted without numbers. Text reads at 4.5:1;
/// an icon, outline, focus ring or control border reads at 3:1 against the
/// surface behind it. A palette that fails is fixed in its own values, never
/// waived here.
void main() {
  group('contrast gate', () {
    for (final palette in PortalThemeCatalog.all) {
      final modes = palette.toConfig().build();
      for (final brightness in Brightness.values) {
        final theme =
            brightness == Brightness.dark ? modes.dark : modes.light;
        final cs = theme.colorScheme;
        final semantic = theme.extension<PortalSemanticColors>()!;
        final portal = theme.extension<PortalUiTheme>()!;
        final name = '${palette.label} $brightness';

        void gate(String role, Color fg, Color bg, double floor) {
          final ratio = _contrast(fg, bg);
          expect(ratio, greaterThanOrEqualTo(floor),
              reason: '$name · $role: ${_hex(fg)} on ${_hex(bg)} is '
                  '${ratio.toStringAsFixed(2)}:1, under $floor');
        }

        test('$name: text pairs read at 4.5:1', () {
          final text = <String, (Color, Color)>{
            'onPrimary': (cs.onPrimary, cs.primary),
            'onPrimaryContainer': (cs.onPrimaryContainer, cs.primaryContainer),
            'onSecondary': (cs.onSecondary, cs.secondary),
            'onSecondaryContainer':
                (cs.onSecondaryContainer, cs.secondaryContainer),
            'onTertiary': (cs.onTertiary, cs.tertiary),
            'onTertiaryContainer':
                (cs.onTertiaryContainer, cs.tertiaryContainer),
            'onError': (cs.onError, cs.error),
            'onErrorContainer': (cs.onErrorContainer, cs.errorContainer),
            'onInverseSurface': (cs.onInverseSurface, cs.inverseSurface),
            'onSuccess': (semantic.onSuccess, semantic.success),
            'onSuccessContainer':
                (semantic.onSuccessContainer, semantic.successContainer),
            'onWarning': (semantic.onWarning, semantic.warning),
            'onWarningContainer':
                (semantic.onWarningContainer, semantic.warningContainer),
            'onInfo': (semantic.onInfo, semantic.info),
            'onInfoContainer':
                (semantic.onInfoContainer, semantic.infoContainer),
            'onCard': (portal.onCard, portal.card),
            'onPopover': (portal.onPopover, portal.popover),
            'onMuted': (portal.onMuted, portal.muted),
            'onAccent': (portal.onAccent, portal.accent),
          };
          for (final MapEntry(key: role, value: (fg, bg)) in text.entries) {
            gate(role, fg, bg, 4.5);
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
            gate('onSurface on $on', cs.onSurface, bg, 4.5);
            // Muted text is still text: hints, placeholders, captions.
            gate('onSurfaceVariant on $on', cs.onSurfaceVariant, bg, 4.5);
          }
        });

        test('$name: outlines, icons and status fills read at 3:1', () {
          gate('outline', cs.outline, cs.surface, 3.0);
          gate('outline on surfaceContainerHighest', cs.outline,
              cs.surfaceContainerHighest, 3.0);
          gate('focusRing', portal.focusRing, cs.surface, 3.0);
          gate('primary as a control', cs.primary, cs.surface, 3.0);
          gate('success', semantic.success, cs.surface, 3.0);
          gate('warning', semantic.warning, cs.surface, 3.0);
          gate('info', semantic.info, cs.surface, 3.0);
          gate('danger', semantic.danger, cs.surface, 3.0);
        });
      }
    }
  });
}
