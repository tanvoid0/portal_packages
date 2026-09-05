import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../chat/ai_chat_export.dart';
import '../chat/ai_chat_session.dart';
import '../chat/ai_proposal.dart';
import '../chat/ai_suggestion.dart';
import '../clients/ai_completion_client.dart';
import '../runtime/portal_ai_runtime.dart';
import '../tools/ai_tool.dart';
import 'ai_chat_history_list.dart';
import 'ai_chat_labels.dart';
import 'ai_consent.dart';
import 'ai_suggestion_cards.dart';
import 'ai_item_list.dart';
import 'ai_markdown.dart';
import 'ai_prompt_composer.dart';
import 'ai_thinking_tile.dart';

/// Drop-in assistant UI: prompt box, live step log and a confirmation prompt
/// before any tool that changes data.
///
/// ```dart
/// AiAssistantPage.show(context, runtime: Get.find<PortalAiRuntime>());
/// ```
class AiAssistantPage extends StatefulWidget {
  const AiAssistantPage({
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
    this.onRewind,
    this.onCancel,
    this.labels = const AiChatLabels(),
    this.fill = false,
    this.store,
    this.onItemTap,
    this.initialPrompt,
    this.autoSend = false,
    this.consent,
    this.onAttach,
    this.maxPromptLength,
  }) : assert(
         runtime != null || onSend != null,
         'give the page a runtime to drive the agent, or an onSend that '
         'generates the reply itself',
       );

  /// Drives the agent loop. Null when [onSend] answers instead.
  final PortalAiRuntime? runtime;

  final String title;

  /// Prompts offered as cards before the first run.
  ///
  /// A plain list of sentences still works -- `AiSuggestion.prompts([...])`
  /// wraps them -- but a suggestion that carries a subtitle, an icon and a
  /// time-of-day bias gets a fuller card and a better slot in the rotation.
  final List<AiSuggestion> suggestions;

  /// Opens the app's own AI settings, when it has any. The model and key live
  /// on the server, so there is nothing to configure here by default.
  final VoidCallback? onSettings;

  /// Overrides [PortalAiRuntime.tools] for this page, for tools that have to
  /// be built per call site (e.g. closed over a Riverpod ref).
  final List<AiTool>? tools;

  /// Builders for [AiBlock.kind], so each app draws its own data.
  ///
  /// [AiBlock.itemsKind] is drawn by the assistant itself unless overridden
  /// here. Any other kind with no builder falls back to text: threads persist,
  /// so an old one can hold blocks whose renderer was since renamed or
  /// removed, and a reload must survive that rather than throw.
  final Map<String, Widget Function(AiBlock block)> renderers;

  /// Suggestions to add, edit or throw away, shown as cards with an "Add all"
  /// bar. Host-supplied: the page never invents one.
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
  /// Host-owned: an app with sessions rebuilds the page with the turns it has
  /// persisted, so history and reload cost the page nothing.
  final List<AiChatTurn> turns;

  /// Takes over sending. Set by apps that generate their own reply (portal_task
  /// asks `AiPlanService` for a plan) and then push the result back in through
  /// [turns] and [proposals], instead of running the tool agent.
  final Future<void> Function(String prompt)? onSend;

  /// Host-driven busy flag, ORed with the page's own.
  final bool busy;

  /// Drops [turns] from `index` onwards, for a host that owns the transcript.
  ///
  /// The page puts the question back in the composer itself; all the host has
  /// to do is forget the turns it is about to be asked again. Without this,
  /// [onSend] hosts get no edit and no retry -- the page cannot rewrite a list
  /// it does not own.
  final Future<void> Function(int index)? onRewind;

  /// Shows a stop button while busy when set.
  final VoidCallback? onCancel;

  final AiChatLabels labels;

  /// Where to keep this app's threads, if it wants history.
  ///
  /// With a store the page records the conversation, restores it from the
  /// history button and feeds the earlier turns back to the agent, so a
  /// follow-up can say "make it shorter". Without one it stays a one-shot.
  /// Ignored when [onSend] is set: that host owns its own sessions.
  final AiChatStore? store;

  /// Take all the height offered instead of hugging the content, so the
  /// composer sits at the bottom. Set by [show]; an embedded card wants the
  /// opposite.
  final bool fill;

