import 'package:flutter/material.dart';
import '../theme/portal_ui_theme.dart';
import '../theme/portal_typography.dart';
import '../tokens/design_tokens.dart';
import 'portal_pressable.dart';

enum PortalButtonVariant { primary, secondary, outline, destructive, ghost }

enum PortalButtonSize { sm, md, lg }

class PortalButton extends StatelessWidget {
  const PortalButton({
    required this.label,
    super.key,
    this.onPressed,
    this.variant = PortalButtonVariant.primary,
    this.size = PortalButtonSize.md,
    this.leading,
    this.expand = false,
    this.isLoading = false,
    this.backgroundColor,
    this.foregroundColor,
  })  : tooltip = null,
        _circular = false;

  /// A circular icon-only button, [size] across (36 / 48 / 56). [tooltip] is
  /// required: it is the only name a screen reader gets.
  PortalButton.icon({
    required IconData icon,
    required String this.tooltip,
    super.key,
    this.onPressed,
    this.variant = PortalButtonVariant.secondary,
    this.size = PortalButtonSize.md,
    this.isLoading = false,
    this.backgroundColor,
    this.foregroundColor,
  })  : label = '',
        leading = Icon(icon),
        expand = false,
        _circular = true;

  final String label;
  final VoidCallback? onPressed;
  final PortalButtonVariant variant;
  final PortalButtonSize size;
  final Widget? leading;
  final bool expand;

  /// Swaps [leading] for a spinner and refuses taps. Use it for a submit that
  /// is in flight - a button left tappable during an async action is how you
  /// get two of whatever it creates.
  final bool isLoading;

  /// Replace the variant's fill and ink for this one button; the widget beats
  /// the theme. Pick a pair that contrasts.
  final Color? backgroundColor;
  final Color? foregroundColor;

  /// The accessible name of the [PortalButton.icon] form.
  final String? tooltip;
  final bool _circular;

  @override
  Widget build(BuildContext context) {
    final portal = PortalUiTheme.of(context);
    final tokens = portal.tokens;
    final (hPad, _, labelFontSize) = _metrics(tokens);
    final painted = _paintedHeight;
    final tap = painted < tokens.minTapTarget ? tokens.minTapTarget : painted;
    final base = _styleFor(portal, Theme.of(context).colorScheme);
    final style = _ButtonStyle(
      background: backgroundColor ?? base.background,
      foreground: foregroundColor ?? base.foreground,
      border: base.border,
    );
    // Filled buttons are pills; tonal, outlined and ghost keep a soft corner.
    final radius = switch (variant) {
      PortalButtonVariant.primary ||
      PortalButtonVariant.destructive =>
        tokens.radii.full,
      _ => _circular ? tokens.radii.full : tokens.radii.md,
    };
    final textStyle = portalControlLabelStyle(
      labelFontSize,
      color: style.foreground,
    );

    final showLabel = label.isNotEmpty;
    final leadingWidget = isLoading
        ? SizedBox(
            width: labelFontSize,
            height: labelFontSize,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: style.foreground,
            ),
          )
        : leading;
    final content = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (leadingWidget != null) ...[
          leadingWidget,
          if (showLabel) SizedBox(width: tokens.spacing.sm),
        ],
        if (showLabel)
          Flexible(
            fit: expand ? FlexFit.tight : FlexFit.loose,
            child: Text(
              label,
              style: textStyle,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
      ],
    );

    final styled = DefaultTextStyle.merge(
      style: textStyle,
      child: IconTheme.merge(
        data: IconThemeData(color: style.foreground, size: 18),
        child: content,
      ),
    );

    // Ripple stays (it is what a button feels like); the press scale rides on
    // top. `Ink` rather than a DecoratedBox so the splash paints over the fill.
    final button = PortalPressable(
      onTap: onPressed,
      enabled: !isLoading,
      ripple: true,
      borderRadius: BorderRadius.circular(radius),
      splashColor: portal.primary.withValues(alpha: 0.12),
      highlightColor: portal.primary.withValues(alpha: 0.06),
      child: Ink(
        decoration: BoxDecoration(
          color: style.background,
          borderRadius: BorderRadius.circular(radius),
          border: style.border,
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: _circular ? 0 : hPad),
          child: SizedBox(
            height: painted,
            width: _circular ? painted : null,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                  minWidth: _circular ? 0 : tokens.minTapTarget),
              child: Align(
                alignment: Alignment.center,
                widthFactor: expand ? null : 1,
                child: styled,
              ),
            ),
          ),
        ),
      ),
    );

    // A small button paints under the minimum tap target, so the hit area is
    // a box around the paint rather than taller paint (`UI_PATTERNS.md`).
    if (_circular) {
      return Tooltip(
        message: tooltip!,
        child: SizedBox(width: tap, height: tap, child: Center(child: button)),
      );
    }
    if (tap == painted) return button;
    return SizedBox(height: tap, child: Center(child: button));
  }

  /// The painted pill's height. The hit area is [DesignTokens.minTapTarget]
  /// around this, never grown into the paint (`UI_PATTERNS.md`). The 44dp
  /// box used to sit *inside* the padding, so md painted 68 and lg 76 where
  /// the kit paints 48 and 56 (batch K, K1).
  double get _paintedHeight => switch (size) {
    PortalButtonSize.sm => 36,
    PortalButtonSize.md => 48,
    PortalButtonSize.lg => 56,
  };

  /// Horizontal padding, vertical padding (unused since K1 fixed the painted
  /// height), and the label's size.
  (double, double, double) _metrics(DesignTokens tokens) {
    switch (size) {
      case PortalButtonSize.sm:
        return (tokens.spacing.md, tokens.spacing.sm, tokens.typeScale.sm);
      case PortalButtonSize.md:
        return (tokens.spacing.lg, tokens.spacing.md, tokens.typeScale.md);
      case PortalButtonSize.lg:
        return (tokens.spacing.xl, tokens.spacing.lg, tokens.typeScale.lg);
    }
  }

  _ButtonStyle _styleFor(PortalUiTheme portal, ColorScheme scheme) {
    switch (variant) {
      case PortalButtonVariant.primary:
        return _ButtonStyle(
          background: portal.primary,
          foreground: portal.onPrimary,
          border: null,
        );
      // One neutral fill across the fleet (batch K, K2). The scheme's
      // secondary role is brand in some apps -- grey in assistant, blue in
      // finance -- so the secondary button changed colour app to app where
      // the kit draws one. Read from the scheme rather than portal.accent,
      // which an app skin may point somewhere else. Brand stays on primary.
      case PortalButtonVariant.secondary:
        return _ButtonStyle(
          background: scheme.surfaceContainerHigh,
          foreground: scheme.onSurface,
          border: null,
        );
      case PortalButtonVariant.outline:
        return _ButtonStyle(
          background: portal.surface,
          foreground: portal.onSurface,
          border: Border.all(
            color: portal.outline,
            width: portal.tokens.borderWidth,
          ),
        );
      case PortalButtonVariant.destructive:
        return _ButtonStyle(
          background: portal.destructive,
          foreground: portal.onDestructive,
          border: null,
        );
      case PortalButtonVariant.ghost:
        return _ButtonStyle(
          background: Colors.transparent,
          foreground: portal.onSurface,
          border: null,
        );
    }
  }
}

class _ButtonStyle {
  const _ButtonStyle({
    required this.background,
    required this.foreground,
    this.border,
  });

  final Color background;
  final Color foreground;
  final Border? border;
}
