import 'package:flutter/material.dart';

import '../motion/portal_spring_curve.dart';
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
    this.sm = 8,
    this.md = 12,
    this.lg = 20,
    this.xl = 28,
    this.full = 999,
  });

  final double sm;
  final double md;
  final double lg;
  final double xl;
  final double full;
}

/// Avatar diameters — a list row (`sm`), a bar or tile (`md`), a profile
/// header (`lg`). `PortalProgressRing` sizes itself to `lg` by default so a
/// ring and an avatar line up in the same row.
@immutable
class PortalAvatarSizes {
  const PortalAvatarSizes({this.sm = 32, this.md = 40, this.lg = 56});

  final double sm;
  final double md;
  final double lg;
}

/// Glyph sizes for an `Icon` that is not a component's own. The defaults are
/// finance's `AppIconSize` (`xs`..`xxxl`) plus the two steps task uses that
/// it lacks: `xxs` (12, a tag or a chevron) and `dense` (20, a row glyph).
@immutable
class PortalIconSizes {
  const PortalIconSizes({
    this.xxs = 12,
    this.xs = 14,
    this.sm = 16,
    this.md = 18,
    this.dense = 20,
    this.lg = 22,
    this.xl = 28,
    this.xxl = 36,
    this.xxxl = 44,
  });

  final double xxs;
  final double xs;
  final double sm;
  final double md;
  final double dense;
  final double lg;
  final double xl;
  final double xxl;
  final double xxxl;
}

/// Fixed component dimensions: control heights, card padding, the tile an
/// icon sits in, a progress track. The defaults are finance's `AppSizes`.
/// Hit areas are `minTapTarget`, never these: they size the paint.
@immutable
class PortalComponentSizes {
  const PortalComponentSizes({
    this.buttonHeightSm = 36,
    this.buttonHeightMd = 44,
    this.buttonHeightLg = 52,
    this.inputHeightMd = 48,
    this.inputHeightLg = 56,
    this.cardPaddingSm = 14,
    this.cardPaddingMd = 18,
    this.cardPaddingLg = 22,
    this.iconContainerSm = 36,
    this.iconContainerMd = 44,
    this.iconContainerLg = 52,
    this.iconContainerXl = 60,
    this.trackHeight = 6,
    this.trackHeightSm = 4,
    this.dotSm = 6,
  });

  final double buttonHeightSm;
  final double buttonHeightMd;
  final double buttonHeightLg;
  final double inputHeightMd;
  final double inputHeightLg;
  final double cardPaddingSm;
  final double cardPaddingMd;
  final double cardPaddingLg;

  /// The tile an icon sits in (an index tab, a list leading).
  final double iconContainerSm;
  final double iconContainerMd;
  final double iconContainerLg;
  final double iconContainerXl;

  /// A progress track; `trackHeightSm` for a thin meter inside a row.
  final double trackHeight;
  final double trackHeightSm;

  /// A legend mark: the dot before a series label.
  final double dotSm;
}

/// Typography scale (font sizes and typeface). Pair with [TextTheme] in
/// [buildPortalTheme].
@immutable
class PortalTypeScale {
  const PortalTypeScale({
    this.xs = 11,
    this.sm = 12,
    this.md = 14,
    this.lg = 16,
    this.xl = 18,
    this.xxl = 22,
    this.fontFamily = defaultFontFamily,
  });

  /// Plus Jakarta Sans, bundled with this package. This is Flutter's
  /// package-font key, so it resolves from any app that depends on ui_core
  /// without the app declaring a font of its own.
  static const String defaultFontFamily =
      'packages/portal_ui_core/PlusJakartaSans';

  final double xs;
  final double sm;
  final double md;
  final double lg;
  final double xl;
  final double xxl;

  /// Typeface [buildPortalTheme] sets on [ThemeData.fontFamily]. Fills every
  /// text style that does not name its own family, so a per-style override
  /// (a serif heading, say) still wins. `null` leaves the platform default.
  final String? fontFamily;
}

