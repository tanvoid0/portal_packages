import 'package:flutter/material.dart';

import '../theme/portal_ui_theme.dart';
import 'portal_button.dart';
import 'portal_card.dart';

/// Nothing-here state — glyph, title, optional body, optional single action.
///
/// The body is deliberately optional and the action deliberately singular: an
/// empty state that offers three ways forward is a menu, not an empty state.
class PortalEmptyState extends StatelessWidget {
  const PortalEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
    this.actionIcon,
    this.inCard = true,
  });

  final IconData icon;
  final String title;
  final String? message;

  /// Both [actionLabel] and [onAction] must be set for the button to render.
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData? actionIcon;

  /// Wraps the content in a [PortalCard]. Set false when the state already
  /// sits inside a card or fills the page.
  final bool inCard;

  @override
  Widget build(BuildContext context) {
    final portal = PortalUiTheme.of(context);
    final tokens = portal.tokens;

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: tokens.spacing.xxl, color: portal.onSurfaceVariant),
        SizedBox(height: tokens.spacing.md),
        Text(
          title,
          textAlign: TextAlign.center,
          style: tokens.textStyles.subtitle.copyWith(color: portal.onSurface),
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
                .copyWith(color: portal.onSurfaceVariant),
          ),
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
