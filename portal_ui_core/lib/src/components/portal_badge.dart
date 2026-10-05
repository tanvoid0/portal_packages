import 'package:flutter/material.dart';

import '../theme/portal_component_extensions.dart';
import '../theme/portal_semantic_colors.dart';
import '../theme/portal_ui_theme.dart';

/// Which colour a [PortalBadge] speaks in.
enum PortalBadgeTone {
  neutral,
  primary,
  secondary,
  success,
  warning,
  danger,
  info,
}

/// Status label: Paid, Overdue, In progress.
///
/// A tinted pill: the tone at a low alpha behind the tone as text, so it reads
/// on glass and solid surfaces alike. [outlined] adds a hairline in the tone
/// for a status that must not read by colour alone. Not [PortalCountBadge],
/// which sits on another widget's corner; this one is a word. Re-skin
/// app-wide with [PortalBadgeTheme].
class PortalBadge extends StatelessWidget {
  const PortalBadge({
    super.key,
    required this.label,
    this.tone = PortalBadgeTone.neutral,
    this.icon,
    this.leading,
    this.outlined = false,
    this.foregroundColor,
    this.backgroundColor,
  });

  final String label;
  final PortalBadgeTone tone;
  final IconData? icon;

  /// Any glyph (a `FaIcon`, an SVG) in place of [icon]; it paints itself, so
  /// size and tint it with the ink [PortalBadge] sets through `IconTheme`.
  final Widget? leading;
  final bool outlined;

  /// Replaces the tone's colour, for a domain hue the semantic set lacks
  /// (a journey status). The tint behind it is derived unless
  /// [backgroundColor] is set.
  final Color? foregroundColor;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final portal = PortalUiTheme.of(context);
    final tokens = portal.tokens;
    final skin = PortalBadgeTheme.of(context);
    final semantic = PortalSemanticColors.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;

    final toned = switch (tone) {
      PortalBadgeTone.neutral => portal.onMuted,
      PortalBadgeTone.primary => portal.primary,
      PortalBadgeTone.secondary => portal.secondary,
      PortalBadgeTone.success => semantic.success,
      PortalBadgeTone.warning => semantic.warning,
      PortalBadgeTone.danger => semantic.danger,
      PortalBadgeTone.info => semantic.info,
    };
    final fg = foregroundColor ?? toned;
    final bg = backgroundColor ??
        (tone == PortalBadgeTone.neutral && foregroundColor == null
            ? portal.muted
            : fg.withValues(alpha: skin.tintAlpha ?? (dark ? 0.22 : 0.14)));

    final style = (skin.textStyle ??
            tokens.textStyles.caption.copyWith(fontWeight: FontWeight.w600))
        .copyWith(color: fg);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: bg,
        borderRadius:
            skin.borderRadius ?? BorderRadius.circular(tokens.radii.full),
        border:
            outlined ? Border.all(color: fg, width: tokens.borderWidth) : null,
      ),
      child: Padding(
        padding: skin.padding ??
            EdgeInsets.symmetric(
              horizontal: tokens.spacing.md,
              vertical: tokens.spacing.xs,
            ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (leading != null) ...[
              IconTheme.merge(
                data: IconThemeData(color: fg, size: tokens.typeScale.sm),
                child: leading!,
              ),
              SizedBox(width: tokens.spacing.xs),
            ] else if (icon != null) ...[
              Icon(icon, size: tokens.typeScale.sm, color: fg),
              SizedBox(width: tokens.spacing.xs),
            ],
            Flexible(child: Text(label, style: style)),
          ],
        ),
      ),
    );
  }
}