  /// Opens a result row. Called with the block's [AiBlock.entity] and the row
  /// tapped; an [AiItem] with no id is one the assistant proposed but has not
  /// saved, so the host opens its create form rather than its editor. Rows are
  /// inert without this -- only the app knows what a recipe looks like.
  final void Function(String entity, AiItem item)? onItemTap;

  /// Put in the composer on first mount, for a caller that already has the
  /// question -- a voice launch that has finished transcribing, or a deep link
  /// carrying one.
  final String? initialPrompt;

  /// Gates the page behind a "what gets sent" card until accepted.
  ///
  /// Null for an app that needs no gate. While it is unaccepted the deck is
  /// inert and the composer is disabled, so there is one way past it.
  final AiConsent? consent;

  /// Adds an attachment button beside the counter. Null draws none.
  final VoidCallback? onAttach;

  /// Caps the composer and shows a counter. Null means neither.
  final int? maxPromptLength;

  /// Asks [initialPrompt] without waiting for the user to press send.
  ///
  /// Off by default, and deliberately: the prompt can come from outside the
  /// app, and sending it runs tools against the user's data. Turn it on only
  /// where the text is known to be either the user's own speech or a sentence
  /// this app composed itself. Only the first mount sends, so a rebuild does
  /// not ask twice.
  final bool autoSend;

  /// Opens the assistant as its own route.
  static Future<void> show(
    BuildContext context, {
    required PortalAiRuntime runtime,
    String title = 'Assistant',
    List<AiSuggestion> suggestions = const [],
    VoidCallback? onSettings,
    List<AiTool>? tools,
    Map<String, Widget Function(AiBlock block)> renderers = const {},
    List<AiProposal> proposals = const [],
    ValueChanged<AiProposal>? onAcceptProposal,
    ValueChanged<AiProposal>? onEditProposal,
    ValueChanged<AiProposal>? onDiscardProposal,
    AiChatLabels labels = const AiChatLabels(),
    AiChatStore? store,
    void Function(String entity, AiItem item)? onItemTap,
    AiConsent? consent,
    VoidCallback? onAttach,
    int? maxPromptLength,
  }) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          body: SafeArea(
            child: AiAssistantPage(
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
              onItemTap: onItemTap,
              consent: consent,
              onAttach: onAttach,
              maxPromptLength: maxPromptLength,
              fill: true,
            ),
          ),
        ),
      ),
    );
  }

  @override
  State<AiAssistantPage> createState() => _AiAssistantPageState();
}

class _AiAssistantPageState extends State<AiAssistantPage> {
  final _input = TextEditingController();
  final _scroll = ScrollController();

  /// Set by the stop button. The in-flight request cannot be recalled, so the
  /// answer is dropped when it lands rather than appearing minutes later.
  bool _cancelled = false;
  final _steps = <AiAgentStep>[];
  bool _running = false;
  String? _reply;

  /// Reasoning behind [_reply]; only used in one-shot mode, since a kept turn
  /// carries its own in the payload.
  String? _replyThinking;
  String? _error;

  /// Accepting or discarding removes a card here and now; the host is told, but
  /// the page does not wait for it to hand back a new list.
  late List<AiProposal> _proposals = List.of(widget.proposals);
  String? _expandedProposal;

  /// Only used in store mode; when the host passes [AiAssistantPage.onSend] it
  /// owns the transcript and these stay empty.
  final _turns = <AiChatTurn>[];
  final _sessions = <AiChatSessionSummary>[];
  String? _sessionId;

  /// Which prompts the deck shows, and what swaps them. Seeded from the app's
  /// own list so two visits do not open on the same three cards, topped up
  /// with whatever the model suggests.
  late final _rotator = AiSuggestionRotator(pool: widget.suggestions)
    ..refresh();

  /// Swaps one card every so often while the deck is the only thing on screen.
  /// Cancelled the moment a conversation starts -- nothing should move under a
  /// reply someone is reading.
  Timer? _rotation;

  bool _loadingIdeas = false;

  /// True while the deck is what the user is looking at.
  bool get _showingDeck =>
      _steps.isEmpty &&
      _proposals.isEmpty &&
      _visibleTurns.isEmpty &&
      _reply == null &&
      _error == null;

