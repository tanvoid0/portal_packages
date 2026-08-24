import 'package:flutter/material.dart';

import '../theme/portal_layout_insets.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Token groups: each is @immutable, const-constructible, and customizable
// via constructor parameters OR subclassing for richer behaviour.
// ─────────────────────────────────────────────────────────────────────────────

/// Spacing scale (logical pixels). Prefer multiples of [grid] for alignment.
@immutable
class PortalSpacing {
  const PortalSpacing({
    this.xs = 4,
    this.sm = 8,
    this.md = 12,
    this.lg = 16,
    this.xl = 24,
    this.xxl = 32,
    this.xxxl = 48,
    this.grid = 4,
  });

  final double xs;
  final double sm;
  final double md;
  final double lg;
  final double xl;
  final double xxl;
  final double xxxl;
  final double grid;

  EdgeInsets symmetric({double h = 0, double v = 0}) =>
      EdgeInsets.symmetric(horizontal: h, vertical: v);

  EdgeInsets all(double value) => EdgeInsets.all(value);
}

/// Corner radii used by surfaces and controls.
@immutable
class PortalRadii {
  const PortalRadii({
    this.sm = 6,
    this.md = 10,
    this.lg = 14,
    this.xl = 20,
    this.full = 999,
  });

  final double sm;
  final double md;
  final double lg;
  final double xl;
  final double full;
}

/// Typography scale (font sizes). Pair with [TextTheme] in [buildPortalTheme].
@immutable
class PortalTypeScale {
  const PortalTypeScale({
    this.xs = 11,
    this.sm = 12,
    this.md = 14,
    this.lg = 16,
    this.xl = 18,
    this.xxl = 22,
  });

  final double xs;
  final double sm;
  final double md;
  final double lg;
  final double xl;
  final double xxl;
}

/// Typography *styles* — complete [TextStyle] definitions for semantic roles.
///
/// Customise by passing different values at construction or by subclassing
/// to add app-specific roles (e.g. `RecipeTextStyles extends PortalTextStyles`
/// adding a `sectionHeader` style).
@immutable
class PortalTextStyles {
  const PortalTextStyles({
    this.display = const TextStyle(
      fontSize: 34,
      fontWeight: FontWeight.w800,
      height: 1.15,
      letterSpacing: -0.5,
    ),
    this.headline = const TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.w700,
      height: 1.2,
      letterSpacing: -0.3,
    ),
    this.title = const TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w600,
      height: 1.25,
      letterSpacing: -0.2,
    ),
    this.subtitle = const TextStyle(
      fontSize: 17,
      fontWeight: FontWeight.w600,
      height: 1.3,
      letterSpacing: -0.1,
    ),
    this.body = const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.normal,
      height: 1.5,
      letterSpacing: 0.1,
    ),
    this.caption = const TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w500,
      height: 1.4,
      letterSpacing: 0.2,
    ),
    this.overline = const TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      height: 1.3,
      letterSpacing: 0.8,
    ),
  });

  final TextStyle display;
  final TextStyle headline;
  final TextStyle title;
  final TextStyle subtitle;
  final TextStyle body;
  final TextStyle caption;
  final TextStyle overline;
}

/// Motion tokens for consistent animation across the system.
@immutable
class PortalMotion {
  const PortalMotion({
    this.fast = const Duration(milliseconds: 150),
    this.medium = const Duration(milliseconds: 300),
    this.slow = const Duration(milliseconds: 500),
    this.staggerStep = const Duration(milliseconds: 60),
    this.listRevealDuration = const Duration(milliseconds: 280),
    this.standard = Curves.easeOutCubic,
    this.emphasized = Curves.easeInOutCubic,
  });

  final Duration fast;
  final Duration medium;
  final Duration slow;

  /// Delay between staggered list items.
  final Duration staggerStep;

  /// Duration for list item fade/slide reveal.
  final Duration listRevealDuration;

  final Curve standard;
  final Curve emphasized;
}

/// Elevation / shadow tokens.
///
/// This is an instance class (not static) so apps can **subclass** to
/// override shadow behaviour — e.g. a "flat" theme with no shadows, or an
/// app with coloured ambient shadows.
///
/// ```dart
/// class FlatElevation extends PortalElevation {
///   const FlatElevation();
///   @override
///   List<BoxShadow> card(Brightness brightness) => const [];
/// }
/// ```
@immutable
class PortalElevation {
  const PortalElevation();

