import 'dart:async';

import 'package:flutter/material.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

import '../chat/ai_chat_session.dart';
import 'ai_chat_labels.dart';

/// One icon button in the panel's quick-access row.
class AiChatQuickAccess {
  const AiChatQuickAccess({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;

  /// The button's tooltip and screen-reader name.
  final String label;
  final VoidCallback onTap;
}

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
    this.quickAccess = const [],
    this.footer,
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

  /// Icon buttons under the search row: new incognito chat and the like.
  final List<AiChatQuickAccess> quickAccess;

  /// Pinned under the list over a rule: who is signed in, Settings.
  final Widget? footer;

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
    final title = await portalInputDialog(
      context,
      title: widget.labels.renameTitle,
      initialValue: item.title,
      confirmLabel: widget.labels.save,
      cancelLabel: widget.labels.cancel,
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
    final t = PortalUiTheme.of(context).tokens;
    final cs = Theme.of(context).colorScheme;
    final labels = widget.labels;
    final matches = _matches;
    return PortalReviewTag(
      id: 'shared.sidebar',
      child: SizedBox(
        width: widget.width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: EdgeInsetsDirectional.only(
                      start: t.spacing.lg,
                      end: t.spacing.sm,
                      top: t.spacing.sm,
                      bottom: t.spacing.sm,
                    ),
                    child: PortalSearchField(
                      hintText: labels.searchHint,
                      onChanged: (value) => setState(() => _query = value),
                    ),
                  ),
                ),
                PortalButton.icon(
                  icon: PortalIcons.edit_square_rounded,
                  tooltip: labels.newChat,
                  onPressed: widget.onNewChat,
                ),
                if (widget.onClose != null)
                  PortalButton.icon(
                    icon: PortalIcons.close_rounded,
                    tooltip: labels.close,
                    onPressed: widget.onClose,
                  ),
                SizedBox(width: t.spacing.xs),
              ],
            ),
            if (widget.quickAccess.isNotEmpty)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: t.spacing.lg),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    for (final q in widget.quickAccess)
                      PortalButton.icon(
                        icon: q.icon,
                        tooltip: q.label,
                        onPressed: q.onTap,
                      ),
                  ],
                ),
              ),
            Expanded(
              child: matches.isEmpty
                  ? ListView(children: [_empty()])
                  : ListView(children: _sections(matches)),
            ),
            if (widget.footer != null)
              DecoratedBox(
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: PortalUiTheme.of(context).rule(cs)),
                  ),
                ),
                child: widget.footer,
              ),
          ],
        ),
      ),
    );
  }

  Widget _empty() {
    final labels = widget.labels;
    if (widget.sessions.isEmpty) {
      return PortalEmptyState(
        icon: PortalIcons.forum_rounded,
        title: labels.historyEmpty,
        actionLabel: labels.newChat,
        onAction: widget.onNewChat,
        inCard: false,
      );
    }
    return PortalEmptyState(
      icon: PortalIcons.search_rounded,
      title: labels.noMatches,
      inCard: false,
    );
  }

  /// One caption-headed, full-bleed section per bucket; [_matches] already
  /// has the pinned rows first, so a bucket is a run.
  List<Widget> _sections(List<AiChatSessionSummary> matches) {
    final runs = <_Group, List<AiChatSessionSummary>>{};
    for (final s in matches) {
      (runs[_bucketOf(s)] ??= []).add(s);
    }
    return [
      for (final MapEntry(key: group, value: rows) in runs.entries)
        PortalListSection(
          header: _labelFor(group),
          captionHeader: true,
          style: PortalListStyle.fullBleed,
          children: [for (final s in rows) _row(s)],
        ),
    ];
  }

  Widget _row(AiChatSessionSummary item) {
    final labels = widget.labels;
    final f = PortalFormat.of(context);
    final current = item.id == widget.selectedId;
    final actions = [
      if (widget.onRename != null)
        PortalAction(
          icon: PortalIcons.edit_rounded,
          label: labels.rename,
          onPressed: () => _rename(item),
        ),
      if (widget.onSetPinned != null)
        PortalAction(
          icon: PortalIcons.push_pin_rounded,
          label: item.pinned ? labels.unpin : labels.pin,
          onPressed: () => _togglePin(item),
        ),
      if (widget.onDelete != null)
        PortalAction(
          icon: PortalIcons.delete_rounded,
          label: labels.delete,
          destructive: true,
          onPressed: () => _delete(item),
        ),
    ];
    return PortalListItem(
      title: item.title,
      subtitle: _subtitleFor(item),
      trailing: PortalListAccessory.meta(
        f.date(item.updatedAt, short: true),
        spoken: f.date(item.updatedAt),
        icon: current
            ? PortalIcons.check_circle_rounded
            : item.pinned
            ? PortalIcons.push_pin_rounded
            : null,
        markLabel: current
            ? 'current chat'
            : item.pinned
            ? 'pinned'
            : null,
      ),
      onTap: () => widget.onSelect(item.id),
      onLongPress: actions.isEmpty
          ? null
          : () => showPortalActionSheet(context, actions, title: item.title),
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