  bool get _gated => widget.consent?.accepted == false;

  void _syncRotation() {
    final wanted = _showingDeck && !_gated && _rotator.canRotate;
    if (wanted == (_rotation != null)) return;
    _rotation?.cancel();
    _rotation = wanted
        ? Timer.periodic(const Duration(seconds: 14), (_) {
            if (!mounted) return;
            setState(_rotator.rotateOne);
          })
        : null;
  }

  Future<void> _freshIdeas() async {
    final runtime = widget.runtime;
    if (runtime == null || _loadingIdeas) return;
    setState(() => _loadingIdeas = true);
    final ideas = await runtime.suggestPrompts(
      seed: [for (final s in widget.suggestions) s.prompt],
    );
    if (!mounted) return;
    setState(() {
      _loadingIdeas = false;
      // An empty list means the backend could not answer; keep what is on
      // screen rather than blanking the deck. What does come back joins the
      // pool instead of replacing it, so the app's curated cards survive.
      if (ideas.isEmpty) return;
      _rotator
        ..mergePool(AiSuggestion.prompts(ideas))
        ..refresh();
    });
  }

  List<AiChatTurn> get _visibleTurns =>
      widget.onSend != null ? widget.turns : _turns;

  @override
  void initState() {
    super.initState();
    _reloadSessions();
    _syncRotation();
    final initial = widget.initialPrompt?.trim();
    if (initial == null || initial.isEmpty) return;
    _input.text = initial;
    if (!widget.autoSend) return;
    // After the first frame: _send() calls setState, and the confirm dialog
    // for a mutating tool needs a mounted route to sit on.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_send());
    });
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
        title:
            existing?.title ??
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

  /// Puts the whole conversation on the clipboard as JSON.
  ///
  /// The transcript is only half of what tuning the assistant needs, so the
  /// system prompt and tool specs go with it. The clipboard is the export:
  /// pasting into a chat or an issue is what people actually do with this, and
  /// it costs no plugin and no file permission.
  Future<void> _exportChat() async {
    final runtime = widget.runtime;
    String? prompt;
    var specs = const <String>[];
    if (runtime != null) {
      final tools = widget.tools ?? runtime.tools;
      specs = [for (final tool in tools) tool.spec];
      try {
        prompt = runtime.systemPromptFor(widget.tools);
      } on AiCompletionException {
        // No usable backend configured: the turns are still worth exporting.
      }
    }
    final json = aiChatExportJson(
      app: widget.title,
      title: _sessionId == null ? null : widget.store?.load(_sessionId!)?.title,
      turns: _visibleTurns,
      at: DateTime.now(),
      systemPrompt: prompt,
      toolSpecs: specs,
    );
    await Clipboard.setData(ClipboardData(text: json));
    if (!mounted) return;
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      const SnackBar(content: Text('Conversation copied as JSON')),
    );
  }

  Future<void> _showHistory() async {
    final store = widget.store;
    if (store == null) return;
    final chosen = await showDialog<String>(
      context: context,
      builder: (dialogContext) => Dialog(
        // Deleting keeps the dialog open, so it rebuilds from the store rather
        // than from the list this page captured when it opened.
        child: StatefulBuilder(
          builder: (dialogContext, setDialogState) => SizedBox(
            height: 420,
            child: AiChatHistoryList(
              sessions: _sessions,
              selectedId: _sessionId,
              labels: widget.labels,
              width: 320,
              subtitleFor: (s) => '${s.turnCount} ${widget.labels.messages}',
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
  void didUpdateWidget(AiAssistantPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.proposals, widget.proposals)) {
      _proposals = List.of(widget.proposals);
    }
    _syncRotation();
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
    _rotation?.cancel();
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

  /// The last thing the user asked, so a failure or an edit has something to
  /// re-send. Null in host-driven mode: that host owns its transcript.
  AiChatTurn? get _lastUserTurn {
    if (widget.onSend != null && widget.onRewind == null) return null;
    for (final turn in _visibleTurns.reversed) {
      if (turn.isUser) return turn;
    }
    return null;
  }

  /// Drops everything from the last question onwards. Re-sending is one
  /// call, not two: rewinding is the whole job, whether the answer failed or
  /// the user wants to reword it.
  ///
  /// [refill] puts the question's own text back in the composer — that's
  /// "edit". A plain delete (`refill: false`) just removes it.
  Future<void> _rewindToLastQuestion({bool refill = true}) async {
    final turns = _visibleTurns;
    final index = turns.lastIndexWhere((t) => t.isUser);
    if (index < 0) return;
    setState(() {
      if (refill) {
        _input.text = turns[index].content;
        _input.selection = TextSelection.collapsed(offset: _input.text.length);
      }
      _error = null;
      _steps.clear();
      if (widget.onSend == null) _turns.removeRange(index, _turns.length);
    });
    if (widget.onSend != null) await widget.onRewind?.call(index);
  }

  Future<void> _deleteLastQuestion() => _rewindToLastQuestion(refill: false);

  Future<void> _retry() async {
    await _rewindToLastQuestion();
    if (!mounted || _input.text.trim().isEmpty) return;
    await _send();
  }

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
    final clock = Stopwatch()..start();
    setState(() {
      _running = true;
      _cancelled = false;
      _reply = null;
      _error = null;
      _steps.clear();
      if (keeping) {
        _input.clear();
        _turns.add(
          AiChatTurn(role: 'user', content: prompt, at: DateTime.now()),
        );
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
        setState(() {
          _reply = result.message;
          _replyThinking = result.thinking;
        });
        return;
      }
      setState(() {
        _turns.add(
          AiChatTurn(
            role: 'assistant',
            content: result.message,
            at: DateTime.now(),
            took: clock.elapsed,
            payload: {
              'blocks': [
                for (final step in _steps)
                  for (final block in step.blocks) block.toJson(),
              ],
              if (result.thinking != null) 'thinking': result.thinking,
              if (_steps.isNotEmpty) 'step_count': _steps.length,
              if (result.stats case final stats?) ...{
                'model': ?stats.model,
                'tokens': ?stats.totalTokens,
              },
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
      final result = await tool.call(call);
      if (mounted) {
        setState(
          () => _steps.add(
            AiAgentStep(
              call: call,
              result: result.forModel,
              blocks: result.blocks,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(
          () => _steps.add(
            AiAgentStep(call: call, result: e.toString(), failed: true),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _running = false);
    }
  }

  /// Reasoning a turn carries, if the backend reported any.
  String? _thinkingOf(AiChatTurn turn) {
    if (turn.isUser) return null;
    final raw = turn.payload?['thinking'];
    return raw is String && raw.trim().isNotEmpty ? raw : null;
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

  Widget _blockBody(AiBlock block, ThemeData theme) {
    final custom = widget.renderers[block.kind];
    if (custom != null) return custom(block);
    if (block.kind == AiBlock.itemsKind) {
      final open = widget.onItemTap;
      // A block with no entity is rows the host cannot open -- an aggregate,
      // a computed total. Those stay inert rather than offering a chevron
      // that goes nowhere.
      final openable = open != null && block.entity.isNotEmpty;
      return AiItemList(
        items: block.items,
        onTap: openable ? (item) => open(block.entity, item) : null,
      );
    }
    return Text(block.kind, style: theme.textTheme.bodySmall);
  }

  Widget _blockView(AiBlock block, ThemeData theme) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _blockBody(block, theme),
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

  /// One completed tool call: what ran, plus whatever it had to show. The raw
  /// result text is a fallback for a tool with no blocks of its own.
  Widget _stepView(AiAgentStep step, ThemeData theme) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      ListTile(
        dense: true,
        contentPadding: EdgeInsets.zero,
        leading: Icon(
          step.failed ? Icons.error_outline : Icons.check_circle_outline,
          color: step.failed ? theme.colorScheme.error : null,
          size: 20,
        ),
        title: Text(step.call.name.replaceAll('_', ' ')),
        subtitle: step.blocks.isEmpty ? Text(step.result) : null,
      ),
      for (final block in step.blocks)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _blockView(block, theme),
        ),
    ],
  );

  Future<bool> _confirm(AiTool tool, AiToolCall call) async {
    if (!mounted) return false;
    final approved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(tool.name.replaceAll('_', ' ')),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(tool.description),
              if (call.args.isNotEmpty) const SizedBox(height: 12),
              for (final arg in call.args.entries)
                _ArgRow(name: arg.key, value: arg.value),
            ],
          ),
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
        top: widget.fill ? 8 : 0,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: widget.fill ? MainAxisSize.max : MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.title.isNotEmpty ||
              widget.onSettings != null ||
              widget.store != null ||
              _visibleTurns.isNotEmpty) ...[
            Row(
              children: [
                if (widget.fill && Navigator.canPop(context))
                  const BackButton(),
                Expanded(
                  child: Text(widget.title, style: theme.textTheme.titleMedium),
                ),
                if (_visibleTurns.isNotEmpty)
                  IconButton(
                    tooltip: 'Copy conversation as JSON',
                    icon: const Icon(Icons.data_object),
                    onPressed: _exportChat,
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
                  if (_showingDeck) ...[
                    if (widget.consent case final consent?
                        when !consent.accepted)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: AiConsentCard(consent: consent),
                      )
                    else if (widget.labels.empty.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Text(
                          widget.labels.empty,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    const SizedBox(height: 8),
                    AiSuggestionCards(
                      suggestions: _rotator.visible,
                      enabled: !_gated,
                      onTap: (suggestion) {
                        _input.text = suggestion.prompt;
                        _send();
                      },
                      onShuffle: _rotator.canRotate
                          ? () => setState(_rotator.refresh)
                          : null,
                      // Only offered when there is a model to ask and a
                      // house style to imitate.
                      onRefresh: widget.runtime == null ? null : _freshIdeas,
                      refreshing: _loadingIdeas,
                      shuffleLabel: widget.labels.shuffle,
                      refreshLabel: widget.labels.moreIdeas,
                    ),
                  ],
                  for (final turn in _visibleTurns) ...[
                    if (_thinkingOf(turn) case final thinking?)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: AiThinkingTile(
                          thinking: thinking,
                          label: widget.labels.thinking,
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _TurnBubble(
                        turn: turn,
                        // Only the newest question can be acted on:
                        // rewriting or dropping an older one would mean
                        // throwing away every answer after it, which is a
                        // bigger promise than "let me fix that typo".
                        onEdit: !_busy && identical(turn, _lastUserTurn)
                            ? () => _rewindToLastQuestion()
                            : null,
                        onDelete: !_busy && identical(turn, _lastUserTurn)
                            ? _deleteLastQuestion
                            : null,
                        editLabel: widget.labels.edit,
                        deleteLabel: widget.labels.delete,
                      ),
                    ),
                    for (final block in _blocksOf(turn))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _blockView(block, theme),
                      ),
                  ],
                  for (final step in _steps) _stepView(step, theme),
                  if (_replyThinking case final thinking?)
                    AiThinkingTile(
                      thinking: thinking,
                      label: widget.labels.thinking,
                    ),
                  if (_reply != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: AiMarkdown(text: _reply!),
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
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _error!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.error,
                              ),
                            ),
                          ),
                          if (_lastUserTurn != null && !_busy)
                            TextButton.icon(
                              onPressed: _retry,
                              icon: const Icon(Icons.refresh, size: 18),
                              label: Text(widget.labels.retry),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (_proposals.isNotEmpty && widget.onAcceptProposal != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: FilledButton.icon(
                onPressed: _acceptAll,
                icon: const Icon(Icons.playlist_add),
                label: Text('${widget.labels.addAll} (${_proposals.length})'),
              ),
            ),
          const SizedBox(height: 8),
          AiPromptComposer(
            controller: _input,
            enabled: !_gated,
            busy: _busy,
            onStop: _stop,
            onSubmit: _send,
            onAttach: widget.onAttach,
            maxLength: widget.maxPromptLength,
            stopLabel: widget.labels.stop,
            attachLabel: widget.labels.attach,
            hintText: _gated
                ? widget.labels.consentBlocked
                : _busy
                    ? widget.labels.working
                    : widget.labels.inputHint,
          ),
        ],
      ),
    );
  }
}

/// One argument of a pending tool call, as a label and a readable value.
///
/// The user is being asked to approve a change to their own data, so the
/// arguments have to be legible -- a JSON dump is not an answer to "allow
/// this?".
class _ArgRow extends StatelessWidget {
  const _ArgRow({required this.name, required this.value});

  final String name;
  final Object? value;

  static String describe(Object? value) => switch (value) {
    null => '-',
    final List list => list.map(describe).join(', '),
    final Map map => map.values.map(describe).join(' '),
    _ => '$value',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 92,
            child: Text(
              name.replaceAll('_', ' '),
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(describe(value), style: theme.textTheme.bodySmall),
          ),
        ],
      ),
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
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
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
  const _TurnBubble({
    required this.turn,
    this.onEdit,
    this.onDelete,
    this.editLabel = 'Edit',
    this.deleteLabel = 'Delete',
  });

  final AiChatTurn turn;

  /// Puts this turn back in the composer. Null for anything not editable.
  final VoidCallback? onEdit;

  /// Drops this turn (and everything after it) with no re-typing. Null for
  /// anything not deletable.
  final VoidCallback? onDelete;
  final String editLabel;
  final String deleteLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUser = turn.isUser;
    final meta = _meta(context);
    // Only the user gets a bubble. The assistant's reply is the page's own
    // content -- boxing it just fights the app's background for contrast.
    if (!isUser) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AiMarkdown(text: turn.content),
          if (meta != null) _metaText(theme, meta),
        ],
      );
    }
    final scheme = theme.colorScheme;
    final canAct = onEdit != null || onDelete != null;
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Flexible(
          child: GestureDetector(
            // Long-press for actions, like every other chat bubble on the
            // platform -- a pencil icon sitting next to the bubble at all
            // times was one more thing to explain for an action people only
            // ever take right after sending.
            onLongPressStart: canAct
                ? (details) =>
                      _showActions(context, details.globalPosition, scheme)
                : null,
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.sizeOf(context).width * 0.85,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(4),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    turn.content,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      height: 1.45,
                      color: scheme.onPrimaryContainer,
                    ),
                  ),
                  if (meta != null)
                    _metaText(theme, meta, color: scheme.onPrimaryContainer),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showActions(
    BuildContext context,
    Offset position,
    ColorScheme scheme,
  ) async {
    HapticFeedback.selectionClick();
    final overlay =
        Overlay.of(context).context.findRenderObject()! as RenderBox;
    final action = await showMenu<VoidCallback>(
      context: context,
      position: RelativeRect.fromRect(
        position & const Size(1, 1),
        Offset.zero & overlay.size,
      ),
      items: [
        if (onEdit != null)
          PopupMenuItem(
            value: onEdit,
            child: ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: Text(editLabel),
              contentPadding: EdgeInsets.zero,
              dense: true,
            ),
          ),
        if (onDelete != null)
          PopupMenuItem(
            value: onDelete,
            child: ListTile(
              leading: Icon(Icons.delete_outline, color: scheme.error),
              title: Text(deleteLabel, style: TextStyle(color: scheme.error)),
              contentPadding: EdgeInsets.zero,
              dense: true,
            ),
          ),
      ],
    );
    action?.call();
  }

  /// `09:14 - 4.2s - 3 steps`, skipping whatever this turn does not know.
  /// Threads saved before turns carried a time show nothing at all.
  String? _meta(BuildContext context) {
    final parts = [
      if (turn.at case final at?)
        MaterialLocalizations.of(
          context,
        ).formatTimeOfDay(TimeOfDay.fromDateTime(at)),
      if (turn.took case final took?) _formatTook(took),
      if (turn.payload?['step_count'] case final int steps when steps > 0)
        '$steps ${steps == 1 ? 'step' : 'steps'}',
      if (turn.payload?['tokens'] case final int tokens when tokens > 0)
        '$tokens tokens',
      if (turn.payload?['model'] case final String model when model.isNotEmpty)
        model,
    ];
    return parts.isEmpty ? null : parts.join('  ·  ');
  }

  static String _formatTook(Duration took) {
    if (took.inSeconds < 60) {
      return '${(took.inMilliseconds / 1000).toStringAsFixed(1)}s';
    }
    return '${took.inMinutes}m ${took.inSeconds % 60}s';
  }

  Widget _metaText(ThemeData theme, String meta, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        meta,
        style: theme.textTheme.labelSmall?.copyWith(
          color: (color ?? theme.colorScheme.onSurfaceVariant).withValues(
            alpha: 0.7,
          ),
        ),
      ),
    );
  }
}
