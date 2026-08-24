import 'package:flutter/material.dart';
import '../theme/portal_ui_theme.dart';
import '../theme/portal_typography.dart';
import '../tokens/design_tokens.dart';

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
  });

  final String label;
  final VoidCallback? onPressed;
  final PortalButtonVariant variant;
  final PortalButtonSize size;
  final Widget? leading;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final portal = PortalUiTheme.of(context);
    final tokens = portal.tokens;
    final (hPad, vPad, radius, labelFontSize) = _metrics(tokens);
    final style = _styleFor(portal);
    final textStyle = portalControlLabelStyle(
      labelFontSize,
      color: style.foreground,
    );

    final showLabel = label.isNotEmpty;
    final content = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (leading != null) ...[
          leading!,
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

    final effectiveOnPressed = onPressed;
    if (effectiveOnPressed == null) {
      return _shell(
        border: style.border,
        background: style.background,
        radius: radius,
        hPad: hPad,
        vPad: vPad,
        minSize: tokens.minTapTarget,
        child: styled,
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: effectiveOnPressed,
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
            padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: tokens.minTapTarget,
                minWidth: tokens.minTapTarget,
              ),
              child: Align(
                alignment: Alignment.center,
                heightFactor: 1,
                widthFactor: expand ? null : 1,
                child: styled,
              ),
            ),
          ),
        ),
      ),
    );
  }

  (double, double, double, double) _metrics(DesignTokens tokens) {
    switch (size) {
      case PortalButtonSize.sm:
        return (
          tokens.spacing.md,
          tokens.spacing.sm,
          tokens.radii.sm,
          tokens.typeScale.sm,
        );
      case PortalButtonSize.md:
        return (
          tokens.spacing.lg,
          tokens.spacing.md,
          tokens.radii.md,
          tokens.typeScale.md,
        );
      case PortalButtonSize.lg:
        return (
          tokens.spacing.xl,
          tokens.spacing.lg,
          tokens.radii.lg,
          tokens.typeScale.lg,
        );
    }
  }

  _ButtonStyle _styleFor(PortalUiTheme portal) {
    switch (variant) {
      case PortalButtonVariant.primary:
        return _ButtonStyle(
          background: portal.primary,
          foreground: portal.onPrimary,
          border: null,
        );
      case PortalButtonVariant.secondary:
        return _ButtonStyle(
          background: portal.secondary,
          foreground: portal.onSecondary,
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

  Widget _shell({
    required Widget child,
    required Color background,
    required double radius,
    required double hPad,
    required double vPad,
    required double minSize,
    required Border? border,
  }) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(radius),
        border: border,
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: minSize, minWidth: minSize),
          child: Align(
            alignment: Alignment.center,
            heightFactor: 1,
            widthFactor: expand ? null : 1,
            child: child,
          ),
        ),
      ),
    );
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
