import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The appearance choices every Portal app shares: light/dark/system, and an
/// optional palette id for apps whose themes come from the UI kit registry.
///
/// Persisted with `shared_preferences` rather than `GetStorage` so it works in
/// an app that never called `GetStorage.init()` — most of them have not.
///
/// [paletteId] is deliberately an opaque string. `portal_platform` sits below
/// the UI kit and must not know what a palette is; the host app maps the id
/// back to a theme.
class PortalThemeController extends GetxController {
  static const _modeKey = 'portal_theme_mode';
  static const _paletteKey = 'portal_theme_palette';

  final themeMode = ThemeMode.system.obs;
  final paletteId = RxnString();

  @override
  void onInit() {
    super.onInit();
    load();
  }

  /// Reads both values from storage. Awaitable so `main()` can settle the
  /// theme before the first frame instead of flashing the default.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    themeMode.value = parseMode(prefs.getString(_modeKey));
    paletteId.value = prefs.getString(_paletteKey);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    themeMode.value = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_modeKey, mode.name);
  }

  Future<void> setPaletteId(String? id) async {
    paletteId.value = id;
    final prefs = await SharedPreferences.getInstance();
    if (id == null || id.isEmpty) {
      await prefs.remove(_paletteKey);
    } else {
      await prefs.setString(_paletteKey, id);
    }
  }

  /// Unknown or missing values fall back to [ThemeMode.system] — a stored
  /// string from an older build should not be able to crash a launch.
  static ThemeMode parseMode(String? stored) => ThemeMode.values.firstWhere(
        (m) => m.name == stored,
        orElse: () => ThemeMode.system,
      );

  static String labelFor(ThemeMode mode) => switch (mode) {
        ThemeMode.system => 'System',
        ThemeMode.light => 'Light',
        ThemeMode.dark => 'Dark',
      };

  static IconData iconFor(ThemeMode mode) => switch (mode) {
        ThemeMode.system => Icons.brightness_auto_outlined,
        ThemeMode.light => Icons.light_mode_outlined,
        ThemeMode.dark => Icons.dark_mode_outlined,
      };
}

/// One selectable palette, as the host app describes it.
///
/// Apps built on the UI kit map `PortalThemeCatalog` onto this; apps with a
/// hand-built theme pass an empty list and the picker does not appear.
class PortalPaletteOption {
  const PortalPaletteOption({
    required this.id,
    required this.label,
    required this.swatch,
  });

  final String id;
  final String label;
  final Color swatch;
}
