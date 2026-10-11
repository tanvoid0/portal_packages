import 'package:flutter/material.dart';

import '../theme/portal_ui_theme.dart';
import 'portal_pressable.dart';
import 'portal_skeleton.dart';

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
    this.overline = false,
    this.headerValue,
  })  : assert(
          headerValue == null ||
              (trailing == null && actionLabel == null),
          'a header value is not a control: never with trailing or an action',
        ),
        _skeleton = false;

  /// Shaped like the header: a skeleton bar in place of [title], and one
  /// beside it in place of [headerValue] when [hasValue].
  const PortalSectionHeader.skeleton({super.key, bool hasValue = false})
      : title = '',
        icon = null,
        trailing = null,
        foregroundColor = null,
        iconColor = null,
        caption = null,
        actionLabel = null,
        onAction = null,
        overline = false,
        headerValue = hasValue ? '' : null,
        _skeleton = true;

  final String title;

  /// Renders the title as a small uppercase-style eyebrow
  /// (`tokens.textStyles.overline`, muted by default) instead of the
  /// `subtitle` role — for a filter-group label or a quiet section cue. The
  /// caller still supplies the copy's casing.
  final bool overline;

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

  /// A muted row-size value at the end, preformatted — a day's net, a
  /// group's total. Read with the title as one header. Not a control: never
  /// with [trailing] or [actionLabel].
  final String? headerValue;

  final bool _skeleton;

  @override
  Widget build(BuildContext context) {
    final portal = PortalUiTheme.of(context);
    final tokens = portal.tokens;
    final ink = foregroundColor ??
        (overline ? portal.onSurfaceVariant : portal.onSurface);
    final style = (overline ? tokens.textStyles.overline : tokens.textStyles.subtitle)
        .copyWith(color: ink);

    if (_skeleton) {
      return ExcludeSemantics(
        child: Row(
          children: [
            Expanded(child: PortalSkeleton(height: style.fontSize ?? 16, width: 120)),
            if (headerValue != null) ...[
              SizedBox(width: tokens.spacing.sm),
              PortalSkeleton(height: style.fontSize ?? 16, width: 48),
            ],
          ],
        ),
      );
    }

    final heading = Text(title, style: style);
    final action = actionLabel;

    if (headerValue case final value?) {
      return Semantics(
        header: true,
        label: '$title, $value',
        child: ExcludeSemantics(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              if (icon != null) ...[
                Icon(icon, size: style.fontSize, color: iconColor ?? ink),
                SizedBox(width: tokens.spacing.sm),
              ],
              Expanded(child: heading),
              SizedBox(width: tokens.spacing.sm),
              Text(
                value,
                maxLines: 1,
                softWrap: false,
                style: tokens.textStyles.body.copyWith(
                  fontWeight: FontWeight.w500,
                  color: portal.onSurfaceVariant,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
      );
    }

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
