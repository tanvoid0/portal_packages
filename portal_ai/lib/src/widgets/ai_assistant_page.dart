import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../chat/ai_attachment.dart';
import '../chat/ai_chat_export.dart';
import '../chat/ai_chat_session.dart';
import '../chat/ai_error_message.dart';
import '../chat/ai_proposal.dart';
import '../chat/ai_suggestion.dart';
import '../clients/ai_completion_client.dart';
import '../documents/ai_document_client.dart';
import '../documents/ai_document_import.dart';
import '../runtime/portal_ai_runtime.dart';
import '../tools/ai_agent.dart';
import '../tools/ai_tool.dart';
import 'ai_chat_history_list.dart';
import 'ai_chat_labels.dart';
import 'ai_consent.dart';
import 'ai_suggestion_cards.dart';
import 'ai_item_list.dart';
import 'ai_markdown.dart';
import 'ai_prompt_composer.dart';
import 'ai_settings_section.dart';
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
    this.avatar,
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
    this.onEditToolCall,
    this.canEditToolCall,
    this.initialPrompt,
    this.autoSend = false,
    this.consent,
    this.onAttach,
    this.documents,
    this.maxPromptLength,
  }) : assert(
         runtime != null || onSend != null,
         'give the page a runtime to drive the agent, or an onSend that '
         'generates the reply itself',
       );

  /// Drives the agent loop. Null when [onSend] answers instead.
  final PortalAiRuntime? runtime;

  final String title;

  /// What the header shows in place of the default assistant glyph.
  ///
  /// An app with its own assistant identity ("Coach", "Chef") passes an
  /// image or an icon here; it is clipped into the same circle and keeps the
  /// presence dot, so branding never costs the busy indicator.
  final Widget? avatar;

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

  /// Reads a picked file into text on the server, so a question can be asked
  /// about a receipt or a note. Set it and the composer's attach button picks
  /// a file itself; leave it null and [onAttach] is whatever the host wants.
  final AiDocumentClient? documents;

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

  /// Opens the app's own add/edit screen for a proposed change, prefilled
  /// from the call, and answers true when the user saved there.
  ///
  /// Only the app knows what its editor looks like or how to fill it, so the
  /// card offers Edit only where this is wired. Saving in the editor is the
  /// change being made -- the tool is not run again afterwards.
  final Future<bool> Function(AiToolCall call)? onEditToolCall;

  /// Whether [onEditToolCall] has a form for this call.
  ///
  /// An app's editor covers some of its tools and not others -- a recipe has
  /// a form, a meal-plan row does not -- and an Edit button that opens
  /// nothing is worse than no button. Null offers Edit for every call.
  final bool Function(AiToolCall call)? canEditToolCall;

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
    Widget? avatar,
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
    Future<bool> Function(AiToolCall call)? onEditToolCall,
    bool Function(AiToolCall call)? canEditToolCall,
    AiConsent? consent,
    VoidCallback? onAttach,
    AiDocumentClient? documents,
    int? maxPromptLength,
  }) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          body: SafeArea(
            child: AiAssistantPage(
              runtime: runtime,
              title: title,
              avatar: avatar,
              documents: documents,
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
              onEditToolCall: onEditToolCall,
              canEditToolCall: canEditToolCall,
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

  /// Focused by hand when the field appears. `autofocus` is not enough: the
  /// menu that opens search returns focus to whatever had it when it closes,
  /// which is the composer, so what the user typed went into the prompt.
  final _searchFocus = FocusNode();

  /// Set by the stop button. The in-flight request cannot be recalled, so the
  /// answer is dropped when it lands rather than appearing minutes later.
  bool _cancelled = false;
  final _steps = <AiAgentStep>[];
  bool _running = false;
  String? _reply;

  /// Reasoning behind [_reply]; only used in one-shot mode, since a kept turn
  /// carries its own in the payload.
  String? _replyThinking;

  /// The answer as it is being written, before the turn it belongs to exists.
  /// Null between runs.
  String? _streamingReply;

  /// Find-in-conversation. While [_chatQuery] is set the transcript shows only
  /// the turns that match; tapping one clears the search and scrolls to it.
  bool _searching = false;
  String _chatQuery = '';

  /// True when the newest turn is off screen, which is the only time a
  /// jump-to-latest button is worth the space.
  bool _scrolledUp = false;

  /// True once the transcript has scrolled off its top, which shrinks the
  /// header to a single line.
  bool _collapsed = false;

  /// A document read for the next prompt: its name for the chip, its text for
  /// the model. Cleared once sent.
  ({String name, String text})? _attachment;
  bool _reading = false;
  String? _error;

  /// The tool waiting on the user, drawn as a card at the end of the thread.
  _PendingConfirm? _pendingConfirm;

  /// Accepting or discarding removes a card here and now; the host is told, but
  /// the page does not wait for it to hand back a new list.
  late List<AiProposal> _proposals = List.of(widget.proposals);
  String? _expandedProposal;

  /// Only used in store mode; when the host passes [AiAssistantPage.onSend] it
  /// owns the transcript and these stay empty.
  final _turns = <AiChatTurn>[];
  final _sessions = <AiChatSessionSummary>[];
  String? _sessionId;

  /// Threads this page has already asked the model to name, and threads the
  /// user has named. Both keep [_autoTitle] from overwriting a good title.
  final _autoTitled = <String>{};
  final _renamed = <String>{};

  /// Which prompts the deck shows, and what swaps them. Seeded from the app's
  /// own list so two visits do not open on the same three cards, topped up
  /// with whatever the model suggests.
  late final _rotator = AiSuggestionRotator(pool: widget.suggestions)
    ..refresh();

  /// Swaps one card every so often while the deck is the only thing on screen.
  /// Cancelled the moment a conversation starts -- nothing should move under a
  /// reply someone is reading.
  Timer? _rotation;

  /// Kept so the keyboard does not drop after every send. A composer that
  /// closes the keyboard on submit makes a back-and-forth conversation a
  /// tap-to-reopen chore.
  final _inputFocus = FocusNode();

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

  /// What the transcript draws: everything, or the matches while a
  /// find-in-conversation is running.
  List<AiChatTurn> get _shownTurns {
    final query = _chatQuery.trim().toLowerCase();
    if (query.isEmpty) return _visibleTurns;
    return [
      for (final turn in _visibleTurns)
        if (turn.content.toLowerCase().contains(query)) turn,
    ];
  }

  /// Whether the next thing on screen is also the assistant talking.
  ///
  /// Messenger draws the face once per run, against the last bubble of it, so
  /// a multi-part answer reads as one voice rather than three arrivals. The
  /// live stream and a finished [_reply] both render below the turn list, so
  /// the last turn has to count them as what follows it.
  bool _assistantFollows(int index) {
    final turns = _shownTurns;
    if (index < turns.length - 1) return !turns[index + 1].isUser;
    return _streamingReply != null || _reply != null;
  }

  /// Leaves the search and puts [turn] on screen where it actually sits.
  void _revealTurn(AiChatTurn turn) {
    setState(() {
      _searching = false;
      _chatQuery = '';
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = GlobalObjectKey(turn).currentContext;
      if (context == null) return;
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 250),
        alignment: 0.2,
      );
    });
  }

  /// Reads a file into text for the next prompt. The text goes to the model,
  /// not into the transcript: nobody wants a receipt pasted into their chat.
  Future<void> _pickAttachment() async {
    final documents = widget.documents;
    if (documents == null || _reading) return;
    setState(() => _reading = true);
    try {
      final file = await pickAiDocument();
      if (file == null) return;
      final read = await documents.extractText(
        bytes: file.bytes,
        filename: file.name,
      );
      if (!mounted) return;
      setState(() => _attachment = (name: file.name, text: read.text));
    } catch (e) {
      if (mounted) _failWith(e);
    } finally {
      if (mounted) setState(() => _reading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_watchScroll);
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
        pinned: existing?.pinned ?? false,
      ),
    );
    if (mounted) setState(_reloadSessions);
    unawaited(_autoTitle(id));
  }

  /// Threads titled from the first message all read alike ("Can you help me
  /// wi..."), so the model names one once there is an exchange to name. Once
  /// only, and never over a title the user typed -- [_renameSession] marks
  /// those so this leaves them alone.
  Future<void> _autoTitle(String id) async {
    final runtime = widget.runtime;
    final store = widget.store;
    if (runtime == null || store == null) return;
    if (_autoTitled.contains(id) || _renamed.contains(id)) return;
    final session = store.load(id);
    if (session == null || session.turns.length < 2) return;
    _autoTitled.add(id);
    final title = await runtime.suggestTitle(session.turns);
    if (title.isEmpty || _renamed.contains(id)) return;
    final latest = store.load(id);
    if (latest == null) return;
    await store.save(latest.copyWith(title: title));
    if (mounted) setState(_reloadSessions);
  }

  Future<void> _renameSession(String id, String title) async {
    final store = widget.store;
    final session = store?.load(id);
    if (store == null || session == null) return;
    _renamed.add(id);
    await store.save(session.copyWith(title: title));
    if (mounted) setState(_reloadSessions);
  }

  Future<void> _setPinned(String id, bool pinned) async {
    final store = widget.store;
    final session = store?.load(id);
    if (store == null || session == null) return;
    await store.save(session.copyWith(pinned: pinned));
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
  Future<void> _exportChat({required bool asJson}) async {
    if (!asJson) {
      await Clipboard.setData(
        ClipboardData(
          text: aiChatExportMarkdown(
            app: widget.title,
            title: _sessionId == null
                ? null
                : widget.store?.load(_sessionId!)?.title,
            turns: _visibleTurns,
            at: DateTime.now(),
          ),
        ),
      );
      if (!mounted) return;
      ScaffoldMessenger.maybeOf(
        context,
      )?.showSnackBar(SnackBar(content: Text(widget.labels.copied)));
      return;
    }
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
              onRename: (id, title) async {
                await _renameSession(id, title);
                if (dialogContext.mounted) setDialogState(() {});
              },
              onSetPinned: (id, pinned) async {
                await _setPinned(id, pinned);
                if (dialogContext.mounted) setDialogState(() {});
              },
              onDelete: (id) async {
                await _deleteSession(id);
                if (_sessions.isEmpty) {
                  if (dialogContext.mounted) {
                    Navigator.of(dialogContext).pop();
                  }
                  return;
                }
                if (dialogContext.mounted) setDialogState(() {});
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
    // A page torn down mid-question leaves the agent awaiting an answer that
    // can never arrive, so it is refused on the way out.
    _answerConfirm(false);
    _rotation?.cancel();
    _scroll.removeListener(_watchScroll);
    _inputFocus.dispose();
    _searchFocus.dispose();
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  /// Keeps the newest turn in view; a long thread otherwise grows below the
  /// fold and the reply looks like it never arrived.
  void _followNewest({bool force = true}) {
    // Reading back through a long answer must not be yanked to the end by the
    // next chunk arriving, so a stream only follows when the user is already
    // at the bottom.
    if (!force && !_atBottom) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  void _watchScroll() {
    final scrolledUp = !_atBottom;
    // Messenger drops its subtitle line as soon as the thread moves, giving
    // the transcript the height back. One threshold, no animation curve of
    // our own -- AnimatedCrossFade below owns the transition.
    final collapsed = _scroll.hasClients && _scroll.position.pixels > 24;
    if (scrolledUp == _scrolledUp && collapsed == _collapsed) return;
    setState(() {
      _scrolledUp = scrolledUp;
      _collapsed = collapsed;
    });
  }

  static const _bottomSlack = 80.0;

  bool get _atBottom {
    if (!_scroll.hasClients) return true;
    final position = _scroll.position;
    return position.maxScrollExtent - position.pixels <= _bottomSlack;
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
    final index = _visibleTurns.lastIndexWhere((t) => t.isUser);
    if (index < 0) return;
    await _rewindTo(index, refill: refill);
  }

  /// [index] is the question to go back to. Everything from it onwards goes,
  /// which for an older question means dropping answers the user has read --
  /// so that case asks first.
  Future<void> _rewindTo(int index, {bool refill = true}) async {
    final turns = _visibleTurns;
    if (index < 0 || index >= turns.length) return;
    // Its own answer going with it is the point; anything beyond that is
    // work the user has already read, so ask.
    final after = turns.length - index - 1;
    if (after > 1 && !await _confirmRewind(after)) return;
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

  Future<bool> _confirmRewind(int dropped) async {
    final labels = widget.labels;
    final approved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        content: Text(labels.rewindWarning.replaceAll('@count', '$dropped')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(labels.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(labels.rewind),
          ),
        ],
      ),
    );
    return approved ?? false;
  }

  /// Host-driven mode owns its own transcript; without an [onRewind] to tell
  /// it, going back would only lie to the screen.
  bool _canRewind(AiChatTurn turn) =>
      turn.isUser && (widget.onSend == null || widget.onRewind != null);

  Future<void> _retry() async {
    await _rewindToLastQuestion();
    if (!mounted || _input.text.trim().isEmpty) return;
    await _send();
  }

  Future<void> _send() async {
    final prompt = _input.text.trim();
    if (prompt.isEmpty) return;
    // With a card open the run is not busy, it is waiting on the user. What
    // they typed is the answer: decline this call, and hand the model the
    // correction so it proposes again rather than stopping.
    if (_pendingConfirm != null) {
      _input.clear();
      _answerConfirm(false, note: prompt);
      return;
    }
    if (_busy) return;
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
        if (mounted && !_cancelled) _failWith(e);
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
          AiChatTurn(
            role: 'user',
            content: prompt,
            at: DateTime.now(),
            // The document's text goes to the model, not into the bubble;
            // the name is what makes the turn make sense on a reload.
            payload: _attachment == null
                ? null
                : {'attachment': _attachment!.name},
          ),
        );
      }
    });
    try {
      final result = await widget.runtime!.ask(
        _withAttachment(prompt),
        tools: widget.tools,
        history: history,
        confirm: _confirm,
        onStep: (step) {
          if (!mounted || _cancelled) return;
          setState(() => _steps.add(step));
          _followNewest();
        },
        onReply: (delta) {
          if (!mounted || _cancelled) return;
          setState(() => _streamingReply = (_streamingReply ?? '') + delta);
          _followNewest(force: false);
        },
      );
      if (!mounted || _cancelled) return;
      if (!keeping) {
        setState(() {
          _reply = result.message;
          _replyThinking = result.thinking;
          _streamingReply = null;
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
        _streamingReply = null;
      });
      _followNewest();
      await _persist();
    } catch (e) {
      if (!mounted || _cancelled) return;
      setState(() {
        _error = _messageFor(e);
        _streamingReply = null;
      });
      _followNewest();
      // Keep the question even though the answer failed: without this the
      // user's turn is on screen but gone after a reload.
      await _persist();
    } finally {
      if (mounted) {
        setState(() {
          _running = false;
          _streamingReply = null;
          // One prompt, one document: keeping it around would silently
          // re-send it with the next question.
          _attachment = null;
        });
        // Straight back to typing: the keyboard staying up is the difference
        // between a conversation and a form you fill in one field at a time.
        _inputFocus.requestFocus();
      }
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
    if (tool.mutates && !(await _confirm(tool, call)).accepted) return;

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
  /// A step's result as something worth reading.
  ///
  /// Tool results are written for the model. The refusal sentence in
  /// particular carries the user's own correction back to it -- "user declined
  /// this action and asked instead: make it vegan" -- and printing that
  /// verbatim reads like the app talking about the user in the third person.
  static String _stepResultText(String result) {
    const declined = 'user declined this action';
    if (!result.startsWith(declined)) return result;
    final note = result.substring(declined.length).replaceFirst(
      RegExp(r'^ and asked instead: '),
      '',
    );
    return note.trim().isEmpty ? 'Declined' : 'Declined — asked for: $note';
  }

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
        title: Text(aiToolTitle(step.call.name)),
        subtitle: step.blocks.isEmpty
            // A tool result is written for the model, and some are long --
            // image_search returns a screenful of Unsplash URLs. Two lines is
            // enough to say what happened without burying the conversation.
            ? Text(
                _stepResultText(step.result),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              )
            : null,
      ),
      for (final block in step.blocks)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _blockView(block, theme),
        ),
    ],
  );

  Future<AiToolDecision> _confirm(AiTool tool, AiToolCall call) async {
    if (!mounted) return const AiToolDecision.declined();
    // Asked in the transcript, not over it. A modal hid the question that
    // caused the tool call and the answer so far, which is exactly the
    // context needed to judge whether to allow it -- and it did not match
    // the proposal cards portal_task already asks with.
    // Resolved before the card goes up: an id in an argument row says
    // nothing, and the answer to "delete this?" depends entirely on which
    // one. A tool that cannot resolve it -- a bad id, a repo that will not
    // read -- must still get its question asked, so the lookup failing is
    // not the question failing.
    AiItem? preview;
    try {
      preview = await tool.preview?.call(call);
    } catch (_) {
      preview = null;
    }
    if (!mounted) return const AiToolDecision.declined();
    final pending = _PendingConfirm(tool: tool, call: call, preview: preview);
    setState(() => _pendingConfirm = pending);
    _followNewest();
    final decision = await pending.answer.future;
    if (mounted && identical(_pendingConfirm, pending)) {
      setState(() => _pendingConfirm = null);
    }
    return decision;
  }

  bool _canEdit(AiToolCall call) =>
      widget.onEditToolCall != null &&
      (widget.canEditToolCall?.call(call) ?? true);

  /// Hands the proposed call to the app's editor.
  ///
  /// Saving there *is* the change, so the tool must not also run: the call is
  /// declined with a note saying so, or the card is left standing if the user
  /// backed out of the editor without saving.
  Future<void> _editPending(_PendingConfirm pending) async {
    final edit = widget.onEditToolCall;
    if (edit == null || pending.answer.isCompleted) return;
    final saved = await edit(pending.call);
    if (!mounted || pending.answer.isCompleted) return;
    if (!saved) return;
    _answerConfirm(
      false,
      note:
          'the user opened the editor and saved this themselves; do not '
          'call this tool again for it',
    );
  }

  void _toggleSearch() {
    setState(() {
      _searching = !_searching;
      if (!_searching) _chatQuery = '';
    });
    if (!_searching) return;
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _searchFocus.requestFocus(),
    );
  }

  /// Answers the open card. [note] is what the user typed instead of pressing
  /// a button: it declines this call and tells the model what to do instead,
  /// so a proposal can be corrected without leaving the conversation.
  void _answerConfirm(bool accepted, {String? note}) {
    final pending = _pendingConfirm;
    if (pending == null || pending.answer.isCompleted) return;
    pending.answer.complete(
      accepted
          ? const AiToolDecision.accepted()
          : AiToolDecision.declined(note: note),
    );
  }

  String _withAttachment(String prompt) {
    final attachment = _attachment;
    if (attachment == null) return prompt;
    return aiPromptWithAttachment(
      prompt: prompt,
      name: attachment.name,
      text: attachment.text,
    );
  }

  /// Records a failure and brings it into view.
  ///
  /// The bubble is appended at the end of the thread, so without the scroll
  /// it lands under the composer and the run looks like it simply stopped.
  void _failWith(Object error) {
    setState(
      () => _error = aiErrorMessage(error, offline: widget.labels.offline),
    );
    _followNewest();
  }

  String _messageFor(Object error) =>
      aiErrorMessage(error, offline: widget.labels.offline);

  void _copyTurn(AiChatTurn turn) {
    Clipboard.setData(ClipboardData(text: turn.content));
    HapticFeedback.selectionClick();
    ScaffoldMessenger.maybeOf(
      context,
    )?.showSnackBar(SnackBar(content: Text(widget.labels.copied)));
  }

  /// The provider and model picker, one tap from the conversation.
  ///
  /// Switching model mid-thread is the whole point -- ask the cheap local one
  /// first, hand the hard question to the cloud -- and sending someone to the
  /// app's settings screen and back loses the thread they were in.
  Future<void> _showBackendPicker() async {
    final runtime = widget.runtime;
    final store = runtime?.backendStore;
    if (runtime == null || store == null) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: AiSettingsSection(
            store: store,
            onChanged: (option) {
              runtime.applyBackend(option);
              if (mounted) setState(() {});
            },
          ),
        ),
      ),
    );
    if (mounted) setState(() {});
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
                  const BackButton(
                    style: ButtonStyle(visualDensity: VisualDensity.compact),
                  ),
                _AiPresenceAvatar(
                  busy: _busy,
                  local: widget.runtime?.usesLocalModel ?? false,
                  avatar: widget.avatar,
                ),
                const SizedBox(width: 8),
                Expanded(
                  // Messenger-style stacked title: the name on one tight line
                  // with the backend underneath it, instead of a title row
                  // fighting an ActionChip for horizontal space.
                  child: InkWell(
                    onTap: widget.runtime?.backendStore == null
                        ? null
                        : _showBackendPicker,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              height: 1.1,
                            ),
                            // Without these the row's fixed children (back
                            // button, avatar, up to five icons) leave the
                            // title a few logical pixels, and it wraps one
                            // letter per line down the whole screen instead
                            // of ellipsing.
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (widget.runtime != null)
                            AnimatedCrossFade(
                              duration: const Duration(milliseconds: 150),
                              firstChild: const SizedBox(
                                height: 0,
                                width: double.infinity,
                              ),
                              secondChild: Text(
                                _busy
                                    ? widget.labels.thinking
                                    : widget.runtime!.backendLabel,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                  height: 1.1,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              crossFadeState: _collapsed
                                  ? CrossFadeState.showFirst
                                  : CrossFadeState.showSecond,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Find and the two export formats share one overflow menu.
                // As separate icons they were 96dp of a 411dp row that also
                // carries the back button, the backend chip and two more
                // icons, which left the title nothing to render into.
                if (_visibleTurns.isNotEmpty)
                  PopupMenuButton<_ChatMenuAction>(
                    tooltip: widget.labels.share,
                    icon: const Icon(Icons.more_vert),
                    iconSize: 20,
                    padding: EdgeInsets.zero,
                    onSelected: (action) => switch (action) {
                      _ChatMenuAction.find => _toggleSearch(),
                      _ChatMenuAction.copyAsMarkdown => _exportChat(
                        asJson: false,
                      ),
                      _ChatMenuAction.copyAsJson => _exportChat(asJson: true),
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: _ChatMenuAction.find,
                        child: Text(widget.labels.searchInChat),
                      ),
                      PopupMenuItem(
                        value: _ChatMenuAction.copyAsMarkdown,
                        child: Text(widget.labels.copyAsMarkdown),
                      ),
                      PopupMenuItem(
                        value: _ChatMenuAction.copyAsJson,
                        child: Text(widget.labels.copyAsJson),
                      ),
                    ],
                  ),
                if (widget.store != null) ...[
                  IconButton(
                    tooltip: widget.labels.historyTitle,
                    icon: const Icon(Icons.history),
                    iconSize: 20,
                    visualDensity: VisualDensity.compact,
                    onPressed: _showHistory,
                  ),
                  IconButton(
                    tooltip: widget.labels.newChat,
                    icon: const Icon(Icons.add_comment_outlined),
                    iconSize: 20,
                    visualDensity: VisualDensity.compact,
                    onPressed: _newChat,
                  ),
                ],
                if (widget.onSettings != null)
                  IconButton(
                    tooltip: 'AI settings',
                    icon: const Icon(Icons.tune),
                    iconSize: 20,
                    visualDensity: VisualDensity.compact,
                    onPressed: widget.onSettings,
                  ),
              ],
            ),
            if (_searching)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: TextField(
                  focusNode: _searchFocus,
                  onChanged: (value) => setState(() => _chatQuery = value),
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: widget.labels.searchInChatHint,
                    prefixIcon: const Icon(Icons.search, size: 18),
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
            const SizedBox(height: 8),
          ],
          Flexible(
            fit: widget.fill ? FlexFit.tight : FlexFit.loose,
            child: Stack(
              children: [
                SingleChildScrollView(
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
                          onRefresh: widget.runtime == null
                              ? null
                              : _freshIdeas,
                          refreshing: _loadingIdeas,
                          shuffleLabel: widget.labels.shuffle,
                          refreshLabel: widget.labels.moreIdeas,
                        ),
                      ],
                      for (final (index, turn) in _shownTurns.indexed) ...[
                        if (_thinkingOf(turn) case final thinking?)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: AiThinkingTile(
                              thinking: thinking,
                              label: widget.labels.thinking,
                            ),
                          ),
                        Padding(
                          key: GlobalObjectKey(turn),
                          padding: const EdgeInsets.only(bottom: 12),
                          child: GestureDetector(
                            onTap: _chatQuery.trim().isEmpty
                                ? null
                                : () => _revealTurn(turn),
                            child: _TurnBubble(
                              turn: turn,
                              avatar: widget.avatar,
                              local: widget.runtime?.usesLocalModel ?? false,
                              showAvatar: !_assistantFollows(index),
                              onCopy: () => _copyTurn(turn),
                              copyLabel: widget.labels.copy,
                              copiedLabel: widget.labels.copied,
                              youLabel: widget.labels.youSaid,
                              assistantLabel: widget.labels.assistantSaid,
                              // Any question can be reworked, not just the newest:
                              // the mistake worth fixing is often three turns back.
                              // Going back drops the answers after it, so
                              // _rewindTo asks before throwing away more than the
                              // last exchange.
                              onEdit: !_busy && _canRewind(turn)
                                  ? () => _rewindTo(_visibleTurns.indexOf(turn))
                                  : null,
                              onDelete: !_busy && _canRewind(turn)
                                  ? () => _rewindTo(
                                      _visibleTurns.indexOf(turn),
                                      refill: false,
                                    )
                                  : null,
                              editLabel: widget.labels.edit,
                              deleteLabel: widget.labels.delete,
                            ),
                          ),
                        ),
                        for (final block in _blocksOf(turn))
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _blockView(block, theme),
                          ),
                      ],
                      for (final step in _steps) _stepView(step, theme),
                      if (_streamingReply case final partial?
                          when partial.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Semantics(
                            liveRegion: true,
                            child: _assistantBubble(
                              context,
                              AiMarkdown(text: partial),
                              avatar: widget.avatar,
                              local: widget.runtime?.usesLocalModel ?? false,
                            ),
                          ),
                        ),
                      if (_replyThinking case final thinking?)
                        AiThinkingTile(
                          thinking: thinking,
                          label: widget.labels.thinking,
                        ),
                      if (_reply != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: _assistantBubble(
                            context,
                            AiMarkdown(text: _reply!),
                            avatar: widget.avatar,
                            local: widget.runtime?.usesLocalModel ?? false,
                          ),
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
                      if (_pendingConfirm case final pending?)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _ConfirmCard(
                            pending: pending,
                            onAccept: () => _answerConfirm(true),
                            onDecline: () => _answerConfirm(false),
                            onEdit: _canEdit(pending.call)
                                ? () => _editPending(pending)
                                : null,
                          ),
                        ),
                      // A failure is part of the conversation, so it reads as one:
                      // the assistant's own bubble shape in the error colours,
                      // rather than loose red text that ran the width of the page
                      // and pushed Retry off to the side.
                      if (_error != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              constraints: BoxConstraints(
                                maxWidth:
                                    MediaQuery.sizeOf(context).width * 0.85,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.errorContainer,
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(16),
                                  topRight: Radius.circular(16),
                                  bottomLeft: Radius.circular(4),
                                  bottomRight: Radius.circular(16),
                                ),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _error!,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      height: 1.45,
                                      color: theme.colorScheme.onErrorContainer,
                                    ),
                                  ),
                                  if (_lastUserTurn != null && !_busy)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: TextButton.icon(
                                        onPressed: _retry,
                                        icon: const Icon(
                                          Icons.refresh,
                                          size: 18,
                                        ),
                                        label: Text(widget.labels.retry),
                                        style: TextButton.styleFrom(
                                          foregroundColor: theme
                                              .colorScheme
                                              .onErrorContainer,
                                          padding: EdgeInsets.zero,
                                          visualDensity: VisualDensity.compact,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                // Only while the newest turn is off screen: an always-there
                // button sits on top of the answer you are reading.
                if (_scrolledUp)
                  Positioned(
                    right: 0,
                    bottom: 8,
                    child: FloatingActionButton.small(
                      heroTag: null,
                      tooltip: widget.labels.jumpToLatest,
                      onPressed: _followNewest,
                      child: const Icon(Icons.arrow_downward),
                    ),
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
                label: Text('${widget.labels.addAll} (${_proposals.length})'),
              ),
            ),
          const SizedBox(height: 8),
          if (_reading || _attachment != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: _reading
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            widget.labels.readingFile,
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      )
                    : InputChip(
                        avatar: const Icon(
                          Icons.description_outlined,
                          size: 16,
                        ),
                        label: Text(
                          '${widget.labels.attached}: ${_attachment!.name}',
                          overflow: TextOverflow.ellipsis,
                        ),
                        onDeleted: () => setState(() => _attachment = null),
                        deleteButtonTooltipMessage:
                            widget.labels.removeAttachment,
                      ),
              ),
            ),
          AiPromptComposer(
            controller: _input,
            focusNode: _inputFocus,
            enabled: !_gated,
            busy: _busy && _pendingConfirm == null,
            onStop: _stop,
            onSubmit: _send,
            onAttach: widget.documents != null
                ? _pickAttachment
                : widget.onAttach,
            maxLength: widget.maxPromptLength,
            stopLabel: widget.labels.stop,
            attachLabel: widget.labels.attach,
            hintText: _gated
                ? widget.labels.consentBlocked
                : (_busy && _pendingConfirm == null)
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
    // Steps and ingredients are sentences. Joined with a comma they read as
    // "Preheat the oven., Cut the aubergine.", so each gets its own line.
    final List list => list.map(describe).join('\n'),
    // Rows arrive as {recipe_id, date, meal_type, servings}. The id is the
    // one value a person cannot check -- "868faf5c-bdc9-4f55 2026-09-08
    // dinner 4" is not an answer to "allow this?" -- so it is dropped, unless
    // dropping leaves nothing to show.
    final Map map => switch (map.values
        .where((v) => !_looksLikeId(v))
        .map(describe)
        .join(' ')) {
      '' => map.values.map(describe).join(' '),
      final kept => kept,
    },
    _ => '$value',
  };

  static final _uuid = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
    caseSensitive: false,
  );

  static bool _looksLikeId(Object? value) =>
      value is String && _uuid.hasMatch(value.trim());

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
/// The assistant's side of the thread.
///
/// Left bare, a reply sat on the page's own background at the same tone as
/// everything around it, so a thread read as one undifferentiated block. The
/// outline is what guarantees an edge whatever surface the host app puts
/// behind us -- surfaceContainerHigh alone can land a hair off a tinted
/// background.
///
/// The avatar repeats beside every reply, as it does in Messenger: with a
/// header that collapses on scroll, a thread read halfway down otherwise has
/// nothing on screen saying who is talking.
Widget _assistantBubble(
  BuildContext context,
  Widget child, {
  Widget? avatar,
  bool local = false,
  bool showAvatar = true,
}) {
  final scheme = Theme.of(context).colorScheme;
  return Row(
    crossAxisAlignment: CrossAxisAlignment.end,
    mainAxisAlignment: MainAxisAlignment.start,
    children: [
      if (showAvatar)
        _AiPresenceAvatar(
          busy: false,
          local: local,
          avatar: avatar,
          size: 24,
          // The dot is the header's status line. Repeated down the thread it
          // would claim every past reply is live.
          showDot: false,
        )
      else
        // Same width as the avatar, so a run of replies keeps one left edge
        // instead of stepping out under the face.
        SizedBox(
          width: 24 * MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.3),
        ),
      const SizedBox(width: 8),
      Flexible(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHigh,
            border: Border.all(color: scheme.outlineVariant),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
              bottomLeft: Radius.circular(4),
              bottomRight: Radius.circular(16),
            ),
          ),
          child: child,
        ),
      ),
      // Keeps a short reply from stretching to the full width, the way the
      // user's own bubble is capped at 85%.
      const SizedBox(width: 40),
    ],
  );
}

