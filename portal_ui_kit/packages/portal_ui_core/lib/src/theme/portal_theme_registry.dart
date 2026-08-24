import 'portal_theme_composer.dart';
import 'portal_theme_palette.dart';
import 'portal_theme_preset.dart';
import 'portal_theme_definition.dart';
import 'portal_visual_theme.dart';

/// Registry of composed and custom complete themes.
///
/// Seeds every palette × visual-style combination. Register more via
/// [registerDefinition] or [PortalVisualThemeRegistry] + [PortalThemeComposer].
class PortalThemeRegistry {
  PortalThemeRegistry._();

  static final PortalThemeRegistry instance = PortalThemeRegistry._();

  final Map<String, PortalThemePreset> _presets = {};
  bool _initialized = false;

  void ensureInitialized() {
    if (_initialized) return;
    _seedComposed();
    _initialized = true;
  }

  void _seedComposed() {
    PortalVisualThemeRegistry.instance.ensureInitialized();
    for (final palette in PortalThemeCatalog.all) {
      for (final visual in PortalVisualThemeRegistry.instance.all) {
        _put(PortalThemeComposer.preset(
          palette: palette,
          visualTheme: visual,
        ));
      }
    }
  }

  List<PortalThemePreset> get all {
    ensureInitialized();
    final list = _presets.values.toList()
      ..sort((a, b) => a.label.compareTo(b.label));
    return list;
  }

  List<PortalThemePreset> search(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return all;
    return all.where((p) {
      if (p.id.toLowerCase().contains(q)) return true;
      if (p.label.toLowerCase().contains(q)) return true;
      if (p.description?.toLowerCase().contains(q) == true) return true;
      for (final tag in p.tags) {
        if (tag.toLowerCase().contains(q)) return true;
      }
      return false;
    }).toList();
  }

  int get count {
    ensureInitialized();
    return _presets.length;
  }

  PortalThemePreset get defaultPreset => byId(kPortalDefaultThemeId);

  PortalThemePreset byId(String id) {
    ensureInitialized();
    return _presets[id] ?? _presets[kPortalDefaultThemeId]!;
  }

  PortalThemePreset? tryById(String id) {
    ensureInitialized();
    return _presets[id];
  }

  void register(PortalThemePreset preset) => _put(preset);

  void registerDefinition(PortalThemeDefinition definition) {
    _put(definition.toPreset());
  }

  void registerAll(Iterable<PortalThemeDefinition> definitions) {
    for (final def in definitions) {
      registerDefinition(def);
    }
  }

  void unregister(String id) => _presets.remove(id);

  /// Re-generates palette × visual-style presets (e.g. after registering a new
  /// [PortalVisualTheme]).
  void syncComposed() {
    ensureInitialized();
    _seedComposed();
  }

  void reset() {
    _presets.clear();
    _initialized = false;
    PortalVisualThemeRegistry.instance.reset();
    ensureInitialized();
  }

  void _put(PortalThemePreset preset) => _presets[preset.id] = preset;
}
