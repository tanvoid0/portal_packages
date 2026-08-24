import 'package:flutter/material.dart';

import 'portal_surface_treatment.dart';
import 'portal_theme_build_context.dart';
import 'portal_ui_theme.dart';

// ── PortalUiTheme transforms per visual style ─────────────────────────────

PortalUiTheme _solidPortalUiTheme(PortalThemeBuildContext ctx, PortalUiTheme base) {
  return base.copyWith(
    surfaceTreatment: PortalSurfaceTreatment.solid,
    clearGlassStyle: true,
  );
}

PortalUiTheme _glassPortalUiTheme(PortalThemeBuildContext ctx, PortalUiTheme base) {
  final glass = PortalGlassStyle.forBrightness(ctx.brightness);
  final glassBorder = base.outline.withValues(alpha: glass.borderAlpha);
  return base.copyWith(
    surfaceTreatment: PortalSurfaceTreatment.glass,
    glassStyle: glass,
    surface: base.surface.withValues(alpha: glass.tintAlpha),
    surfaceVariant: base.surfaceVariant.withValues(alpha: glass.tintAlpha * 0.75),
    outline: glassBorder,
    border: glassBorder,
    card: base.card.withValues(alpha: glass.tintAlpha),
    popover: base.popover.withValues(alpha: glass.tintAlpha),
    input: base.input.withValues(alpha: glass.tintAlpha * 0.9),
  );
}

// ── ThemeData customizers ───────────────────────────────────────────────────

ThemeData _materialCustomize(PortalThemeBuildContext ctx, ThemeData theme) =>
    theme;

ThemeData _cleanCustomize(PortalThemeBuildContext ctx, ThemeData theme) {
  final cs = ctx.colorScheme;
  final r = ctx.tokens.radii;
  final subtle = BorderSide(color: cs.outline.withValues(alpha: 0.18));

  return theme.copyWith(
    dividerTheme: theme.dividerTheme.copyWith(
      color: cs.outline.withValues(alpha: 0.12),
      thickness: 0.5,
    ),
    cardTheme: theme.cardTheme.copyWith(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(r.lg),
        side: subtle,
      ),
      margin: EdgeInsets.symmetric(vertical: ctx.tokens.spacing.sm),
    ),
    inputDecorationTheme: theme.inputDecorationTheme.copyWith(
      filled: true,
      fillColor: cs.surfaceContainerLow.withValues(alpha: 0.35),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(r.md),
        borderSide: subtle,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(r.md),
        borderSide: subtle,
      ),
    ),
    listTileTheme: theme.listTileTheme.copyWith(
      contentPadding: EdgeInsets.symmetric(
        horizontal: ctx.tokens.spacing.xl,
        vertical: ctx.tokens.spacing.sm,
      ),
    ),
  );
}

ThemeData _atomicCustomize(PortalThemeBuildContext ctx, ThemeData theme) {
  final cs = ctx.colorScheme;
  final r = ctx.tokens.radii;
  final strong = BorderSide(
    color: cs.outline.withValues(alpha: 0.85),
    width: ctx.tokens.borderWidth,
  );

  return theme.copyWith(
    cardTheme: theme.cardTheme.copyWith(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(r.sm),
        side: strong,
      ),
      margin: EdgeInsets.zero,
    ),
    dividerTheme: theme.dividerTheme.copyWith(
      thickness: 1.5,
      color: cs.outline.withValues(alpha: 0.55),
    ),
    chipTheme: theme.chipTheme.copyWith(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(r.sm),
        side: strong,
      ),
    ),
    inputDecorationTheme: theme.inputDecorationTheme.copyWith(
      contentPadding: EdgeInsets.symmetric(
        horizontal: ctx.tokens.spacing.md,
        vertical: ctx.tokens.spacing.sm,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(r.sm),
        borderSide: strong,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(r.sm),
        borderSide: strong,
      ),
    ),
  );
}

ThemeData _glassCustomize(PortalThemeBuildContext ctx, ThemeData theme) {
  final cs = ctx.colorScheme;
  final glass = PortalGlassStyle.forBrightness(ctx.brightness);
  final r = ctx.tokens.radii;
  final border = BorderSide(
    color: cs.outline.withValues(alpha: glass.borderAlpha),
    width: ctx.tokens.borderWidth,
  );

  Color frost(Color c) => c.withValues(alpha: glass.tintAlpha);

  return theme.copyWith(
    scaffoldBackgroundColor: Colors.transparent,
    canvasColor: frost(cs.surfaceContainerHighest),
    cardTheme: theme.cardTheme.copyWith(
      color: frost(cs.surfaceContainerHighest),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(r.lg),
        side: border,
      ),
    ),
    appBarTheme: theme.appBarTheme.copyWith(
      backgroundColor: frost(cs.surface),
      surfaceTintColor: Colors.transparent,
    ),
    dialogTheme: theme.dialogTheme.copyWith(
      backgroundColor: frost(cs.surfaceContainerHighest),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(r.xl),
        side: border,
      ),
    ),
    bottomSheetTheme: theme.bottomSheetTheme.copyWith(
      backgroundColor: frost(cs.surfaceContainerHighest),
      elevation: 0,
    ),
    inputDecorationTheme: theme.inputDecorationTheme.copyWith(
      fillColor: frost(cs.surfaceContainerHigh),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(r.md),
        borderSide: border,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(r.md),
        borderSide: BorderSide(
          color: cs.primary.withValues(alpha: 0.65),
          width: border.width,
        ),
      ),
    ),
    chipTheme: theme.chipTheme.copyWith(
      backgroundColor: frost(cs.surfaceContainerHigh),
      side: border,
    ),
    popupMenuTheme: theme.popupMenuTheme.copyWith(
      color: frost(cs.surfaceContainerHighest),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(r.lg),
        side: border,
      ),
    ),
    navigationBarTheme: theme.navigationBarTheme.copyWith(
      backgroundColor: frost(cs.surface),
      elevation: 0,
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return cs.primary.withValues(alpha: 0.2);
          }
          return frost(cs.surfaceContainerHigh);
        }),
        side: WidgetStateProperty.all(border),
      ),
    ),
  );
}

/// Style hooks keyed by visual theme id.
abstract final class PortalVisualThemeStyles {
  static PortalUiThemeBuilder portalUiThemeFor(String id) => switch (id) {
        'glass' => _glassPortalUiTheme,
        _ => _solidPortalUiTheme,
      };

  static PortalThemeCustomizer customizeFor(String id) => switch (id) {
        'clean' => _cleanCustomize,
        'atomic' => _atomicCustomize,
        'glass' => _glassCustomize,
        _ => _materialCustomize,
      };
}
