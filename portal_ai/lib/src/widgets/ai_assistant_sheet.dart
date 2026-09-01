import 'dart:convert';

import 'package:flutter/material.dart';

import '../chat/ai_chat_session.dart';
import '../chat/ai_proposal.dart';
import '../runtime/portal_ai_runtime.dart';
import '../tools/ai_tool.dart';
import 'ai_chat_history_list.dart';
import 'ai_chat_labels.dart';

/// Drop-in assistant UI: prompt box, live step log and a confirmation prompt
/// before any tool that changes data.
///
/// ```dart
/// AiAssistantSheet.show(context, runtime: Get.find<PortalAiRuntime>());
/// ```
class AiAssistantSheet extends StatefulWidget {
  const AiAssistantSheet({
    super.key,
    this.runtime,
    this.title = 'Assistant',
    this.suggestions = const [],
    this.onSettings,
    this.tools,
    this.renderers = const {},
    this.proposals = const [],
    this.onAcceptProposal,
    this.onEditProposal,
    this.onDiscardProposal,
    this.turns = const [],
    this.onSend,
    this.busy = false,
    this.onCancel,
    this.labels = const AiChatLabels(),
    this.fill = false,
    this.store,
  }) : assert(
          runtime != null || onSend != null,
          'give the sheet a runtime to drive the agent, or an onSend that '
          'generates the reply itself',
        );

  /// Drives the agent loop. Null when [onSend] answers instead.
  final PortalAiRuntime? runtime;

  final String title;

  /// Example prompts shown as tappable chips before the first run.
  final List<String> suggestions;

  /// Opens the app's own AI settings, when it has any. The model and key live
  /// on the server, so there is nothing to configure here by default.
  final VoidCallback? onSettings;

  /// Overrides [PortalAiRuntime.tools] for this sheet, for tools that have to
  /// be built per call site (e.g. closed over a Riverpod ref).
  final List<AiTool>? tools;

  /// Builders for [AiBlock.kind], so each app draws its own data.
  ///
  /// A kind with no builder falls back to text: threads persist, so an old one
  /// can hold blocks whose renderer was since renamed or removed, and a reload
  /// must survive that rather than throw.
  final Map<String, Widget Function(AiBlock block)> renderers;

  /// Suggestions to add, edit or throw away, shown as cards with an "Add all"
  /// bar. Host-supplied: the sheet never invents one.
  final List<AiProposal> proposals;

  /// Called once per proposal accepted, by its card or by "Add all". The card
  /// disappears; what accepting means is the host's business.
  final ValueChanged<AiProposal>? onAcceptProposal;

  /// Opens the host's editor. The card stays -- the host passes a new list if
  /// the edit changed anything.
  final ValueChanged<AiProposal>? onEditProposal;

  final ValueChanged<AiProposal>? onDiscardProposal;

  /// The conversation so far, rendered as bubbles above the run log.
  ///
  /// Host-owned: an app with sessions rebuilds the sheet with the turns it has
  /// persisted, so history and reload cost the sheet nothing.
  final List<AiChatTurn> turns;

  /// Takes over sending. Set by apps that generate their own reply (portal_task
  /// asks `AiPlanService` for a plan) and then push the result back in through
  /// [turns] and [proposals], instead of running the tool agent.
  final Future<void> Function(String prompt)? onSend;

  /// Host-driven busy flag, ORed with the sheet's own.
  final bool busy;

  /// Shows a stop button while busy when set.
  final VoidCallback? onCancel;

  final AiChatLabels labels;

  /// Where to keep this app's threads, if it wants history.
  ///
  /// With a store the sheet records the conversation, restores it from the
  /// history button and feeds the earlier turns back to the agent, so a
  /// follow-up can say "make it shorter". Without one it stays a one-shot.
  /// Ignored when [onSend] is set: that host owns its own sessions.
  final AiChatStore? store;

  /// Take all the height offered instead of hugging the content, so the
  /// composer sits at the bottom. For hosts that embed this full-screen; a
  /// modal sheet wants the opposite.
  final bool fill;

