import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

void main() {
  group('portalToastColors', () {
    testWidgets('resolves opaque ColorScheme fills in light and dark',
        (tester) async {
      for (final brightness in [Brightness.light, Brightness.dark]) {
        final modes = PortalThemeComposer.build(
          palette: PortalThemePalette.violet,
          visualTheme: PortalVisualThemeCatalog.material,
        );
        final theme = brightness == Brightness.light ? modes.light : modes.dark;

        late PortalToastColors neutral;
        late PortalToastColors success;
        late PortalToastColors destructive;
        late ColorScheme cs;

        await tester.pumpWidget(
          MaterialApp(
            theme: theme,
            home: Builder(
              builder: (context) {
                cs = Theme.of(context).colorScheme;
                neutral = portalToastColors(context, PortalToastVariant.neutral);
                success = portalToastColors(context, PortalToastVariant.success);
                destructive =
                    portalToastColors(context, PortalToastVariant.destructive);
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        expect(neutral.background.a, 1.0);
        expect(neutral.foreground.a, 1.0);
        expect(success.background.a, 1.0);
        expect(destructive.background.a, 1.0);
        expect(neutral.background, cs.surface);
        expect(success.background, cs.secondary);
        expect(destructive.background, cs.error);
      }
    });

    testWidgets('stays opaque when the visual theme is glass', (tester) async {
      final modes = PortalThemeComposer.build(
        palette: PortalThemePalette.violet,
        visualTheme: PortalVisualThemeCatalog.glass,
      );
      final portal = modes.light.extension<PortalUiTheme>()!;
      expect(portal.isGlass, isTrue);
      expect(portal.popover.a, lessThan(1.0));

      late PortalToastColors colors;
      await tester.pumpWidget(
        MaterialApp(
          theme: modes.light,
          home: Builder(
            builder: (context) {
              colors = portalToastColors(context, PortalToastVariant.neutral);
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(colors.background.a, 1.0);
      expect(colors.foreground.a, 1.0);
    });
  });
}
