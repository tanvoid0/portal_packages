import 'package:flutter/material.dart';

import '../theme/portal_ui_theme.dart';
import 'portal_pressable.dart';

/// A titled break inside a scroll page.
///
/// Extracted from portal_gym so every app labels its sections the same way.
/// Type comes from `tokens.textStyles.subtitle` — an app that wants a heavier
/// or tighter section title changes it once, in its token bundle, not here.
class PortalSectionHeader extends StatelessWidget {
  const PortalSectionHeader({
    super.key,
    required this.title,
    this.icon,
    this.trailing,
    this.foregroundColor,
    this.iconColor,
    this.caption,
    this.actionLabel,
    this.onAction,
  });

  final String title;

  /// Optional leading glyph. Sized to the title's line, not a fixed constant.
  final IconData? icon;

  /// Right-aligned affordance — a "See all", a count, an action.
  final Widget? trailing;

  /// Overrides icon and title colour. Defaults to `onSurface`.
  final Color? foregroundColor;

  /// Colours the [icon] alone, leaving the title on [foregroundColor]. For a
  /// status glyph — a green check on a done section — that must not tint the
  /// title. Defaults to the title's colour.
  final Color? iconColor;

  /// Muted secondary line under the [title] — a date bucket, a count.
  final String? caption;

  /// A text action on the title's line ("See all"), named by its own label.
  /// Renders in the trailing slot with a `minTapTarget` hit area; an explicit
  /// [trailing] wins over it. A null [onAction] draws it disabled.
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final portal = PortalUiTheme.of(context);
    final tokens = portal.tokens;
    final ink = foregroundColor ?? portal.onSurface;
    final style = tokens.textStyles.subtitle.copyWith(color: ink);

    final heading = Text(title, style: style);
    final action = actionLabel;

    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: style.fontSize, color: iconColor ?? ink),
          SizedBox(width: tokens.spacing.sm),
        ],
        Expanded(
          child: caption == null
              ? heading
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    heading,
                    Text(
                      caption!,
                      style: tokens.textStyles.caption
                          .copyWith(color: portal.onSurfaceVariant),
                    ),
                  ],
                ),
        ),
        if (trailing != null)
          trailing!
        else if (action != null)
          PortalPressable(
            onTap: onAction,
            // A null handler is a disabled action, not plain text.
            button: true,
            enabled: onAction != null,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: tokens.minTapTarget,
                minHeight: tokens.minTapTarget,
              ),
              child: Center(
                widthFactor: 1,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: tokens.spacing.xs),
                  child: Text(
                    action,
                    style: tokens.textStyles.body.copyWith(
                      fontWeight: tokens.textStyles.subtitle.fontWeight,
                      color: onAction == null
                          ? portal.onSurfaceVariant
                          : portal.primary,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