  static Future<void> show(
    BuildContext context, {
    required PortalAiRuntime runtime,
    String title = 'Assistant',
    List<String> suggestions = const [],
    VoidCallback? onSettings,
    List<AiTool>? tools,
    Map<String, Widget Function(AiBlock block)> renderers = const {},
    List<AiProposal> proposals = const [],
    ValueChanged<AiProposal>? onAcceptProposal,
    ValueChanged<AiProposal>? onEditProposal,
    ValueChanged<AiProposal>? onDiscardProposal,
    AiChatLabels labels = const AiChatLabels(),
    AiChatStore? store,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => AiAssistantSheet(
        runtime: runtime,
        title: title,
        suggestions: suggestions,
        onSettings: onSettings,
        tools: tools,
        renderers: renderers,
        proposals: proposals,
        onAcceptProposal: onAcceptProposal,
        onEditProposal: onEditProposal,
        onDiscardProposal: onDiscardProposal,
        labels: labels,
        store: store,
      ),
    );
  }

  @override
  State<AiAssistantSheet> createState() => _AiAssistantSheetState();
}

class _AiAssistantSheetState extends State<AiAssistantSheet> {
  final _input = TextEditingController();
  final _scroll = ScrollController();

  /// Set by the stop button. The in-flight request cannot be recalled, so the
  /// answer is dropped when it lands rather than appearing minutes later.
  bool _cancelled = false;
  final _steps = <AiAgentStep>[];
  bool _running = false;
  String? _reply;
  String? _error;

  /// Accepting or discarding removes a card here and now; the host is told, but
  /// the sheet does not wait for it to hand back a new list.
  late List<AiProposal> _proposals = List.of(widget.proposals);
  String? _expandedProposal;

  /// Only used in store mode; when the host passes [AiAssistantSheet.onSend] it
  /// owns the transcript and these stay empty.
  final _turns = <AiChatTurn>[];
  final _sessions = <AiChatSessionSummary>[];
  String? _sessionId;

  List<AiChatTurn> get _visibleTurns =>
      widget.onSend != null ? widget.turns : _turns;

  @override
  void initState() {
    super.initState();
    _reloadSessions();
  }

  void _reloadSessions() {
    final store = widget.store;
    if (store == null) return;
    _sessions
      ..clear()
      ..addAll(store.listSummaries());
  }

  Future<void> _persist() async {
    final store = widget.store;
    if (store == null || _turns.isEmpty) return;
    final now = DateTime.now();
    final id = _sessionId ??= now.microsecondsSinceEpoch.toString();
    final existing = store.load(id);
    final first = _turns.first.content.trim();
    await store.save(
      AiChatSession(
        id: id,
        title: existing?.title ??
            (first.length <= 48 ? first : '${first.substring(0, 45)}...'),
        createdAt: existing?.createdAt ?? now,
        updatedAt: now,
        turns: List.of(_turns),
      ),
    );
    if (mounted) setState(_reloadSessions);
  }

  Future<void> _deleteSession(String id) async {
    await widget.store?.delete(id);
    if (!mounted) return;
    if (_sessionId == id) {
      _newChat();
    } else {
      setState(_reloadSessions);
    }
  }

  void _loadSession(String id) {
    final session = widget.store?.load(id);
    if (session == null) return;
    setState(() {
      _sessionId = session.id;
      _turns
        ..clear()
        ..addAll(session.turns);
      _steps.clear();
      _reply = null;
      _error = null;
    });
  }

  void _newChat() {
    setState(() {
      _sessionId = null;
      _turns.clear();
      _steps.clear();
      _reply = null;
      _error = null;
    });
  }

  Future<void> _showHistory() async {
    final store = widget.store;
    if (store == null) return;
    final chosen = await showDialog<String>(
      context: context,
      builder: (dialogContext) => Dialog(
        // Deleting keeps the dialog open, so it rebuilds from the store rather
        // than from the list this sheet captured when it opened.
        child: StatefulBuilder(
          builder: (dialogContext, setDialogState) => SizedBox(
            height: 420,
            child: AiChatHistoryList(
              sessions: _sessions,
              selectedId: _sessionId,
              labels: widget.labels,
              width: 320,
              subtitleFor: (s) =>
                  '${s.turnCount} ${widget.labels.messages}',
              onClose: () => Navigator.of(dialogContext).pop(),
              onSelect: (id) => Navigator.of(dialogContext).pop(id),
              onNewChat: () => Navigator.of(dialogContext).pop(''),
              onDelete: (id) async {
                await _deleteSession(id);
                if (_sessions.isEmpty) {
                  if (dialogContext.mounted) {
                    Navigator.of(dialogContext).pop();
                  }
                  return;
                }
                setDialogState(() {});
              },
            ),
          ),
        ),
      ),
    );
    if (chosen == null) return;
    if (chosen.isEmpty) {
      _newChat();
    } else {
      _loadSession(chosen);
    }
  }

