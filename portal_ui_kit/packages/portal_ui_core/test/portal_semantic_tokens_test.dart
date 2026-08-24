import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

void main() {
  group('PortalUiTheme semantic tokens', () {
    test('maps shadcn-aligned roles from color scheme', () {
      final modes = PortalThemeComposer.build(
        palette: PortalThemePalette.violet,
        visualTheme: PortalVisualThemeCatalog.material,
      );
      final portal = modes.light.extension<PortalUiTheme>()!;
      final scheme = modes.light.colorScheme;

      expect(portal.background, scheme.surface);
      expect(portal.foreground, scheme.onSurface);
      expect(portal.muted, scheme.surfaceContainerLow);
      expect(portal.onMuted, scheme.onSurfaceVariant);
      expect(portal.card, scheme.surfaceContainerHighest);
      expect(portal.popover, scheme.surfaceContainerHighest);
      expect(portal.accent, scheme.surfaceContainerHigh);
      expect(portal.input, isNotNull);
      expect(portal.border, isNotNull);
      expect(portal.ring, portal.focusRing);
    });

    test('border helpers derive from semantic border token', () {
      final portal = PortalThemeComposer.build(
        palette: PortalThemePalette.emerald,
        visualTheme: PortalVisualThemeCatalog.clean,
      ).light.extension<PortalUiTheme>()!;

      expect(portal.borderSide().color, portal.border);
      expect(portal.subtleBorderSide().color.a, lessThan(portal.border.a));
    });

    test('glass visual theme adjusts border and surfaces', () {
      final portal = PortalThemeComposer.build(
        palette: PortalThemePalette.violet,
        visualTheme: PortalVisualThemeCatalog.glass,
      ).light.extension<PortalUiTheme>()!;

      expect(portal.isGlass, isTrue);
      expect(portal.border.a, lessThan(1.0));
      expect(portal.card.a, lessThan(1.0));
    });

    test('applyPortalComponentThemes wires scrollbar theme from PortalUiTheme', () {
      final modes = PortalThemeComposer.build(
        palette: PortalThemePalette.violet,
        visualTheme: PortalVisualThemeCatalog.material,
      );
      final portal = modes.light.extension<PortalUiTheme>()!;
      final scrollbar = modes.light.scrollbarTheme;

      expect(scrollbar.thickness?.resolve({}), 8);
      expect(scrollbar.thumbColor?.resolve({}), portal.border);
    });
  });

  group('portalInputDecoration', () {
    testWidgets('uses portal input fill and border tokens', (tester) async {
      final modes = PortalThemeComposer.build(
        palette: PortalThemePalette.violet,
        visualTheme: PortalVisualThemeCatalog.material,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: modes.light,
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: TextField(
                  decoration: portalInputDecoration(context, hint: 'Email'),
                ),
              );
            },
          ),
        ),
      );

      final portal = modes.light.extension<PortalUiTheme>()!;
      final decoration = tester.widget<TextField>(find.byType(TextField)).decoration!;
      expect(decoration.filled, isTrue);
      expect(decoration.fillColor, portal.input);
    });
  });
}