class _TurnBubble extends StatelessWidget {
  const _TurnBubble({
    required this.turn,
    this.avatar,
    this.local = false,
    this.showAvatar = true,
    this.onEdit,
    this.onDelete,
    this.onCopy,
    this.editLabel = 'Edit',
    this.deleteLabel = 'Delete',
    this.copyLabel = 'Copy',
    this.copiedLabel = 'Copied',
    this.youLabel = 'You said',
    this.assistantLabel = 'Assistant said',
  });

  final AiChatTurn turn;

  /// The host's own assistant face, shown beside the reply. Null falls back
  /// to the default glyph.
  final Widget? avatar;
  final bool local;

  /// False on every reply but the last of a run, which leaves the gutter
  /// empty so the bubbles still line up under the one face above them.
  final bool showAvatar;

  /// Puts this turn back in the composer. Null for anything not editable.
  final VoidCallback? onEdit;

  /// Drops this turn (and everything after it) with no re-typing. Null for
  /// anything not deletable.
  final VoidCallback? onDelete;

  /// Puts this turn on the clipboard. Offered on every turn, including the
  /// assistant's -- an answer you cannot copy out is an answer you retype.
  final VoidCallback? onCopy;
  final String editLabel;
  final String deleteLabel;
  final String copyLabel;
  final String copiedLabel;

