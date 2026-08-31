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
  PortalThemeController({
    this.defaultMode = ThemeMode.system,
    this.legacyKeys = const [],
  });

  static const _modeKey = 'portal_theme_mode';
  static const _paletteKey = 'portal_theme_palette';

  /// What an app starts on before the user has chosen. `portal_gym` ships
  /// dark; everything else follows the system.
  final ThemeMode defaultMode;

  /// `shared_preferences` keys an app used before it moved to this controller,
  /// newest first. Read once, then written under [_modeKey] and deleted.
  ///
  /// Without this, migrating an app silently resets everyone who had chosen a
  /// theme — the setting does not look broken, it just quietly reverts.
  final List<String> legacyKeys;

  late final themeMode = defaultMode.obs;
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
    paletteId.value = prefs.getString(_paletteKey);

    final stored = prefs.getString(_modeKey);
    if (stored != null) {
      themeMode.value = parseMode(stored, fallback: defaultMode);
      return;
    }

    for (final key in legacyKeys) {
      final legacy = prefs.getString(key);
      if (legacy == null) continue;
      themeMode.value = parseMode(legacy, fallback: defaultMode);
      await prefs.setString(_modeKey, themeMode.value.name);
      await prefs.remove(key);
      return;
    }

    themeMode.value = defaultMode;
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

  /// Whether the app is currently dark *on screen*, which is not the same as
  /// `themeMode == dark`: under [ThemeMode.system] only the platform knows.
  bool isDarkIn(BuildContext context) => switch (themeMode.value) {
        ThemeMode.dark => true,
        ThemeMode.light => false,
        ThemeMode.system =>
          MediaQuery.platformBrightnessOf(context) == Brightness.dark,
      };

  /// One-tap light/dark for apps that keep a toggle outside settings.
  ///
  /// Resolves [ThemeMode.system] against what is actually on screen first, so
  /// the first tap always visibly flips rather than sometimes doing nothing.
  Future<void> toggleLightDark(BuildContext context) =>
      setThemeMode(isDarkIn(context) ? ThemeMode.light : ThemeMode.dark);

  /// Unknown or missing values fall back to [fallback] — a stored string from
  /// an older build should not be able to crash a launch.
  static ThemeMode parseMode(
    String? stored, {
    ThemeMode fallback = ThemeMode.system,
  }) =>
      ThemeMode.values.firstWhere(
        (m) => m.name == stored,
        orElse: () => fallback,
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