/// Typography *styles* — complete [TextStyle] definitions for semantic roles.
///
/// Every style carries a `height`: 1.1 for the two figure sizes, 1.2 for
/// headings, 1.5 for reading text, 1.4 for the small labels. [emphasized]
/// and [numeric] derive a variant from any of them.
///
/// Customise by passing different values at construction or by subclassing
/// to add app-specific roles (e.g. `RecipeTextStyles extends PortalTextStyles`
/// adding a `sectionHeader` style).
@immutable
class PortalTextStyles {
  const PortalTextStyles({
    this.hero = const TextStyle(
      fontSize: 44,
      fontWeight: FontWeight.w800,
      height: 1.1,
      letterSpacing: -1.0,
    ),
    this.display = const TextStyle(
      fontSize: 34,
      fontWeight: FontWeight.w800,
      height: 1.1,
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
      height: 1.2,
      letterSpacing: -0.2,
    ),
    this.subtitle = const TextStyle(
      fontSize: 17,
      fontWeight: FontWeight.w600,
      height: 1.25,
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
      height: 1.4,
      letterSpacing: 0.8,
    ),
  });

  /// One figure that owns the screen — a balance, a stat page's headline
  /// number. Above [display]; pair with [numeric] when it holds digits.
  final TextStyle hero;
  final TextStyle display;
  final TextStyle headline;
  final TextStyle title;
  final TextStyle subtitle;
  final TextStyle body;
  final TextStyle caption;
  final TextStyle overline;

  /// [style] one weight heavier and tracked 0.2 tighter — a selected tab, the
  /// current value in a list of values. Already `w900` stays `w900`.
  TextStyle emphasized(TextStyle style) {
    final weight = style.fontWeight ?? FontWeight.normal;
    final heavier =
        weight.value >= 900 ? weight : FontWeight(weight.value + 100);
    return style.copyWith(
      fontWeight: heavier,
      letterSpacing: (style.letterSpacing ?? 0) - 0.2,
    );
  }

  /// [style] with tabular figures, so digits share a width and a counter or
  /// a column of amounts does not jitter as the values change.
  TextStyle numeric(TextStyle style) => style.copyWith(
        fontFeatures: [
          ...?style.fontFeatures,
          const FontFeature.tabularFigures(),
        ],
      );
}

/// Motion tokens for consistent animation across the system.
///
/// Springs follow the M3 Expressive scheme. *Spatial* springs move and resize
/// things and overshoot a little on the way in; *effects* springs (damping
/// ratio 1) fade and recolour and never pass their target, so they are the
/// safe choice for anything that asserts on `0..1` — `Opacity`, shadow and
/// padding lerps, the `animations` package. Wrap one in [PortalSpringCurve]
/// for an implicit animation, or hand it to `AnimationController.animateWith`
/// as a `SpringSimulation`.
@immutable
class PortalMotion {
  const PortalMotion({
    this.fast = const Duration(milliseconds: 150),
    this.medium = const Duration(milliseconds: 300),
    this.slow = const Duration(milliseconds: 500),
    this.staggerStep = const Duration(milliseconds: 60),
    this.listRevealDuration = const Duration(milliseconds: 280),
    this.pressScale = 0.97,
    Curve? standard,
    Curve? emphasized,
  })  : _standard = standard,
        _emphasized = emphasized;

  final Duration fast;
  final Duration medium;
  final Duration slow;

  /// Delay between staggered list items.
  final Duration staggerStep;

  /// Duration for list item fade/slide reveal.
  final Duration listRevealDuration;

  /// Scale a `PortalPressable` shrinks to while held. 1 disables the press.
  final double pressScale;

  // Static because `SpringDescription.withDampingRatio` is not const and this
  // class has to stay const-constructible for `DesignTokens`.
  static final SpringDescription spatialFast = _spring(800, .6);
  static final SpringDescription spatialDefault = _spring(380, .8);
  static final SpringDescription spatialSlow = _spring(200, .8);
  static final SpringDescription effectsFast = _spring(3800, 1);
  static final SpringDescription effectsDefault = _spring(1600, 1);
  static final SpringDescription effectsSlow = _spring(800, 1);

