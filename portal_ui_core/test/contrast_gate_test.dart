import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portal_ui_core/contrast_gate.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

/// F2 — the floors our docs asserted without numbers. Text reads at 4.5:1;
/// an icon, outline, focus ring or control border reads at 3:1 against the
/// surface behind it. A palette that fails is fixed in its own values, never
/// waived here. The floors themselves live in `lib/contrast_gate.dart` (F6),
/// so every app's `test/contrast_gate_test.dart` holds the same line.
void main() {
  group('contrast gate', () {
    for (final palette in PortalThemeCatalog.all) {
      final modes = palette.toConfig().build();
      for (final brightness in Brightness.values) {
        final theme = brightness == Brightness.dark ? modes.dark : modes.light;
        final name = '${palette.label} $brightness';
        test('$name clears the floors', () {
          final failures = portalThemeContrastFailures(theme, scheme: name);
          expect(failures, isEmpty, reason: describeContrastFailures(failures));
        });
      }
    }
  });
}
