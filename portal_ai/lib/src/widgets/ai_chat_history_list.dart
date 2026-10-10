import 'dart:async';

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
/// finding one meant opening three. Pinned threads sit in their own group
/// above the days, then Today, Yesterday, Previous 7 days, Previous 30 days
/// and Older -- the buckets a portal_assistant sidebar full of months of
/// threads actually needs, not just yesterday-or-not. Search reads whole
/// transcripts where the store fills [AiChatSessionSummary.searchText].
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
    this.onRename,
    this.onSetPinned,
    this.labels = const AiChatLabels(),
    this.width = 280,
    this.previous7DaysLabel = 'Previous 7 days',
    this.previous30DaysLabel = 'Previous 30 days',
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

  /// Removes a thread. No menu entry is drawn when this is null.
  ///
  /// Called after the undo snackbar closes without being undone, so a host
  /// only ever hears about deletes the user let stand.
  final Future<void> Function(String id)? onDelete;

  /// Retitles a thread. No menu entry is drawn when this is null.
  final Future<void> Function(String id, String title)? onRename;

  /// Pins or unpins a thread. No menu entry is drawn when this is null.
  final Future<void> Function(String id, bool pinned)? onSetPinned;

  final AiChatLabels labels;
  final double width;

  /// [AiChatLabels] has no field for these two -- they're new with the
  /// finer-grained grouping, so they land here rather than growing a package
  /// this widget doesn't own.
  final String previous7DaysLabel;
  final String previous30DaysLabel;

  @override
  State<AiChatHistoryList> createState() => _AiChatHistoryListState();
}

class _AiChatHistoryListState extends State<AiChatHistoryList> {
  String _query = '';

  /// Rows hidden while their undo window is open, against the timer that
  /// commits them. The host is not told until that fires, so undo is a local
  /// un-hide rather than a restore every store would have to implement.
  final _pendingDelete = <String, Timer>{};

  static const _undoWindow = Duration(seconds: 5);

  @override
  void dispose() {
    // Leaving the list does not undo a delete: commit whatever is still
    // pending, unhooked from this state.
    for (final entry in _pendingDelete.entries) {
      entry.value.cancel();
      widget.onDelete?.call(entry.key);
    }
    _pendingDelete.clear();
    super.dispose();
  }

  List<AiChatSessionSummary> get _matches {
    final query = _query.trim().toLowerCase();
    final visible = [
      for (final s in widget.sessions)
        if (!_pendingDelete.containsKey(s.id)) s,
    ];
    final matched = query.isEmpty
        ? visible
        : [
            for (final s in visible)
              if (s.title.toLowerCase().contains(query) ||
                  s.preview.toLowerCase().contains(query) ||
                  s.searchText.toLowerCase().contains(query))
                s,
          ];
    // Pinned first; the host's order is kept inside each block.
    return [
      for (final s in matched)
        if (s.pinned) s,
      for (final s in matched)
        if (!s.pinned) s,
    ];
  }

