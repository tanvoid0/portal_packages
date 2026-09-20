import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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
