import 'package:flutter/material.dart';

import '../chat/ai_chat_session.dart';
import 'ai_chat_labels.dart';

/// Past threads, newest first, with a button to start a fresh one.
///
/// Takes the summaries rather than a store: the host already holds them, and
/// portal_ai has no storage of its own to read them from.
class AiChatHistoryList extends StatelessWidget {
  const AiChatHistoryList({
    super.key,
    required this.sessions,
    required this.onSelect,
    required this.onNewChat,
    this.selectedId,
    this.onClose,
    this.subtitleFor,
    this.onDelete,
    this.labels = const AiChatLabels(),
    this.width = 280,
  });

  final List<AiChatSessionSummary> sessions;
  final ValueChanged<String> onSelect;
  final VoidCallback onNewChat;
  final String? selectedId;

  /// Shows a close button when set, for the drawer form.
  final VoidCallback? onClose;

  /// The line under a title. Defaults to the item count, but a host that puts
  /// something better in [AiChatSessionSummary.payload] (a plan date, say) can
  /// format it here.
  final String Function(AiChatSessionSummary)? subtitleFor;

  /// Removes a thread. No button is drawn when this is null.
  final Future<void> Function(String id)? onDelete;

  final AiChatLabels labels;
  final double width;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16, 16, onClose == null ? 16 : 4, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    labels.historyTitle,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                if (onClose != null)
                  IconButton(
                    icon: const Icon(Icons.close),
                    tooltip: labels.close,
                    onPressed: onClose,
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: FilledButton.icon(
              onPressed: onNewChat,
              icon: const Icon(Icons.add, size: 18),
              label: Text(labels.newChat),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: sessions.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        labels.historyEmpty,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(8, 4, 8, 16),
                    itemCount: sessions.length,
                    itemBuilder: (context, index) {
                      final item = sessions[index];
                      final selected = item.id == selectedId;
                      return ListTile(
                        selected: selected,
                        title: Text(
                          item.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight:
                                selected ? FontWeight.w600 : FontWeight.w500,
                          ),
                        ),
                        subtitle: subtitleFor == null
                            ? null
                            : Text(
                                subtitleFor!(item),
                                style: theme.textTheme.labelSmall,
                              ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (selected)
                              const Icon(Icons.check_circle_rounded, size: 18),
                            if (onDelete != null)
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 18),
                                tooltip: labels.delete,
                                onPressed: () => onDelete!(item.id),
                              ),
                          ],
                        ),
                        onTap: () => onSelect(item.id),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
