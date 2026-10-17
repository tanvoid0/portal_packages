import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../chat/ai_chat_session.dart';
import 'ai_chat_history_list.dart';
import 'ai_chat_labels.dart';

/// The assistant's thread panel: [AiChatHistoryList] in a leading-edge sheet
/// that slides in over whatever is behind it. One implementation for the whole
/// app -- the Start screen and the chat page both open this, so there is a
/// single sidebar rather than a copy per screen.
///
/// [quickAccess] and [footer] are built by the caller from the [close] callback
/// handed to them, since their destinations are the host's routes: a tap closes
/// the panel first, then navigates. [onSelect] fires with a thread id, or null
/// for New chat, after the panel has already closed.
Future<void> showAiHistoryPanel({
  required BuildContext context,
  required List<AiChatSessionSummary> sessions,
  required ValueChanged<String?> onSelect,
  String? selectedId,
  AiChatLabels labels = const AiChatLabels(),
  String Function(AiChatSessionSummary)? subtitleFor,
  List<AiChatQuickAccess> Function(VoidCallback close)? quickAccess,
  Widget Function(VoidCallback close)? footer,
  Future<void> Function(String id, String title)? onRename,
  Future<void> Function(String id, bool pinned)? onSetPinned,
  Future<void> Function(String id)? onDelete,
}) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Theme.of(context).colorScheme.scrim.withValues(alpha: 0.5),
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (dialogContext, _, _) {
      // Root navigator by default (showGeneralDialog); popping this one closes
      // the panel whichever navigator the host sits under.
      void close() => Navigator.of(dialogContext).pop();
      return Align(
        alignment: AlignmentDirectional.centerStart,
        child: Material(
          color: Theme.of(dialogContext).colorScheme.surfaceContainer,
          child: SafeArea(
            child: SizedBox(
              // Never the whole width -- the sliver still showing is what says
              // this is a panel over the screen, not a page you navigated to.
              width: math.min(340, MediaQuery.sizeOf(dialogContext).width * 0.86),
              child: StatefulBuilder(
                // Rename/pin/delete keep the panel open, so it rebuilds from
                // the host's (mutated or re-read) session list.
                builder: (dialogContext, setDialogState) => AiChatHistoryList(
                  sessions: sessions,
                  selectedId: selectedId,
                  labels: labels,
                  width: double.infinity,
                  subtitleFor: subtitleFor,
                  onSelect: (id) {
                    close();
                    onSelect(id);
                  },
                  onNewChat: () {
                    close();
                    onSelect(null);
                  },
                  onRename: onRename == null
                      ? null
                      : (id, title) async {
                          await onRename(id, title);
                          setDialogState(() {});
                        },
                  onSetPinned: onSetPinned == null
                      ? null
                      : (id, pinned) async {
                          await onSetPinned(id, pinned);
                          setDialogState(() {});
                        },
                  onDelete: onDelete == null
                      ? null
                      : (id) async {
                          await onDelete(id);
                          setDialogState(() {});
                        },
                  quickAccess: quickAccess?.call(close) ?? const [],
                  footer: footer?.call(close),
                ),
              ),
            ),
          ),
        ),
      );
    },
    transitionBuilder: (context, animation, _, child) => SlideTransition(
      position: Tween(begin: const Offset(-1, 0), end: Offset.zero).animate(
        CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
      ),
      child: child,
    ),
  );
}
