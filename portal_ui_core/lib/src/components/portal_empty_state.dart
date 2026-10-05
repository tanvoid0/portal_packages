import 'package:flutter/material.dart';

import '../theme/portal_component_extensions.dart';
import '../theme/portal_ui_theme.dart';
import 'portal_button.dart';
import 'portal_card.dart';

/// Nothing-here state — glyph, title, optional body, optional single action.
///
/// Three parts, and an empty state is unfinished without the first two (F4):
///
/// 1. **What goes here** — [title].
/// 2. **Why it is empty** — [message], and the three reasons read
///    differently: nothing created yet, filtered to nothing, or cleared on
///    purpose. "No results" does not say which.
/// 3. **The one way forward** — either [actionLabel]/[onAction] or, where
///    there is nothing to act on yet, an [example] of what will be here.
///
/// A filtered-to-nothing state offers *clear filters*, never *add*: the list
/// is not empty, the filter is. Pass the filter-clearing callback as
/// [onAction] and say so in the label.
///
/// The body is deliberately optional (a state on a page with its own
/// explanation does not repeat it) and the action deliberately singular: an
/// empty state that offers three ways forward is a menu, not an empty state.
class PortalEmptyState extends StatelessWidget {
  const PortalEmptyState({
    super.key,
    this.icon,
    this.iconWidget,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
    this.actionIcon,
    this.example,
    this.iconWellColor,
    this.inCard = true,
  }) : assert(icon != null || iconWidget != null, 'give an icon or iconWidget');

  final IconData? icon;

  /// Any glyph (a `FaIcon`, a logo) in place of [icon]; it paints its own
  /// colour and size. Wins over [icon].
  final Widget? iconWidget;
  final String title;
  final String? message;

  /// Both [actionLabel] and [onAction] must be set for the button to render.
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData? actionIcon;

  /// What will be here, shown instead of (or beside) an action on a first-run
  /// state — one sample row, card or chart, drawn at the size it will really
  /// be. Dim or label it in the caller if it should read as a sample; this
  /// slot only decides where it sits.
  final Widget? example;

  /// Circular well painted behind the glyph. Omit for a bare icon.
  final Color? iconWellColor;

  /// Wraps the content in a [PortalCard]. Set false when the state already
  /// sits inside a card or fills the page.
  final bool inCard;

  @override
  Widget build(BuildContext context) {
    final portal = PortalUiTheme.of(context);
    final tokens = portal.tokens;
    final skin = PortalEmptyStateTheme.of(context);
    final well = iconWellColor ?? skin.iconWellColor;
    final iconColor = skin.iconColor ?? portal.onSurfaceVariant;
    final iconSize = skin.iconSize ?? tokens.spacing.xxl;

    final glyph = iconWidget ?? Icon(icon, size: iconSize, color: iconColor);
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (well == null)
          glyph
        else
          CircleAvatar(
            radius: iconSize * 1.5,
            backgroundColor: well,
            child: glyph,
          ),
        SizedBox(height: tokens.spacing.md),
        Text(
          title,
          textAlign: TextAlign.center,
          style: tokens.textStyles.subtitle
              .copyWith(color: skin.titleColor ?? portal.onSurface),
        ),
        if (message != null) ...[
          SizedBox(height: tokens.spacing.xs),
          Text(
            message!,
            textAlign: TextAlign.center,
            // onSurfaceVariant, not an alpha of onSurface: an alpha ramp on a
            // glass card lands wherever the backdrop does and stops clearing
            // 4.5:1.
            style: tokens.textStyles.caption
                .copyWith(color: skin.messageColor ?? portal.onSurfaceVariant),
          ),
        ],
        if (example != null) ...[
          SizedBox(height: tokens.spacing.lg),
          example!,
        ],
        if (actionLabel != null && onAction != null) ...[
          SizedBox(height: tokens.spacing.lg),
          PortalButton(
            label: actionLabel!,
            leading: actionIcon == null ? null : Icon(actionIcon),
            onPressed: onAction,
          ),
        ],
      ],
    );

    if (!inCard) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(tokens.spacing.xxl),
          child: content,
        ),
      );
    }

    return PortalCard(variant: PortalCardVariant.glass, child: content);
  }
}
