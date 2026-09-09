import 'package:flutter/material.dart';

import '../tokens/design_tokens.dart';
import 'portal_theme_build_context.dart';
import 'portal_visual_theme_styles.dart';

/// Visual style layer — layout tokens + component chrome (independent of accent color).
///
/// Pair with a [PortalThemePalette] via [PortalThemeComposer]. Register custom
/// styles at runtime through [PortalVisualThemeRegistry].
@immutable
class PortalVisualTheme {
  const PortalVisualTheme({
    required this.id,
    required this.label,
    required this.tokens,
    this.description,
    this.portalUiThemeBuilder,
    this.customize,
    this.componentThemeOptionsBuilder,
    this.tags = const [],
  });

  final String id;
  final String label;
  final DesignTokens tokens;
  final String? description;
  final PortalUiThemeBuilder? portalUiThemeBuilder;
  final PortalThemeCustomizer? customize;
  final PortalComponentThemeOptionsBuilder? componentThemeOptionsBuilder;
  final List<String> tags;

  PortalUiThemeBuilder get resolvedPortalUiThemeBuilder =>
      portalUiThemeBuilder ?? PortalVisualThemeStyles.portalUiThemeFor(id);

  PortalThemeCustomizer get resolvedCustomize =>
      customize ?? PortalVisualThemeStyles.customizeFor(id);

  PortalVisualTheme copyWith({
    String? id,
    String? label,
    DesignTokens? tokens,
    String? description,
    PortalUiThemeBuilder? portalUiThemeBuilder,
    PortalThemeCustomizer? customize,
    PortalComponentThemeOptionsBuilder? componentThemeOptionsBuilder,
    List<String>? tags,
  }) {
    return PortalVisualTheme(
      id: id ?? this.id,
      label: label ?? this.label,
      tokens: tokens ?? this.tokens,
      description: description ?? this.description,
      portalUiThemeBuilder: portalUiThemeBuilder ?? this.portalUiThemeBuilder,
      customize: customize ?? this.customize,
      componentThemeOptionsBuilder:
          componentThemeOptionsBuilder ?? this.componentThemeOptionsBuilder,
      tags: tags ?? this.tags,
    );
  }
}

/// Default visual theme id.
const String kPortalDefaultVisualThemeId = 'material';

/// Built-in visual themes and a growing registry for experiments.
class PortalVisualThemeRegistry {
  PortalVisualThemeRegistry._();

  static final PortalVisualThemeRegistry instance = PortalVisualThemeRegistry._();

  final Map<String, PortalVisualTheme> _themes = {};
  bool _initialized = false;

  void ensureInitialized() {
    if (_initialized) return;
    _seedBuiltIns();
    _initialized = true;
  }

  void _seedBuiltIns() {
    _registerBuiltIn(
      id: 'material',
      label: 'Material',
      tokens: DesignTokens.defaults,
      description: 'Standard Material 3 spacing and component chrome',
    );
    _registerBuiltIn(
      id: 'clean',
      label: 'Clean',
      tokens: DesignTokens.rounded,
      description: 'Airy layout, soft borders, generous whitespace',
    );
    _registerBuiltIn(
      id: 'atomic',
      label: 'Atomic',
      tokens: DesignTokens.compact,
      description: 'Dense, sharp UI with strong structural borders',
    );
    _registerBuiltIn(
      id: 'glass',
      label: 'Glass',
      tokens: DesignTokens.rounded,
      description: 'Frosted blur, translucent panels, specular edges',
    );
  }

  void _registerBuiltIn({
    required String id,
    required String label,
    required DesignTokens tokens,
    String? description,
  }) {
    _put(PortalVisualTheme(
      id: id,
      label: label,
      tokens: tokens,
      description: description,
    ));
  }

  List<PortalVisualTheme> get all {
    ensureInitialized();
    final list = _themes.values.toList()
      ..sort((a, b) => a.label.compareTo(b.label));
    return list;
  }

  PortalVisualTheme get defaultTheme => byId(kPortalDefaultVisualThemeId);

  PortalVisualTheme byId(String id) {
    ensureInitialized();
    return _themes[id] ?? _themes[kPortalDefaultVisualThemeId]!;
  }

  PortalVisualTheme? tryById(String id) {
    ensureInitialized();
    return _themes[id];
  }

  void register(PortalVisualTheme theme) => _put(theme);

  void unregister(String id) => _themes.remove(id);

  void reset() {
    _themes.clear();
    _initialized = false;
    ensureInitialized();
  }

  void _put(PortalVisualTheme theme) => _themes[theme.id] = theme;
}

/// Named shortcuts to built-in visual themes.
abstract final class PortalVisualThemeCatalog {
  static const String defaultId = kPortalDefaultVisualThemeId;

  static PortalVisualTheme get material =>
      PortalVisualThemeRegistry.instance.byId('material');

  static PortalVisualTheme get clean =>
      PortalVisualThemeRegistry.instance.byId('clean');

  static PortalVisualTheme get atomic =>
      PortalVisualThemeRegistry.instance.byId('atomic');

  static PortalVisualTheme get glass =>
      PortalVisualThemeRegistry.instance.byId('glass');

  static List<PortalVisualTheme> get all =>
      PortalVisualThemeRegistry.instance.all;
}