  @override
  void didUpdateWidget(AiAssistantSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.proposals, widget.proposals)) {
      _proposals = List.of(widget.proposals);
    }
  }

  void _resolveProposal(AiProposal proposal, ValueChanged<AiProposal>? then) {
    setState(() {
      _proposals.removeWhere((p) => p.id == proposal.id);
      if (_expandedProposal == proposal.id) _expandedProposal = null;
    });
    then?.call(proposal);
  }

  void _acceptAll() {
    final pending = List.of(_proposals);
    setState(() {
      _proposals = [];
      _expandedProposal = null;
    });
    for (final proposal in pending) {
      widget.onAcceptProposal?.call(proposal);
    }
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  /// Keeps the newest turn in view; a long thread otherwise grows below the
  /// fold and the reply looks like it never arrived.
  void _followNewest() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  void _stop() {
    setState(() {
      _cancelled = true;
      _running = false;
    });
    widget.onCancel?.call();
  }

  bool get _busy => _running || widget.busy;

  Future<void> _send() async {
    final prompt = _input.text.trim();
    if (prompt.isEmpty || _busy) return;
    final send = widget.onSend;
    if (send != null) {
      _input.clear();
      setState(() {
        _running = true;
        _cancelled = false;
        _error = null;
      });
      try {
        await send(prompt);
        if (mounted && !_cancelled) _followNewest();
      } catch (e) {
        if (mounted && !_cancelled) setState(() => _error = e.toString());
      } finally {
        if (mounted) setState(() => _running = false);
      }
      return;
    }
    final keeping = widget.store != null;
    final history = List.of(_turns);
    setState(() {
      _running = true;
      _cancelled = false;
      _reply = null;
      _error = null;
      _steps.clear();
      if (keeping) {
        _input.clear();
        _turns.add(AiChatTurn(role: 'user', content: prompt));
      }
    });
    try {
      final result = await widget.runtime!.ask(
        prompt,
        tools: widget.tools,
        history: history,
        confirm: _confirm,
        onStep: (step) {
          if (!mounted || _cancelled) return;
          setState(() => _steps.add(step));
          _followNewest();
        },
      );
      if (!mounted || _cancelled) return;
      if (!keeping) {
        setState(() => _reply = result.message);
        return;
      }
      setState(() {
        _turns.add(
          AiChatTurn(
            role: 'assistant',
            content: result.message,
            payload: {
              'blocks': [
                for (final step in _steps)
                  for (final block in step.blocks) block.toJson(),
              ],
            },
          ),
        );
        _steps.clear();
      });
      _followNewest();
      await _persist();
    } catch (e) {
      if (!mounted || _cancelled) return;
      setState(() => _error = e.toString());
      // Keep the question even though the answer failed: without this the
      // user's turn is on screen but gone after a reload.
      await _persist();
    } finally {
      if (mounted) setState(() => _running = false);
    }
  }

  /// Runs an [AiAction] button: same tools, same confirm prompt as a call the
  /// model makes. Nothing here goes back to the model -- the user asked for
  /// this action directly.
  Future<void> _runAction(AiAction action) async {
    if (_busy) return;
    final tools = widget.tools ?? widget.runtime?.tools ?? const <AiTool>[];
    final tool = resolveTool(tools, action.tool);
    final call = AiToolCall(action.tool, action.args);
    if (tool == null) {
      if (mounted) {
        setState(() => _error = 'Unknown action: ${action.tool}');
      }
      return;
    }
    if (tool.mutates && !await _confirm(tool, call)) return;

    setState(() => _running = true);
    try {
      final rich = tool.runRich;
      final step = rich != null
          ? () async {
              final r = await rich(call);
              return AiAgentStep(
                call: call,
                result: r.forModel,
                blocks: r.blocks,
              );
            }()
          : tool.run(call).then(
              (r) => AiAgentStep(call: call, result: r),
            );
      final resolved = await step;
      if (mounted) setState(() => _steps.add(resolved));
    } catch (e) {
      if (mounted) {
        setState(() => _steps.add(
              AiAgentStep(call: call, result: e.toString(), failed: true),
            ));
      }
    } finally {
      if (mounted) setState(() => _running = false);
    }
  }

  /// Blocks a restored turn carries. An unreadable payload renders nothing
  /// rather than throwing: old threads outlive the shapes that wrote them.
  List<AiBlock> _blocksOf(AiChatTurn turn) {
    final raw = turn.payload?['blocks'];
    if (raw is! List) return const [];
    return [
      for (final entry in raw)
        if (entry is Map) AiBlock.fromJson(Map<String, dynamic>.from(entry)),
    ];
  }

  Widget _blockView(AiBlock block, ThemeData theme) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          widget.renderers[block.kind]?.call(block) ??
              Text(block.kind, style: theme.textTheme.bodySmall),
          if (block.actions.isNotEmpty)
            Wrap(
              spacing: 8,
              children: [
                for (final action in block.actions)
                  OutlinedButton(
                    onPressed: _busy ? null : () => _runAction(action),
                    child: Text(action.label),
                  ),
              ],
            ),
        ],
      );

  Future<bool> _confirm(AiTool tool, AiToolCall call) async {
    if (!mounted) return false;
    final approved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(tool.name.replaceAll('_', ' ')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(tool.description),
            if (call.args.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                const JsonEncoder.withIndent('  ').convert(call.args),
                style: Theme.of(dialogContext).textTheme.bodySmall,
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Skip'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Allow'),
          ),
        ],
      ),
    );
    return approved ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: widget.fill ? MainAxisSize.max : MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.title.isNotEmpty ||
              widget.onSettings != null ||
              widget.store != null) ...[
            Row(
              children: [
                Expanded(
                  child: Text(widget.title, style: theme.textTheme.titleMedium),
                ),
                if (widget.store != null) ...[
                  IconButton(
                    tooltip: widget.labels.historyTitle,
                    icon: const Icon(Icons.history),
                    onPressed: _showHistory,
                  ),
                  IconButton(
                    tooltip: widget.labels.newChat,
                    icon: const Icon(Icons.add_comment_outlined),
                    onPressed: _newChat,
                  ),
                ],
                if (widget.onSettings != null)
                  IconButton(
                    tooltip: 'AI settings',
                    icon: const Icon(Icons.tune),
                    onPressed: widget.onSettings,
                  ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          Flexible(
            fit: widget.fill ? FlexFit.tight : FlexFit.loose,
            child: SingleChildScrollView(
              controller: _scroll,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_steps.isEmpty &&
                      _proposals.isEmpty &&
                      _visibleTurns.isEmpty &&
                      _reply == null &&
                      _error == null) ...[
                    if (widget.labels.empty.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Text(
                          widget.labels.empty,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    _Suggestions(
                      suggestions: widget.suggestions,
                      onTap: (text) {
                        _input.text = text;
                        _send();
                      },
                    ),
                  ],
                  for (final turn in _visibleTurns) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _TurnBubble(turn: turn),
                    ),
                    for (final block in _blocksOf(turn))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _blockView(block, theme),
                      ),
                  ],
                  for (final step in _steps)
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        step.failed ? Icons.error_outline : Icons.check_circle_outline,
                        color: step.failed ? theme.colorScheme.error : null,
                        size: 20,
                      ),
                      title: Text(step.call.name.replaceAll('_', ' ')),
                      subtitle: Text(step.result),
                    ),
                  for (final step in _steps)
                    for (final block in step.blocks)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _blockView(block, theme),
                      ),
                  if (_reply != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(_reply!, style: theme.textTheme.bodyMedium),
                    ),
                  for (final proposal in _proposals)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _ProposalCard(
                        proposal: proposal,
                        expanded: _expandedProposal == proposal.id,
                        onTap: () => setState(
                          () => _expandedProposal =
                              _expandedProposal == proposal.id
                                  ? null
                                  : proposal.id,
                        ),
                        onAccept: widget.onAcceptProposal == null
                            ? null
                            : () => _resolveProposal(
                                  proposal,
                                  widget.onAcceptProposal,
                                ),
                        labels: widget.labels,
                        onEdit: widget.onEditProposal == null
                            ? null
                            : () => widget.onEditProposal!(proposal),
                        onDiscard: widget.onDiscardProposal == null
                            ? null
                            : () => _resolveProposal(
                                  proposal,
                                  widget.onDiscardProposal,
                                ),
                      ),
                    ),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        _error!,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: theme.colorScheme.error),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (_busy)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.labels.working,
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                  TextButton(
                    onPressed: _stop,
                    child: Text(widget.labels.stop),
                  ),
                ],
              ),
            ),
          if (_proposals.isNotEmpty && widget.onAcceptProposal != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: FilledButton.icon(
                onPressed: _acceptAll,
                icon: const Icon(Icons.playlist_add),
                label: Text(
                  '${widget.labels.addAll} (${_proposals.length})',
                ),
              ),
            ),
          const SizedBox(height: 8),
          TextField(
            controller: _input,
            enabled: !_busy,
            minLines: 1,
            maxLines: 4,
            textInputAction: TextInputAction.send,
            onSubmitted: (_) => _send(),
            decoration: InputDecoration(
              hintText: widget.labels.inputHint,
              border: const OutlineInputBorder(),
              suffixIcon: _busy
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : IconButton(
                      icon: const Icon(Icons.arrow_upward),
                      onPressed: _send,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Suggestions extends StatelessWidget {
  const _Suggestions({required this.suggestions, required this.onTap});

  final List<String> suggestions;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    if (suggestions.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final suggestion in suggestions)
          ActionChip(label: Text(suggestion), onPressed: () => onTap(suggestion)),
      ],
    );
  }
}

