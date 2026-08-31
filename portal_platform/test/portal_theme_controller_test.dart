import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portal_platform/portal_platform.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The part worth pinning is the reading: an app that migrates onto this
/// controller must not silently reset everyone who had already chosen a theme.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('load', () {
    test('uses the app default when nothing is stored', () async {
      SharedPreferences.setMockInitialValues({});
      final c = PortalThemeController(defaultMode: ThemeMode.dark);
      await c.load();
      expect(c.themeMode.value, ThemeMode.dark);
    });

    test('prefers a stored value over the default', () async {
      SharedPreferences.setMockInitialValues({'portal_theme_mode': 'light'});
      final c = PortalThemeController(defaultMode: ThemeMode.dark);
      await c.load();
      expect(c.themeMode.value, ThemeMode.light);
    });

    test('adopts a legacy key, then rewrites and deletes it', () async {
      SharedPreferences.setMockInitialValues({
        'portal_gym:theme_mode': 'light',
      });
      final c = PortalThemeController(
        defaultMode: ThemeMode.dark,
        legacyKeys: const ['portal_gym:theme_mode'],
      );
      await c.load();

      expect(c.themeMode.value, ThemeMode.light);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('portal_theme_mode'), 'light');
      expect(prefs.getString('portal_gym:theme_mode'), isNull);
    });

    test('ignores a legacy key once the new one exists', () async {
      SharedPreferences.setMockInitialValues({
        'portal_theme_mode': 'system',
        'portal_gym:theme_mode': 'dark',
      });
      final c = PortalThemeController(
        defaultMode: ThemeMode.dark,
        legacyKeys: const ['portal_gym:theme_mode'],
      );
      await c.load();
      expect(c.themeMode.value, ThemeMode.system);
    });

    test('falls back rather than throwing on a value it cannot read', () async {
      SharedPreferences.setMockInitialValues({'portal_theme_mode': 'sepia'});
      final c = PortalThemeController(defaultMode: ThemeMode.dark);
      await c.load();
      expect(c.themeMode.value, ThemeMode.dark);
    });
  });

  testWidgets('isDarkIn resolves system against the platform', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final c = PortalThemeController();
    await c.load();

    late BuildContext ctx;
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(platformBrightness: Brightness.dark),
        child: Builder(builder: (context) {
          ctx = context;
          return const SizedBox.shrink();
        }),
      ),
    );

    expect(c.themeMode.value, ThemeMode.system);
    expect(c.isDarkIn(ctx), isTrue);

    // A toggle under system must land on an explicit mode that actually
    // flips what is on screen, not on `system` again.
    await c.toggleLightDark(ctx);
    expect(c.themeMode.value, ThemeMode.light);
  });
}