  /// Read out before the turn itself, so a screen reader says who is talking
  /// -- on screen that is the bubble's side and colour, which announces
  /// nothing.
  final String youLabel;
  final String assistantLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUser = turn.isUser;
    final meta = _meta(context);
    final scheme = theme.colorScheme;
    if (!isUser) {
      // A visible button rather than the bubble's long-press menu: the reply
      // is selectable text, and a long press there belongs to the selection.
      return Semantics(
        label: assistantLabel,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _assistantBubble(
              context,
              AiMarkdown(
                text: turn.content,
                copyCodeLabel: copyLabel,
                copiedLabel: copiedLabel,
              ),
              avatar: avatar,
              local: local,
              showAvatar: showAvatar,
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (meta != null) _metaText(theme, meta),
                if (onCopy != null)
                  IconButton(
                    onPressed: onCopy,
                    tooltip: copyLabel,
                    icon: const Icon(Icons.copy_outlined, size: 16),
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    constraints: const BoxConstraints(),
                    color: scheme.onSurfaceVariant,
                  ),
              ],
            ),
          ],
        ),
      );
    }
    final canAct = onEdit != null || onDelete != null || onCopy != null;
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Flexible(
          child: Semantics(
            label: youLabel,
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
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
        if (onCopy != null)
          PopupMenuItem(
            value: onCopy,
            child: ListTile(
              leading: const Icon(Icons.copy_outlined),
              title: Text(copyLabel),
              contentPadding: EdgeInsets.zero,
              dense: true,
            ),
          ),
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

/// The chat header's overflow menu entries.
enum _ChatMenuAction { find, copyAsMarkdown, copyAsJson }

/// A tool call waiting on the user's answer.
class _PendingConfirm {
  _PendingConfirm({required this.tool, required this.call, this.preview});

  final AiTool tool;
  final AiToolCall call;

  /// The row this call would change, if the tool could resolve one.
  final AiItem? preview;
  final answer = Completer<AiToolDecision>();
}

/// The cover photo a call carries, if it named one.
///
/// Tools that save something people look at -- a recipe, a jacket -- take an
/// image URL the model found with `image_search`. Showing it beats printing
/// the URL: the picture is most of what makes the proposal recognisable.
String? _previewImage(AiToolCall call) {
  for (final entry in call.args.entries) {
    final key = entry.key.toLowerCase();
    if (!key.contains('image') && !key.contains('photo')) continue;
    final value = entry.value;
    if (value is! String) continue;
    final url = Uri.tryParse(value.trim());
    if (url != null && (url.scheme == 'https' || url.scheme == 'http')) {
      return value.trim();
    }
  }
  return null;
}

/// The proposed change, asked in the thread in a proposal-shaped card.
class _ConfirmCard extends StatelessWidget {
  const _ConfirmCard({
    required this.pending,
    required this.onAccept,
    required this.onDecline,
    this.onEdit,
  });

  final _PendingConfirm pending;
  final VoidCallback onAccept;
  final VoidCallback onDecline;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: theme.colorScheme.primary, width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              aiToolTitle(pending.tool.name),
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            if (pending.tool.description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(pending.tool.description, style: theme.textTheme.bodySmall),
            ],
            if (_previewImage(pending.call) case final url?) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.network(
                    url,
                    fit: BoxFit.cover,
                    // A cover photo is decoration. A broken link must not take
                    // the card -- and the decision it is asking for -- with it.
                    errorBuilder: (_, _, _) => const SizedBox.shrink(),
                  ),
                ),
              ),
            ],
            if (pending.preview case final item?) ...[
              const SizedBox(height: 12),
              AiItemList(items: [item]),
            ] else ...[
              if (pending.call.args.isNotEmpty) const SizedBox(height: 12),
              for (final arg in pending.call.args.entries)
                // The photo is shown, so its URL is not worth a row too.
                if (arg.value != _previewImage(pending.call))
                  _ArgRow(name: arg.key, value: arg.value),
            ],
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: onDecline, child: const Text('Decline')),
                if (onEdit != null) ...[
                  const SizedBox(width: 4),
                  TextButton(onPressed: onEdit, child: const Text('Edit')),
                ],
                const SizedBox(width: 8),
                FilledButton(onPressed: onAccept, child: const Text('Accept')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// The assistant's avatar with a presence dot, Messenger-style.
///
/// The dot is the only place the header says whether a reply is being
/// generated once the subtitle has collapsed away, so it carries the busy
/// state rather than only decorating the row, and pulses while it does --
/// a still amber dot is indistinguishable from a colour choice.
class _AiPresenceAvatar extends StatefulWidget {
  const _AiPresenceAvatar({
    required this.busy,
    required this.local,
    this.avatar,
    this.size = 34,
    this.showDot = true,
  });

  /// Unscaled diameter. The real one tracks the platform text scale: at 200%
  /// text a fixed 34dp circle reads as a bullet point next to the name it
  /// belongs to. Capped at 1.3 -- past that the avatar starts pushing the
  /// title out of the row it is meant to label.
  final double size;

  final bool showDot;

  final bool busy;

  /// On-device generation gets its own glyph: the same conversation runs very
  /// differently on a phone model, and people ask which one answered. Ignored
  /// when the host passes an [avatar] of its own.
  final bool local;

  final Widget? avatar;

  @override
  State<_AiPresenceAvatar> createState() => _AiPresenceAvatarState();
}

class _AiPresenceAvatarState extends State<_AiPresenceAvatar>
    with SingleTickerProviderStateMixin {
  // Built here rather than as a lazy `late final`: an avatar that is neither
  // busy nor showing a dot touches _pulse for the first time in dispose(),
  // and creating a ticker against a deactivated element throws.
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    if (widget.busy) _pulse.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(_AiPresenceAvatar old) {
    super.didUpdateWidget(old);
    if (widget.busy == old.busy) return;
    if (widget.busy) {
      _pulse.repeat(reverse: true);
    } else {
      // Back to a solid dot rather than wherever the fade happened to stop.
      _pulse.stop();
      _pulse.value = 0;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final scale = MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.3);
    final box = widget.size * scale;
    final dot = box * 0.29;
    return SizedBox(
      width: box,
      height: box,
      child: Stack(
        children: [
          CircleAvatar(
            radius: box * 0.44,
            backgroundColor: scheme.primaryContainer,
            child: ClipOval(
              child:
                  widget.avatar ??
                  Icon(
                    widget.local ? Icons.offline_bolt : Icons.auto_awesome,
                    size: box * 0.47,
                    color: scheme.onPrimaryContainer,
                  ),
            ),
          ),
          if (widget.showDot)
            Positioned(
              right: 0,
              bottom: 0,
              child: FadeTransition(
                opacity: Tween<double>(begin: 1, end: 0.35).animate(_pulse),
                child: Container(
                  width: dot,
                  height: dot,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.busy
                        ? scheme.tertiary
                        : const Color(0xFF31A24C),
                    // The ring keeps the dot readable against a light avatar in
                    // either theme; without it the green sits on mint and reads
                    // as part of the icon.
                    border: Border.all(color: scheme.surface, width: 2),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
