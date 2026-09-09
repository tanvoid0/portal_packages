import 'package:flutter/material.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

ThemeData _expressiveCustomize(PortalThemeBuildContext ctx, ThemeData theme) {
  final radii = ctx.tokens.radii;
  final cs = ctx.colorScheme;

  return theme.copyWith(
    cardTheme: theme.cardTheme.copyWith(
      shape: radii.continuousBorder(
        borderRadius: radii.circular(radii.lg),
        side: BorderSide(color: cs.outline.withValues(alpha: 0.3)),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radii.lg),
        ),
      ),
    ),
  );
}

/// Extra visual theme styles for the docs gallery.
///
/// Add a [PortalVisualTheme] here to experiment — palette colors stay separate.
void registerExperimentalThemes() {
  PortalVisualThemeRegistry.instance.ensureInitialized();
  PortalVisualThemeRegistry.instance.register(
    const PortalVisualTheme(
      id: 'expressive',
      label: 'Expressive',
      tokens: DesignTokens.expressive,
      description: 'Bold curves and continuous card corners',
      customize: _expressiveCustomize,
      tags: ['experimental'],
    ),
  );
}
