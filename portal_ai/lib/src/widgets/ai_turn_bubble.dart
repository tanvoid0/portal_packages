import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

import '../chat/ai_chat_session.dart';

/// The user's own turn: a [PortalChatBubble] with long-press actions, and an
/// inline "Not sent / Retry" prompt under it when the send failed.
///
/// Actions go through [showPortalActionSheet] rather than a raw `showMenu`, so
/// they get thumb-sized rows and the fleet's destructive colour. A callback
/// left null drops its row; with none set there is no long-press at all.
/// [key] is forwarded to the root so the page can attach a
/// `GlobalObjectKey(turn)` and scroll to this turn.
class AiUserTurn extends StatelessWidget {
  const AiUserTurn({
    super.key,
    required this.turn,
    this.notSent = false,
    this.onRetry,
    this.onCopy,
    this.onEdit,
    this.onDelete,
    this.copy = 'Copy',
    this.edit = 'Edit',
    this.delete = 'Delete',
    this.notSentLabel = 'Not sent',
    this.retry = 'Retry',
  });

  final AiChatTurn turn;

  /// The send failed: shows [notSentLabel] under the bubble with [retry].
  final bool notSent;
  final VoidCallback? onRetry;
  final VoidCallback? onCopy;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final String copy;
  final String edit;
  final String delete;
  final String notSentLabel;
  final String retry;

  @override
  Widget build(BuildContext context) {
    final tokens = PortalUiTheme.of(context).tokens;
    final actions = [
      if (onCopy != null)
        PortalAction(
          icon: PortalIcons.content_copy_rounded,
          label: copy,
          onPressed: onCopy,
        ),
      if (onEdit != null)
        PortalAction(
          icon: PortalIcons.edit_rounded,
          label: edit,
          onPressed: onEdit,
        ),
      if (onDelete != null)
        PortalAction(
          icon: PortalIcons.delete_rounded,
          label: delete,
          onPressed: onDelete,
          destructive: true,
        ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        PortalChatBubble(
          author: PortalChatAuthor.user,
          onLongPress: actions.isEmpty
              ? null
              : () {
                  HapticFeedback.selectionClick();
                  showPortalActionSheet(context, actions);
                },
          child: Text(turn.content),
        ),
        if (notSent)
          Padding(
            padding: EdgeInsets.only(top: tokens.spacing.xs),
            child: IntrinsicWidth(
              child: PortalPrompt(
                message: notSentLabel,
                sentiment: PortalSentiment.negative,
                size: PortalPromptSize.inline,
                action: switch (onRetry) {
                  final r? => (label: retry, onPressed: r),
                  null => null,
                },
              ),
            ),
          ),
      ],
    );
  }
}

/// A centred "Today" / "Yesterday" / "14 Sep" between turns of different days.
class AiDayStamp extends StatelessWidget {
  const AiDayStamp({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final portal = PortalUiTheme.of(context);
    final tokens = portal.tokens;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: tokens.spacing.sm),
      child: Center(
        child: Text(
          label,
          style: tokens.textStyles.caption.copyWith(
            color: portal.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

/// The calendar day of [at] in the context's locale, relative near today.
String aiDayStamp(BuildContext context, DateTime at) =>
    PortalFormat.of(context).date(at);
