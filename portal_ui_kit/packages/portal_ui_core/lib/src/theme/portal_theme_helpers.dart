import 'package:flutter/material.dart';

import '../tokens/design_tokens.dart';
import 'portal_theme_palette.dart';
import 'portal_theme_palette_id.dart';
import 'portal_ui_theme.dart';

/// Shorthand for [PortalUiTheme.of].
extension PortalThemeContext on BuildContext {
  PortalUiTheme get portalTheme => PortalUiTheme.of(this);
  DesignTokens get portalTokens => portalTheme.tokens;
}

/// Shared [InputDecoration] for Portal form controls — mirrors shadcn input styling.
InputDecoration portalInputDecoration(
  BuildContext context, {
  String? label,
  String? hint,
  String? helper,
  String? errorText,
  Widget? prefix,
  Widget? suffix,
  bool enabled = true,
}) {
  final portal = PortalUiTheme.of(context);
  final t = portal.tokens;
  final scheme = Theme.of(context).colorScheme;
  final radius = BorderRadius.circular(t.radii.md);
  final baseBorder = OutlineInputBorder(
    borderRadius: radius,
    borderSide: portal.borderSide(),
  );

  return InputDecoration(
    isDense: true,
    labelText: label,
    hintText: hint,
    helperText: helper,
    errorText: errorText,
    prefixIcon: prefix == null
        ? null
        : Padding(
            padding: EdgeInsets.only(left: t.spacing.sm, right: t.spacing.xs),
            child: prefix,
          ),
    suffixIcon: suffix,
    filled: true,
    fillColor: portal.input,
    contentPadding: EdgeInsets.symmetric(
      horizontal: t.spacing.lg,
      vertical: t.spacing.md,
    ),
    border: baseBorder,
    enabledBorder: baseBorder,
    focusedBorder: OutlineInputBorder(
      borderRadius: radius,
      borderSide: portal.inputFocusBorderSide(),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: radius,
      borderSide: BorderSide(color: scheme.error, width: t.borderWidth),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: radius,
      borderSide: BorderSide(color: scheme.error, width: t.borderWidth + 0.5),
    ),
    disabledBorder: OutlineInputBorder(
      borderRadius: radius,
      borderSide: portal.subtleBorderSide(),
    ),
    labelStyle: TextStyle(color: portal.onSurfaceVariant),
    hintStyle: TextStyle(
      color: portal.mutedForeground.withValues(alpha: 0.85),
    ),
  );
}

/// Visible keyboard focus ring (shadcn `ring`) around [child].
///
/// Pass the same [focusNode] to the focusable control inside [child].
class PortalFocusRing extends StatelessWidget {
  const PortalFocusRing({
    required this.child,
    required this.focusNode,
    super.key,
    this.borderRadius,
    this.padding = 2,
  });

  final Widget child;
  final FocusNode focusNode;
  final BorderRadius? borderRadius;
  final double padding;

  @override
  Widget build(BuildContext context) {
    final portal = PortalUiTheme.of(context);
    final radius = borderRadius ?? BorderRadius.circular(portal.tokens.radii.md);

    return ListenableBuilder(
      listenable: focusNode,
      builder: (context, _) {
        final focused = focusNode.hasFocus;
        return AnimatedContainer(
          duration: portal.tokens.motion.fast,
          curve: Curves.easeOut,
          padding: EdgeInsets.all(focused ? padding : 0),
          decoration: BoxDecoration(
            borderRadius: radius,
            border: focused
                ? Border.fromBorderSide(portal.focusBorderSide())
                : null,
          ),
          child: child,
        );
      },
    );
  }
}

/// Scrollbar theme values aligned with shadcn_ui defaults.
ScrollbarThemeData portalScrollbarTheme(PortalUiTheme portal) {
  return ScrollbarThemeData(
    crossAxisMargin: 1,
    mainAxisMargin: 1,
    thickness: const WidgetStatePropertyAll(8),
    radius: const Radius.circular(999),
    thumbColor: WidgetStatePropertyAll(portal.border),
  );
}

/// [base] with only its primary family replaced by one derived from [seed].
///
/// For an app whose [ColorScheme] is hand-tuned rather than generated: it lets
/// the user pick an accent without giving up the surfaces someone chose on
/// purpose. Surfaces, neutrals, secondary, tertiary and error are untouched —
/// a palette picks an accent, not a new skin. Rebuilding the whole scheme from
/// the seed is the obvious move and the wrong one: it moves every surface too,
/// which turns a settings toggle into a restyle.
///
/// The five roles come from Material's own algorithm, so the contrast pairs
/// are correct for any seed. That is the half that is easy to get wrong by
/// hand and the reason this does not just set `primary`.
///
/// Contrast *against the app's own surfaces* is the part no algorithm here can
/// check — a seed tuned for Material's neutrals may sit differently on a hand
/// -picked canvas. Look at a light seed and a dark one, in both brightnesses,
/// before shipping a new palette.
ColorScheme portalSchemeWithSeed(ColorScheme base, Color seed) {
  final derived = ColorScheme.fromSeed(
    seedColor: seed,
    brightness: base.brightness,
  );
  return base.copyWith(
    primary: derived.primary,
    onPrimary: derived.onPrimary,
    primaryContainer: derived.primaryContainer,
    onPrimaryContainer: derived.onPrimaryContainer,
    inversePrimary: derived.inversePrimary,
  );
}

/// The seed colour a stored palette id names, or null if it names nothing.
///
/// Null covers both "the user never picked one" and "the id came from a build
/// with palettes this one does not have" — either way the app keeps its own
/// hand-tuned accent rather than falling back to some other app's default.
/// Pair with [portalSchemeWithSeed].
Color? portalSeedForPaletteId(String? paletteId) {
  if (paletteId == null || paletteId.isEmpty) return null;
  for (final id in PortalThemePaletteId.values) {
    if (id.name == paletteId) return PortalThemeCatalog.byId(id).seedColor;
  }
  return null;
}
