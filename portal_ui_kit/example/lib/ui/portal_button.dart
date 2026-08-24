import 'package:flutter/material.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

enum PortalButtonVariant { primary, secondary, outline, destructive, ghost }

enum PortalButtonSize { sm, md, lg }

class PortalButton extends StatefulWidget {
  const PortalButton({
    required this.label,
    super.key,
    this.onPressed,
    this.variant = PortalButtonVariant.primary,
    this.size = PortalButtonSize.md,
    this.leading,
    this.expand = false,
    this.isLoading = false,
    this.focusNode,
  });

  final String label;
  final VoidCallback? onPressed;
  final PortalButtonVariant variant;
  final PortalButtonSize size;
  final Widget? leading;
  final bool expand;
  final bool isLoading;
  final FocusNode? focusNode;

  @override
  State<PortalButton> createState() => _PortalButtonState();
}

class _PortalButtonState extends State<PortalButton> {
  FocusNode? _ownedFocusNode;

  FocusNode get _focusNode => widget.focusNode ?? _ownedFocusNode!;

  @override
  void initState() {
    super.initState();
    if (widget.focusNode == null) {
      _ownedFocusNode = FocusNode();
    }
  }

  @override
  void dispose() {
    _ownedFocusNode?.dispose();
    super.dispose();
  }

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
    final borderRadius = BorderRadius.circular(radius);

    final content = Row(
      mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.isLoading) ...[
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: style.foreground,
            ),
          ),
          SizedBox(width: tokens.spacing.sm),
        ] else if (widget.leading != null) ...[
          widget.leading!,
          SizedBox(width: tokens.spacing.sm),
        ],
        Text(widget.label, style: textStyle, textAlign: TextAlign.center),
      ],
    );

    final styled = DefaultTextStyle.merge(
      style: textStyle,
      child: IconTheme.merge(
        data: IconThemeData(color: style.foreground, size: 18),
        child: content,
      ),
    );

    final effectiveOnPressed = widget.isLoading ? null : widget.onPressed;
    final buttonChild = Padding(
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: tokens.minTapTarget,
          minWidth: tokens.minTapTarget,
        ),
        child: Center(child: styled),
      ),
    );

    Widget interactive;
    if (effectiveOnPressed == null) {
      interactive = _shell(
        border: style.border,
        background: style.background,
        radius: radius,
        child: buttonChild,
      );
    } else {
      interactive = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: effectiveOnPressed,
          focusNode: _focusNode,
          borderRadius: borderRadius,
          splashColor: portal.primary.withValues(alpha: 0.12),
          highlightColor: portal.primary.withValues(alpha: 0.06),
          child: Ink(
            decoration: BoxDecoration(
              color: style.background,
              borderRadius: borderRadius,
              border: style.border,
            ),
            child: buttonChild,
          ),
        ),
      );
    }

    if (effectiveOnPressed == null) return interactive;

    return PortalFocusRing(
      focusNode: _focusNode,
      borderRadius: borderRadius,
      child: interactive,
    );
  }

  (double, double, double, double) _metrics(DesignTokens tokens) {
    switch (widget.size) {
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
    switch (widget.variant) {
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
          background: portal.background,
          foreground: portal.foreground,
          border: Border.fromBorderSide(portal.borderSide()),
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
          foreground: portal.foreground,
          border: null,
        );
    }
  }

  Widget _shell({
    required Widget child,
    required Color background,
    required double radius,
    required Border? border,
  }) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(radius),
        border: border,
      ),
      child: child,
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
