import 'portal_theme_preset.dart';
import 'portal_theme_registry.dart';

/// Named shortcuts to common composed themes.
abstract final class PortalThemePresetCatalog {
  static const String defaultId = kPortalDefaultThemeId;

  static PortalThemePreset get violet => byId('violet-material');

  static PortalThemePreset get emerald => byId('emerald-material');

  static PortalThemePreset get rose => byId('rose-clean');

  static PortalThemePreset get violetGlass => byId('violet-glass');

  static List<PortalThemePreset> get all => PortalThemeRegistry.instance.all;

  static PortalThemePreset get defaultPreset =>
      PortalThemeRegistry.instance.defaultPreset;

  static PortalThemePreset byId(String id) =>
      PortalThemeRegistry.instance.byId(id);

  static PortalThemePreset? tryById(String id) =>
      PortalThemeRegistry.instance.tryById(id);
}