/// One suggestion, collapsed to a headline until tapped.
///
/// Lifted from portal_task's plan card, minus everything task-shaped: no
/// duration, no recurrence, no kind enum. The host formats those into
/// [AiProposal.subtitle] before they get here.
class _ProposalCard extends StatelessWidget {
  const _ProposalCard({
    required this.proposal,
    required this.expanded,
    required this.onTap,
    required this.labels,
    this.onAccept,
    this.onEdit,
    this.onDiscard,
  });

  final AiProposal proposal;
  final bool expanded;
  final VoidCallback onTap;
  final AiChatLabels labels;
  final VoidCallback? onAccept;
  final VoidCallback? onEdit;
  final VoidCallback? onDiscard;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: expanded
                ? Border.all(color: theme.colorScheme.primary, width: 1.5)
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      proposal.title,
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  if (proposal.badge.isNotEmpty)
                    Chip(
                      label: Text(proposal.badge),
                      labelStyle: theme.textTheme.labelSmall,
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
              if (proposal.subtitle.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(proposal.subtitle, style: theme.textTheme.bodySmall),
              ],
              if (expanded)
                Row(
                  children: [
                    if (onAccept != null)
                      TextButton.icon(
                        onPressed: onAccept,
                        icon: const Icon(Icons.add, size: 18),
                        label: Text(labels.add),
                      ),
                    if (onEdit != null)
                      TextButton.icon(
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        label: Text(labels.edit),
                      ),
                    if (onDiscard != null)
                      TextButton.icon(
                        onPressed: onDiscard,
                        icon: const Icon(Icons.close, size: 18),
                        label: Text(labels.discard),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One side of the conversation.
class _TurnBubble extends StatelessWidget {
  const _TurnBubble({required this.turn});

  final AiChatTurn turn;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUser = turn.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.85,
        ),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isUser
              ? theme.colorScheme.primary.withValues(alpha: 0.15)
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(14),
            topRight: const Radius.circular(14),
            bottomLeft: Radius.circular(isUser ? 14 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 14),
          ),
        ),
        child: Text(
          turn.content,
          style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
        ),
      ),
    );
  }
}