  void _delete(AiChatSessionSummary item) {
    final onDelete = widget.onDelete;
    if (onDelete == null) return;
    setState(() {
      _pendingDelete[item.id] = Timer(_undoWindow, () => _commit(item.id));
    });
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(
        duration: _undoWindow,
        content: Text(widget.labels.deleted),
        action: SnackBarAction(
          label: widget.labels.undo,
          onPressed: () => _undo(item.id),
        ),
      ),
    );
  }

  void _undo(String id) {
    _pendingDelete.remove(id)?.cancel();
    if (mounted) setState(() {});
  }

  Future<void> _commit(String id) async {
    _pendingDelete.remove(id);
    await widget.onDelete?.call(id);
    if (mounted) setState(() {});
  }

  Future<void> _rename(AiChatSessionSummary item) async {
    final onRename = widget.onRename;
    if (onRename == null) return;
    final title = await showDialog<String>(
      context: context,
      builder: (dialogContext) =>
          _RenameDialog(initial: item.title, labels: widget.labels),
    );
    if (title == null || title.isEmpty || title == item.title) return;
    await onRename(item.id, title);
    if (mounted) setState(() {});
  }

  Future<void> _togglePin(AiChatSessionSummary item) async {
    await widget.onSetPinned?.call(item.id, !item.pinned);
    if (mounted) setState(() {});
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
          if (widget.sessions.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: TextField(
                onChanged: (value) => setState(() => _query = value),
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  isDense: true,
                  hintText: labels.searchHint,
                  prefixIcon: const Icon(Icons.search_rounded, size: 18),
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
                      // No PortalEmptyState: this package doesn't depend on
                      // portal_ui_core. Only the truly-empty case (no
                      // sessions at all) gets the icon -- a search with no
                      // hits is a filter result, not a nothing-here state.
                      child: widget.sessions.isEmpty
                          ? Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.forum_rounded,
                                  size: 32,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  labels.historyEmpty,
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            )
                          : Text(
                              labels.noMatches,
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
                      final bucket = _bucketOf(item);
                      final newGroup =
                          index == 0 || _bucketOf(matches[index - 1]) != bucket;
                      final row = _Row(
                        item: item,
                        selected: item.id == widget.selectedId,
                        subtitle: _subtitleFor(item),
                        onTap: () => widget.onSelect(item.id),
                        onDelete: widget.onDelete == null
                            ? null
                            : () => _delete(item),
                        onRename: widget.onRename == null
                            ? null
                            : () => _rename(item),
                        onTogglePin: widget.onSetPinned == null
                            ? null
                            : () => _togglePin(item),
                        labels: labels,
                      );
                      if (!newGroup) return row;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(8, 12, 8, 4),
                            // No PortalSectionHeader here: this package
                            // doesn't depend on portal_ui_core. This is an
                            // overline, not a section header (it labels a
                            // group of rows, doesn't title content), so it's
                            // upper-cased and tracked rather than styled like
                            // `subtitle`.
                            child: Text(
                              // Not upper-cased. The eyebrow treatment is the letter-spacing
                              // and the muted weight, not CAPS -- which a
                              // screen reader may spell out letter by letter
                              // and which no translation of these labels asked
                              // for.
                              _labelFor(bucket),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.6,
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

  String _labelFor(_Group group) => switch (group) {
    _Group.pinned => widget.labels.pinned,
    _Group.today => widget.labels.today,
    _Group.yesterday => widget.labels.yesterday,
    _Group.previous7 => widget.previous7DaysLabel,
    _Group.previous30 => widget.previous30DaysLabel,
    _Group.older => widget.labels.earlier,
  };

  /// Calendar-day buckets, not elapsed hours -- 23:00 last night is
  /// Yesterday, not "22 hours ago and still Today".
  static _Group _bucketOf(AiChatSessionSummary item) {
    if (item.pinned) return _Group.pinned;
    final at = item.updatedAt;
    final now = DateTime.now();
    final days = DateTime(
      now.year,
      now.month,
      now.day,
    ).difference(DateTime(at.year, at.month, at.day)).inDays;
    return switch (days) {
      <= 0 => _Group.today,
      1 => _Group.yesterday,
      <= 7 => _Group.previous7,
      <= 30 => _Group.previous30,
      _ => _Group.older,
    };
  }
}

enum _Group { pinned, today, yesterday, previous7, previous30, older }

/// Owns its own controller so it is disposed with the route rather than the
/// moment `showDialog` returns -- the field is still on screen while the
/// dialog animates out.
class _RenameDialog extends StatefulWidget {
  const _RenameDialog({required this.initial, required this.labels});

  final String initial;
  final AiChatLabels labels;

  @override
  State<_RenameDialog> createState() => _RenameDialogState();
}

class _RenameDialogState extends State<_RenameDialog> {
  late final _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() => Navigator.of(context).pop(_controller.text.trim());

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.labels.renameTitle),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(widget.labels.cancel),
        ),
        FilledButton(onPressed: _submit, child: Text(widget.labels.save)),
      ],
    );
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
    this.onRename,
    this.onTogglePin,
  });

  final AiChatSessionSummary item;
  final bool selected;
  final String subtitle;
  final VoidCallback onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onRename;
  final VoidCallback? onTogglePin;
  final AiChatLabels labels;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasMenu = onDelete != null || onRename != null || onTogglePin != null;
    return ListTile(
      selected: selected,
      dense: true,
      title: Row(
        children: [
          if (item.pinned)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Icon(
                Icons.push_pin,
                size: 14,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
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
          if (hasMenu)
            PopupMenuButton<VoidCallback>(
              icon: const Icon(Icons.more_vert, size: 18),
              tooltip: '',
              onSelected: (action) => action(),
              itemBuilder: (context) => [
                if (onRename case final rename?)
                  PopupMenuItem(
                    value: rename,
                    child: ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.edit_outlined, size: 18),
                      title: Text(labels.rename),
                    ),
                  ),
                if (onTogglePin case final pin?)
                  PopupMenuItem(
                    value: pin,
                    child: ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        item.pinned ? Icons.push_pin_outlined : Icons.push_pin,
                        size: 18,
                      ),
                      title: Text(item.pinned ? labels.unpin : labels.pin),
                    ),
                  ),
                if (onDelete case final delete?)
                  PopupMenuItem(
                    value: delete,
                    child: ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        Icons.delete_outline,
                        size: 18,
                        color: theme.colorScheme.error,
                      ),
                      title: Text(
                        labels.delete,
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                    ),
                  ),
              ],
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
