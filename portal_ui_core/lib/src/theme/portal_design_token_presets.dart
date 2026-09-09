import 'package:flutter/foundation.dart';

import '../tokens/design_tokens.dart';

/// Named layout token bundle — spacing, radii, motion, tap targets.
@immutable
class PortalDesignTokenPreset {
  const PortalDesignTokenPreset({
    required this.id,
    required this.label,
    required this.tokens,
    this.description,
  });

  final String id;
  final String label;
  final DesignTokens tokens;
  final String? description;
}

/// Every layout style the theme matrix can combine with accent palettes.
abstract final class PortalDesignTokenPresets {
  static const PortalDesignTokenPreset defaultPreset = PortalDesignTokenPreset(
    id: 'default',
    label: 'Default',
    tokens: DesignTokens.defaults,
    description: 'Standard spacing and corner radii',
  );

  static const PortalDesignTokenPreset compact = PortalDesignTokenPreset(
    id: 'compact',
    label: 'Compact',
    tokens: DesignTokens.compact,
    description: 'Tighter spacing and smaller radii',
  );

  static const PortalDesignTokenPreset rounded = PortalDesignTokenPreset(
    id: 'rounded',
    label: 'Rounded',
    tokens: DesignTokens.rounded,
    description: 'Larger corner radii',
  );

  static const PortalDesignTokenPreset generous = PortalDesignTokenPreset(
    id: 'generous',
    label: 'Generous',
    tokens: DesignTokens.generous,
    description: 'Warm, content-heavy corner radii',
  );

  static const PortalDesignTokenPreset expressive = PortalDesignTokenPreset(
    id: 'expressive',
    label: 'Expressive',
    tokens: DesignTokens.expressive,
    description: 'Bold curves and continuous card corners',
  );

  static const List<PortalDesignTokenPreset> all = [
    defaultPreset,
    compact,
    rounded,
    generous,
    expressive,
  ];

  static PortalDesignTokenPreset? tryById(String id) {
    for (final preset in all) {
      if (preset.id == id) return preset;
    }
    return null;
  }

  static PortalDesignTokenPreset forTokens(DesignTokens tokens) {
    for (final preset in all) {
      if (identical(preset.tokens, tokens)) return preset;
    }
    return defaultPreset;
  }
}
