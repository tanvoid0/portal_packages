import 'package:flutter/material.dart';
import '../theme/portal_ui_theme.dart';
import '../theme/portal_typography.dart';
import '../tokens/design_tokens.dart';
import 'portal_pressable.dart';
import 'portal_text.dart';

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
    this.busyLabel,
    this.backgroundColor,
    this.foregroundColor,
  })  : tooltip = null,
        selected = null,
        _circular = false;

  /// A circular icon-only button, [size] across (36 / 48 / 56). [tooltip] is
  /// required: it is the only name a screen reader gets.
  ///
  /// The glyph is [icon] or, for a `FaIcon` / SVG, [iconWidget] (exactly one).
  /// [selected] makes it a toggle (a favourite): true fills the glyph and
  /// tints the button `primaryContainer`, and a screen reader hears the state;
  /// null (default) is a plain button. Write [tooltip] for the action, not the
  /// state, or flip it with the state ("Add to favourites" / "Remove ...").
  PortalButton.icon({
    IconData? icon,
    Widget? iconWidget,
    required String this.tooltip,
    this.selected,
    super.key,
    this.onPressed,
    this.variant = PortalButtonVariant.secondary,
    this.size = PortalButtonSize.md,
    this.isLoading = false,
    this.backgroundColor,
    this.foregroundColor,
  })  : assert((icon == null) != (iconWidget == null),
            'pass exactly one of icon and iconWidget'),
        label = '',
        busyLabel = null,
        leading = iconWidget ?? Icon(icon, fill: selected == true ? 1 : 0),
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

  /// What the button says while [isLoading]: it replaces [label] and a screen
  /// reader announces the change ("Saving"). Null keeps [label] throughout.
  final String? busyLabel;

  /// Replace the variant's fill and ink for this one button; the widget beats
  /// the theme. Pick a pair that contrasts.
  final Color? backgroundColor;
  final Color? foregroundColor;

  /// The accessible name of the [PortalButton.icon] form.
  final String? tooltip;

  /// Toggle state of the [PortalButton.icon] form; null when not a toggle.
  final bool? selected;
  final bool _circular;

  @override
  Widget build(BuildContext context) {
    final portal = PortalUiTheme.of(context);
    final tokens = portal.tokens;
    final (hPad, _, labelFontSize) = _metrics(tokens);
    final painted = _paintedHeight;
    final tap = painted < tokens.minTapTarget ? tokens.minTapTarget : painted;
    final scheme = Theme.of(context).colorScheme;
    final base = selected == true
        ? _ButtonStyle(
            background: scheme.primaryContainer,
            foreground: scheme.onPrimaryContainer,
          )
        : _styleFor(portal, scheme);
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
    final busyName = isLoading ? busyLabel : null;
    final leadingWidget = isLoading
        ? SizedBox(
            width: labelFontSize,
            height: labelFontSize,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: style.foreground,
              // Reduce motion: a still arc instead of one that spins forever,
              // and no "25%" read out for it.
              value: MediaQuery.disableAnimationsOf(context) ? .25 : null,
              semanticsValue: '',
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
            // Shrinks a long or translated label to fit before it ellipsizes,
            // so the word stays readable on a narrow button.
            child: PortalText(
              busyName ?? label,
              style: textStyle,
              textAlign: TextAlign.center,
              minFontSize: 11,
            ),
          ),
      ],
    );

    final styled = DefaultTextStyle.merge(
      style: textStyle,
      child: IconTheme.merge(
        data: IconThemeData(color: style.foreground, size: 18),
        child: busyName == null
            ? content
            : Semantics(liveRegion: true, child: content),
      ),
    );

    // Ripple stays (it is what a button feels like); the press scale rides on
    // top. `Ink` rather than a DecoratedBox so the splash paints over the fill.
    final button = PortalPressable(
      onTap: onPressed,
      // A null handler is a disabled button, not plain content.
      enabled: !isLoading && onPressed != null,
      button: true,
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
              constraints:
                  BoxConstraints(minWidth: _circular ? 0 : tokens.minTapTarget),
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
    // a box around the paint rather than taller paint (`UI_PATTERNS.md`). A tap
    // in that margin presses the button too: the painted one wins its own area.
    Widget hit(Widget box) => GestureDetector(
          behavior: HitTestBehavior.opaque,
          excludeFromSemantics: true,
          onTap: isLoading ? null : onPressed,
          child: box,
        );
    if (_circular) {
      final target = Tooltip(
        message: tooltip!,
        child: hit(
            SizedBox(width: tap, height: tap, child: Center(child: button))),
      );
      return selected == null
          ? target
          : Semantics(selected: selected, child: target);
    }
    if (tap == painted) return button;
    return hit(SizedBox(
        height: tap,
        child: Center(widthFactor: expand ? null : 1, child: button)));
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
