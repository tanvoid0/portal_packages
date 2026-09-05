import 'package:flutter/material.dart';

import '../chat/ai_chat_session.dart';
import 'ai_chat_labels.dart';

/// Past threads, newest first, with a button to start a fresh one.
///
/// Takes the summaries rather than a store: the host already holds them, and
/// portal_ai has no storage of its own to read them from.
///
/// Rows are grouped by day and carry the last thing said, because a list of
/// first-messages-and-a-count made every thread look alike after a week --
/// finding one meant opening three.
class AiChatHistoryList extends StatefulWidget {
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

  /// The line under a title. Defaults to the thread's last message, falling
  /// back to the turn count; a host with something better in
  /// [AiChatSessionSummary.payload] (a plan date, say) can format it here.
  final String Function(AiChatSessionSummary)? subtitleFor;

  /// Removes a thread. No button is drawn when this is null.
  final Future<void> Function(String id)? onDelete;

  final AiChatLabels labels;
  final double width;

  @override
  State<AiChatHistoryList> createState() => _AiChatHistoryListState();
}

class _AiChatHistoryListState extends State<AiChatHistoryList> {
  String _query = '';

  /// Only worth the row of chrome once the list is long enough to lose
  /// something in.
  static const _searchFrom = 6;

  List<AiChatSessionSummary> get _matches {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return widget.sessions;
    return [
      for (final s in widget.sessions)
        if (s.title.toLowerCase().contains(query) ||
            s.preview.toLowerCase().contains(query))
          s,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final labels = widget.labels;
    final matches = _matches;
    return SizedBox(
      width: widget.width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              16,
              widget.onClose == null ? 16 : 4,
              8,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    labels.historyTitle,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (widget.onClose != null)
                  IconButton(
                    icon: const Icon(Icons.close),
                    tooltip: labels.close,
                    onPressed: widget.onClose,
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: FilledButton.icon(
              onPressed: widget.onNewChat,
              icon: const Icon(Icons.add, size: 18),
              label: Text(labels.newChat),
            ),
          ),
          if (widget.sessions.length >= _searchFrom)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: TextField(
                onChanged: (value) => setState(() => _query = value),
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  isDense: true,
                  hintText: labels.searchHint,
                  prefixIcon: const Icon(Icons.search, size: 18),
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
          const SizedBox(height: 8),
          Expanded(
            child: matches.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        widget.sessions.isEmpty
                            ? labels.historyEmpty
                            : labels.noMatches,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(8, 4, 8, 16),
                    itemCount: matches.length,
                    itemBuilder: (context, index) {
                      final item = matches[index];
                      final group = _groupOf(item.updatedAt, labels);
                      final newGroup =
                          index == 0 ||
                          _groupOf(matches[index - 1].updatedAt, labels) !=
                              group;
                      final row = _Row(
                        item: item,
                        selected: item.id == widget.selectedId,
                        subtitle: _subtitleFor(item),
                        onTap: () => widget.onSelect(item.id),
                        onDelete: widget.onDelete,
                        labels: labels,
                      );
                      if (!newGroup) return row;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(8, 12, 8, 4),
                            child: Text(
                              group,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          row,
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  String _subtitleFor(AiChatSessionSummary item) {
    if (widget.subtitleFor case final format?) return format(item);
    if (item.preview.isNotEmpty) return item.preview;
    return '${item.turnCount} ${widget.labels.messages}';
  }

  static String _groupOf(DateTime at, AiChatLabels labels) {
    final now = DateTime.now();
    final days = DateTime(
      now.year,
      now.month,
      now.day,
    ).difference(DateTime(at.year, at.month, at.day)).inDays;
    return switch (days) {
      <= 0 => labels.today,
      1 => labels.yesterday,
      _ => labels.earlier,
    };
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.item,
    required this.selected,
    required this.subtitle,
    required this.onTap,
    required this.labels,
    this.onDelete,
  });

  final AiChatSessionSummary item;
  final bool selected;
  final String subtitle;
  final VoidCallback onTap;
  final Future<void> Function(String id)? onDelete;
  final AiChatLabels labels;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      selected: selected,
      dense: true,
      title: Row(
        children: [
          Expanded(
            child: Text(
              item.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _ago(item.updatedAt),
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
      subtitle: Text(
        subtitle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.labelSmall,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (item.itemCount > 0)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Text(
                '${item.itemCount}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          if (selected) const Icon(Icons.check_circle_rounded, size: 18),
          if (onDelete != null)
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 18),
              tooltip: labels.delete,
              onPressed: () => onDelete!(item.id),
            ),
        ],
      ),
      onTap: onTap,
    );
  }

  /// Coarse on purpose: the row is for recognising a thread, not for auditing
  /// it, so anything past a week is just a date.
  static String _ago(DateTime at) {
    final gap = DateTime.now().difference(at);
    if (gap.inMinutes < 1) return 'now';
    if (gap.inMinutes < 60) return '${gap.inMinutes}m';
    if (gap.inHours < 24) return '${gap.inHours}h';
    if (gap.inDays < 7) return '${gap.inDays}d';
    return '${at.day}/${at.month}';
  }
}