  List<BoxShadow> soft(Brightness brightness) {
    return brightness == Brightness.dark
        ? [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
              spreadRadius: -2,
            ),
          ]
        : [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 24,
              offset: const Offset(0, 8),
              spreadRadius: -4,
            ),
          ];
  }

  List<BoxShadow> medium(Brightness brightness) {
    return brightness == Brightness.dark
        ? [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
              spreadRadius: -4,
            ),
          ]
        : [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 40,
              offset: const Offset(0, 16),
              spreadRadius: -8,
            ),
          ];
  }

  List<BoxShadow> card(Brightness brightness) {
    return brightness == Brightness.dark
        ? [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
              spreadRadius: -4,
            ),
          ]
        : [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 1),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 20,
              offset: const Offset(0, 8),
              spreadRadius: -6,
            ),
          ];
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DesignTokens — the root bundle
// ─────────────────────────────────────────────────────────────────────────────

/// Semantic layout tokens bundled for presets.
///
/// Apps can customise in three ways:
///
/// 1. **Constructor parameters** — override individual groups:
///    ```dart
///    const DesignTokens(
///      radii: PortalRadii(sm: 12, md: 16, lg: 24, xl: 32),
///      textStyles: PortalTextStyles(display: TextStyle(fontSize: 40)),
///    )
///    ```
///
/// 2. **Subclass for new token categories** — extend with domain-specific
///    groups that don't belong in core:
///    ```dart
///    class RecipeTokens extends DesignTokens {
///      const RecipeTokens({
///        super.spacing,
///        super.radii,
///        this.difficultyColors = const DifficultyColors(),
///      });
///      final DifficultyColors difficultyColors;
///    }
///    ```
///    Access in widgets: `(PortalUiTheme.of(context).tokens as RecipeTokens)`
///
/// 3. **Override elevation/shadow behaviour** by passing a custom
///    [PortalElevation] subclass.
@immutable
class DesignTokens {
  const DesignTokens({
    this.spacing = const PortalSpacing(),
    this.radii = const PortalRadii(),
    this.typeScale = const PortalTypeScale(),
    this.textStyles = const PortalTextStyles(),
    this.motion = const PortalMotion(),
    this.elevation = const PortalElevation(),
    this.layout = const PortalLayoutInsets(),
    this.minTapTarget = 44,
    this.borderWidth = 1,
    this.expressiveCorners = false,
  });

  final PortalSpacing spacing;
  final PortalRadii radii;
  final PortalTypeScale typeScale;
  final PortalTextStyles textStyles;
  final PortalMotion motion;
  final PortalElevation elevation;

  /// Page gutter, section gap and the clearance a floating nav needs.
  /// Read this instead of writing a literal inset at a call site.
  final PortalLayoutInsets layout;

  /// Minimum interactive dimension (accessibility).
  final double minTapTarget;

  final double borderWidth;

  /// When true, [applyPortalComponentThemes] uses [ContinuousRectangleBorder] for cards.
  final bool expressiveCorners;

  // ── Named presets ────────────────────────────────────────────────────────

  static const DesignTokens defaults = DesignTokens();

  static const DesignTokens compact = DesignTokens(
    spacing: PortalSpacing(
      xs: 3, sm: 6, md: 10, lg: 12, xl: 18, xxl: 24, xxxl: 36,
    ),
    radii: PortalRadii(sm: 4, md: 8, lg: 10, xl: 14),
    typeScale: PortalTypeScale(
      xs: 10, sm: 11, md: 13, lg: 15, xl: 17, xxl: 20,
    ),
    minTapTarget: 40,
  );

  static const DesignTokens rounded = DesignTokens(
    radii: PortalRadii(sm: 10, md: 16, lg: 20, xl: 28),
  );

  /// Warm, generous radii suited for content-heavy apps (recipes, media).
  static const DesignTokens generous = DesignTokens(
    radii: PortalRadii(sm: 12, md: 16, lg: 24, xl: 32),
  );

  /// Bold curves, stagger-friendly motion, continuous card corners.
  static const DesignTokens expressive = DesignTokens(
    radii: PortalRadii(sm: 12, md: 18, lg: 24, xl: 32),
    motion: PortalMotion(
      medium: Duration(milliseconds: 350),
      staggerStep: Duration(milliseconds: 60),
      listRevealDuration: Duration(milliseconds: 280),
    ),
    expressiveCorners: true,
  );
}
