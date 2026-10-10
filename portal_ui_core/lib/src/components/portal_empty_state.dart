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
/// The one addition is [secondaryActionLabel]/[onSecondaryAction], a ghost
/// under the first for a way back ("Clear search") or a second way to start.
///
/// A load that failed is [PortalEmptyState.error], the fourth of the four
/// states.
class PortalEmptyState extends StatelessWidget {
  const PortalEmptyState({
    super.key,
    this.icon,
    this.iconWidget,
    this.title,
    this.message,
    this.actionLabel,
    this.onAction,
    this.actionIcon,
    this.secondaryActionLabel,
    this.onSecondaryAction,
    this.example,
    this.iconWellColor,
    this.inCard = true,
  })  : _error = false,
        assert(title != null || message != null, 'give a title or a message');

  /// A load that failed: what happened, what to do, and a retry. Announced
  /// politely when it appears. [icon] names the cause: the connection by
  /// default, a document when the file itself is the problem. The retry is a
  /// secondary button, as it is a way back rather than a way to start.
  const PortalEmptyState.error({
    super.key,
    this.title = "Couldn't load this",
    this.message,
    required VoidCallback onRetry,
    String retryLabel = 'Retry',
    this.icon = Icons.cloud_off_rounded,
    this.inCard = true,
  })  : iconWidget = null,
        actionLabel = retryLabel,
        onAction = onRetry,
        actionIcon = null,
        secondaryActionLabel = null,
        onSecondaryAction = null,
        example = null,
        iconWellColor = null,
        _error = true;

  final IconData? icon;

  /// Any glyph (a `FaIcon`, a logo) in place of [icon]; it paints its own
  /// colour and size. Wins over [icon]. Omit both for a message-only inline
  /// hint (pair with [inCard] false).
  final Widget? iconWidget;

  /// Optional: a bare [message] with no title is a valid inline hint.
  final String? title;
  final String? message;

  /// Both [actionLabel] and [onAction] must be set for the button to render.
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData? actionIcon;

  /// A ghost button under the primary action; both must be set to render.
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;

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
  final bool _error;

  @override
  Widget build(BuildContext context) {
    final portal = PortalUiTheme.of(context);
    final tokens = portal.tokens;
    final skin = PortalEmptyStateTheme.of(context);
    final well = iconWellColor ?? skin.iconWellColor;
    final iconColor = skin.iconColor ?? portal.onSurfaceVariant;
    final iconSize = skin.iconSize ?? tokens.spacing.xxl;

    final glyph = iconWidget ?? (icon != null
        ? Icon(icon, size: iconSize, color: iconColor)
        : null);
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (glyph != null) ...[
          if (well == null)
            glyph
          else
            CircleAvatar(
              radius: iconSize * 1.5,
              backgroundColor: well,
              child: glyph,
            ),
          SizedBox(height: tokens.spacing.md),
        ],
        if (title != null)
          Text(
            title!,
            textAlign: TextAlign.center,
            style: tokens.textStyles.subtitle
                .copyWith(color: skin.titleColor ?? portal.onSurface),
          ),
        if (message != null) ...[
          if (title != null) SizedBox(height: tokens.spacing.xs),
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
            variant: _error
                ? PortalButtonVariant.secondary
                : PortalButtonVariant.primary,
            onPressed: onAction,
          ),
        ],
        if (secondaryActionLabel != null && onSecondaryAction != null) ...[
          SizedBox(height: tokens.spacing.sm),
          PortalButton(
            label: secondaryActionLabel!,
            variant: PortalButtonVariant.ghost,
            onPressed: onSecondaryAction,
          ),
        ],
      ],
    );
    final announced =
        _error ? Semantics(liveRegion: true, child: content) : content;

    if (!inCard) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(tokens.spacing.xxl),
          child: announced,
        ),
      );
    }

    return PortalCard(variant: PortalCardVariant.glass, child: announced);
  }
}
