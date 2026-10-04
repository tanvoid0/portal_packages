import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_color_utilities/material_color_utilities.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

/// WCAG 2.x contrast ratio.
double _contrast(Color a, Color b) {
  final la = a.computeLuminance(), lb = b.computeLuminance();
  final (hi, lo) = la > lb ? (la, lb) : (lb, la);
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  group('PortalSemanticColors', () {
    for (final brightness in Brightness.values) {
      test('$brightness: on-colours read at AA on every role', () {
        final theme = buildPortalTheme(brightness: brightness);
        final s = theme.extension<PortalSemanticColors>()!;
        final pairs = {
          'success': (s.success, s.onSuccess),
          'successContainer': (s.successContainer, s.onSuccessContainer),
          'warning': (s.warning, s.onWarning),
          'warningContainer': (s.warningContainer, s.onWarningContainer),
          'info': (s.info, s.onInfo),
          'infoContainer': (s.infoContainer, s.onInfoContainer),
        };
        for (final MapEntry(key: role, value: (bg, fg)) in pairs.entries) {
          expect(_contrast(bg, fg), greaterThanOrEqualTo(4.5), reason: role);
        }
      });
    }

    test('danger mirrors ColorScheme.error', () {
      final theme = buildPortalTheme(brightness: Brightness.light);
      final s = theme.extension<PortalSemanticColors>()!;
      expect(s.danger, theme.colorScheme.error);
      expect(s.onDangerContainer, theme.colorScheme.onErrorContainer);
    });

    // Every app's error roles, read from docs/ui-kit/data/schemes/*.json
    // (written by ./scripts/export-kit-data.sh). Re-run the export and paste
    // the new values here when an app changes its error.
    const errors = <String, (int, int, int, int)>{
      // app: (light error, light errorContainer, dark error, dark container)
      'assistant': (0xFFBE3B2E, 0xFFF9DED9, 0xFFF59182, 0xFF3F1410),
      'finance': (0xFFDE3B41, 0xFFFBE1D9, 0xFFFF7A7F, 0xFF331C18),
      'gym': (0xFFC2382A, 0xFFFADAD5, 0xFFFF8A7A, 0xFF5C1A12),
      'journey': (0xFF9E4A2E, 0xFFF5DED5, 0xFFE0937A, 0xFF42190C),
      'lifestyle': (0xFF9E4A2E, 0xFFF5DED5, 0xFFE0937A, 0xFF42190C),
      'recipe': (0xFFC73E3E, 0xFFF8D0D8, 0xFFF07070, 0xFF3D1E1E),
      'shopping': (0xFFA33124, 0xFFF7DED9, 0xFFEF8578, 0xFF43140E),
      'task': (0xFFDC2626, 0xFFFFDAD6, 0xFFEF4444, 0xFF93000A),
      // K12 moves lifestyle to crimson; pinned here so the pick cannot
      // reintroduce the clash.
      'lifestyle (K12 crimson)':
          (0xFFB3261E, 0xFFF9DEDC, 0xFFF2B8B5, 0xFF8C1D18),
    };

    // Each app seeds its scheme from its own primary, which used to pull
    // warning into error's hue through Blend.harmonize (K3).
    const primaries = <String, (int, int)>{
      'assistant': (0xFF4A6B00, 0xFFC8FF52),
      'finance': (0xFF0E0F13, 0xFFF2F4F8),
      'gym': (0xFFD93E22, 0xFFFF5A3C),
      'journey': (0xFF33538E, 0xFF9FB4E0),
      'lifestyle': (0xFF9A6E1E, 0xFFD9A94E),
      'recipe': (0xFF2A2A2A, 0xFFF0EFEA),
      'shopping': (0xFF2F7D4F, 0xFF63C98C),
      'task': (0xFF67548E, 0xFFD2BCFD),
      'lifestyle (K12 crimson)': (0xFF9A6E1E, 0xFFD9A94E),
    };

    for (final brightness in Brightness.values) {
      final dark = brightness == Brightness.dark;
      test('$brightness: warning clears every app error by 20° in HCT', () {
        for (final MapEntry(key: app, value: e) in errors.entries) {
          final (lightError, lightContainer, darkError, darkContainer) = e;
          final error = Color(dark ? darkError : lightError);
          final errorContainer = Color(dark ? darkContainer : lightContainer);
          final primary = Color(
            dark ? primaries[app]!.$2 : primaries[app]!.$1,
          );
          final s = PortalSemanticColors.fromScheme(
            ColorScheme.fromSeed(seedColor: primary, brightness: brightness)
                .copyWith(
              primary: primary,
              error: error,
              errorContainer: errorContainer,
            ),
          );
          var gap =
              (Hct.fromInt(s.warning.toARGB32()).hue - Hct.fromInt(error.toARGB32()).hue)
                  .abs();
          if (gap > 180) gap = 360 - gap;
          expect(gap, greaterThanOrEqualTo(20),
              reason: '$app: warning reads as negative beside its error');
          expect(s.warningContainer, isNot(errorContainer), reason: app);
        }
      });
    }

    test('harmonises toward the primary hue', () {
      // Same green seed, two very different primaries → two different greens.
      final a = PortalSemanticColors.fromScheme(
        ColorScheme.fromSeed(seedColor: Colors.blue),
      );
      final b = PortalSemanticColors.fromScheme(
        ColorScheme.fromSeed(seedColor: Colors.orange),
      );
      expect(a.success, isNot(b.success));
    });

    test('extensionsBuilder overrides per brightness and survives the pipeline',
        () {
      final modes = PortalThemePalette.violet
          .toConfig()
          .copyWith(
            portalUiThemeBuilder: (_, base) => base,
            extensionsBuilder: (ctx) => [
              ctx.theme.extension<PortalSemanticColors>()!.copyWith(
                info: ctx.brightness == Brightness.dark
                    ? Colors.cyan
                    : Colors.indigo,
              ),
            ],
          )
          .build();
      expect(modes.light.extension<PortalSemanticColors>()!.info, Colors.indigo);
      expect(modes.dark.extension<PortalSemanticColors>()!.info, Colors.cyan);
      // The portal extension is still there beside it.
      expect(modes.light.extension<PortalUiTheme>(), isNotNull);
    });

    testWidgets('of() falls back to scheme defaults without the extension',
        (t) async {
      late PortalSemanticColors s;
      await t.pumpWidget(MaterialApp(
        theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal)),
        home: Builder(builder: (context) {
          s = PortalSemanticColors.of(context);
          return const SizedBox.shrink();
        }),
      ));
      expect(_contrast(s.success, s.onSuccess), greaterThanOrEqualTo(4.5));
    });

    testWidgets('stat card delta is painted by sign', (t) async {
      final theme = buildPortalTheme(brightness: Brightness.light);
      await t.pumpWidget(MaterialApp(
        theme: theme,
        home: const Scaffold(
          body: Column(children: [
            PortalStatCard(value: '1', label: 'up', delta: '+2%'),
            PortalStatCard(value: '1', label: 'down', delta: '-2%'),
          ]),
        ),
      ));
      final s = theme.extension<PortalSemanticColors>()!;
      expect(t.widget<Text>(find.text('+2%')).style?.color, s.success);
      expect(t.widget<Text>(find.text('-2%')).style?.color, s.danger);
    });
  });
}
