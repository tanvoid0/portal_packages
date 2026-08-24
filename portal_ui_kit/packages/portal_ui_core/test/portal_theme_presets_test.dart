import 'package:flutter_test/flutter_test.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

void main() {
  setUp(() => PortalThemeRegistry.instance.reset());

  group('PortalVisualThemeRegistry', () {
    test('includes built-in visual styles', () {
      final ids = PortalVisualThemeRegistry.instance.all.map((t) => t.id).toSet();
      expect(ids, containsAll(['material', 'clean', 'atomic', 'glass']));
    });

    test('glass theme sets PortalUiTheme surface treatment', () {
      final modes = PortalThemeComposer.build(
        palette: PortalThemePalette.violet,
        visualTheme: PortalVisualThemeCatalog.glass,
      );
      final portal = modes.light.extension<PortalUiTheme>();
      expect(portal?.isGlass, isTrue);
      expect(portal?.glassStyle?.blurSigma, greaterThan(0));
    });
  });

  group('PortalThemeComposer', () {
    test('combines palette and visual theme independently', () {
      final modes = PortalThemeComposer.build(
        palette: PortalThemePalette.emerald,
        visualTheme: PortalVisualThemeCatalog.atomic,
      );
      expect(modes.light.colorScheme.primary, isNotNull);
      expect(
        modes.light.extension<PortalUiTheme>()?.tokens,
        DesignTokens.compact,
      );
    });

    test('composeId is stable', () {
      expect(
        PortalThemeComposer.composeId(
          palette: PortalThemePalette.rose,
          visualTheme: PortalVisualThemeCatalog.clean,
        ),
        'rose-clean',
      );
    });
  });

  group('PortalThemeRegistry', () {
    test('seeds palette × visual theme matrix', () {
      PortalVisualThemeRegistry.instance.ensureInitialized();
      final expected = PortalThemeCatalog.all.length *
          PortalVisualThemeRegistry.instance.all.length;
      expect(PortalThemeRegistry.instance.count, expected);
    });

    test('default preset is violet material', () {
      expect(
        PortalThemeRegistry.instance.defaultPreset.id,
        'violet-material',
      );
    });

    test('syncComposed picks up newly registered visual themes', () {
      PortalThemeRegistry.instance.reset();
      PortalVisualThemeRegistry.instance.register(
        const PortalVisualTheme(
          id: 'test-style',
          label: 'Test',
          tokens: DesignTokens.defaults,
        ),
      );
      PortalThemeRegistry.instance.syncComposed();
      expect(
        PortalThemeRegistry.instance.tryById('violet-test-style'),
        isNotNull,
      );
    });
  });
}