  static SpringDescription _spring(double stiffness, double ratio) =>
      SpringDescription.withDampingRatio(
        mass: 1,
        stiffness: stiffness,
        ratio: ratio,
      );

  /// [spatialDefault] as a curve. Pair it with its own settle time:
  /// `AnimatedSlide(duration: PortalMotion.spatial.duration, curve: PortalMotion.spatial)`.
  static final PortalSpringCurve spatial = PortalSpringCurve(spatialDefault);

  /// [effectsDefault] as a curve; never overshoots. Same pairing as [spatial].
  static final PortalSpringCurve effects = PortalSpringCurve(effectsDefault);

  final Curve? _standard;
  final Curve? _emphasized;

  /// Kept from the easing era, now [effects]: a decelerating spring that
  /// never overshoots, so every existing caller keeps working.
  Curve get standard => _standard ?? effects;

  /// Kept from the easing era, now [spatial]: overshoots, for movement only.
  Curve get emphasized => _emphasized ?? spatial;
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

/// The three gradients the fleet actually draws, built from the scheme so
/// they follow a theme change. Everything else was one of 38 ad-hoc
/// `LinearGradient`s in app code.
@immutable
class PortalGradients {
  const PortalGradients();

  /// A faint top-left light on a surface: `onSurface` at 4% fading to
  /// nothing. Layered *over* the surface colour, never instead of it.
  LinearGradient surfaceSheen(ColorScheme scheme) => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          scheme.onSurface.withValues(alpha: 0.04),
          scheme.onSurface.withValues(alpha: 0),
        ],
      );

  /// Brand fill for a hero or a highlighted card: `primary` →
  /// `primaryContainer` at 135° (top-left to bottom-right).
  LinearGradient accent(ColorScheme scheme) => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [scheme.primary, scheme.primaryContainer],
      );

  /// Legibility scrim for text over an image: `scrim` at 60% rising from
  /// the bottom edge to nothing.
  LinearGradient imageScrim(ColorScheme scheme) => LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [
          scheme.scrim.withValues(alpha: 0.6),
          scheme.scrim.withValues(alpha: 0),
        ],
      );
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
    this.gradients = const PortalGradients(),
    this.layout = const PortalLayoutInsets(),
    this.avatarSizes = const PortalAvatarSizes(),
    this.iconSizes = const PortalIconSizes(),
    this.componentSizes = const PortalComponentSizes(),
    this.minTapTarget = 48,
    this.borderWidth = 1,
    this.expressiveCorners = true,
  });

  final PortalSpacing spacing;
  final PortalRadii radii;
  final PortalTypeScale typeScale;
  final PortalTextStyles textStyles;
  final PortalMotion motion;
  final PortalElevation elevation;
  final PortalGradients gradients;

  /// Page gutter, section gap and the clearance a floating nav needs.
  /// Read this instead of writing a literal inset at a call site.
  final PortalLayoutInsets layout;

  /// Avatar diameters; see [PortalAvatarSizes].
  final PortalAvatarSizes avatarSizes;

  /// Icon glyph sizes; see [PortalIconSizes].
  final PortalIconSizes iconSizes;

  /// Control heights, card padding, icon tiles, tracks; see
  /// [PortalComponentSizes].
  final PortalComponentSizes componentSizes;

  /// Minimum interactive dimension: 48, the Android and M3 floor, in every
  /// preset. It sizes the *hit area*, never the paint — put it in a
  /// `SizedBox` around the painted box (see `UI_PATTERNS.md`).
  final double minTapTarget;

  final double borderWidth;

  /// When true (the default), cards use a [ContinuousRectangleBorder] — the
  /// squircle — instead of a plain rounded rect.
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
    // 48 even here: Android and M3 both floor a hit area at 48×48dp with
    // 8dp between targets, and density is the paint's business, not the hit
    // area's (F1).
    minTapTarget: 48,
  );

  static const DesignTokens rounded = DesignTokens(
    radii: PortalRadii(sm: 10, md: 16, lg: 24, xl: 32),
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
