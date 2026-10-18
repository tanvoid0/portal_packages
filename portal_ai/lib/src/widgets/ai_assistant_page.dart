import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

import '../chat/ai_attachment.dart';
import '../chat/ai_card.dart';
import '../chat/ai_chat_export.dart';
import '../chat/ai_chat_session.dart';
import '../chat/ai_error_message.dart';
import '../chat/ai_proposal.dart';
import '../chat/ai_voice_session.dart';
import '../chat/ai_suggestion.dart';
import '../clients/ai_completion_client.dart';
import '../documents/ai_document_client.dart';
import '../documents/ai_document_import.dart';
import '../platform/portal_ai_voice.dart';
import '../runtime/portal_ai_runtime.dart';
import '../tools/ai_agent.dart';
import '../tools/ai_tool.dart';
import 'ai_app_card.dart';
import 'ai_chat_history_list.dart';
import 'ai_chat_labels.dart';
import 'ai_history_panel.dart';
import 'ai_confirm_card.dart';
import 'ai_consent.dart';
import 'ai_suggestion_cards.dart';
import 'ai_voice_page.dart';
import 'ai_item_list.dart';
import 'ai_markdown.dart';
import 'ai_presence_orb.dart';
import '../runtime/ai_persona.dart';
import 'ai_prompt_composer.dart';
import 'ai_reply_foot.dart';
import 'ai_settings_section.dart';
import 'ai_step_tile.dart';
import 'ai_thinking_tile.dart';
import 'ai_turn_bubble.dart';

/// Drop-in assistant UI: prompt box, live step log and a confirmation prompt
/// before any tool that changes data.
///
/// ```dart
/// AiAssistantPage(runtime: Get.find<PortalAiRuntime>())
/// ```
///
/// Mount it at the app's own named `/ai` route (see `PortalAiSegment.ai`)
/// rather than pushing it as an unnamed route.
class AiAssistantPage extends StatefulWidget {
  const AiAssistantPage({
    super.key,
    this.runtime,
    this.title = 'Assistant',
    this.avatar,
    this.suggestions = const [],
    this.personas = const [],
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
    this.onOpenSettings,
    this.labels = const AiChatLabels(),
    this.fill = false,
    this.store,
    this.onItemTap,
    this.onEditToolCall,
    this.canEditToolCall,
    this.initialPrompt,
    this.autoSend = false,
    this.openVoice = false,
    this.resumeLastSession = false,
    this.initialSessionId,
    this.consent,
    this.onAttach,
    this.documents,
    this.maxPromptLength,
    this.onNewIncognito,
    this.quickAccess = const [],
    this.incognito = false,
    this.onLeaveIncognito,
    this.appMark,
    this.onOpenApp,
    this.onOpenCardRow,
    this.onAsk,
  }) : assert(
         runtime != null || onSend != null,
         'give the page a runtime to drive the agent, or an onSend that '
         'generates the reply itself',
       );

  /// Opens the voice conversation as soon as voice is known available, for
  /// a host launched into "talk now" context -- the Android system assist
  /// gesture lands here. No-op where the device has no on-device speech, which
  /// degrades to the plain text chat.
  final bool openVoice;

  /// Opens on the most recent stored thread instead of a blank deck.
  ///
  /// Off by default, and that default is right for the embedded assistant:
  /// you tap the sparkle in the gym app to ask something *now*, and being
  /// dropped back into last Tuesday's conversation would be an obstacle.
  ///
  /// A dedicated chat app is the other case entirely. There the thread is
  /// the document, and an app that throws it away every time you leave is
  /// an app you cannot use for anything that takes two sittings. Requires
  /// a [store]; ignored when [initialPrompt] is set, since an explicit
  /// question is the user asking for a new one.
  final bool resumeLastSession;

  /// Opens this stored thread (a host's history screen picks one) instead of
  /// the newest, so it wins over [resumeLastSession]. An id the [store] no
  /// longer holds opens a blank deck. An [initialPrompt] is then asked in
  /// that thread. Null leaves the other two as they were.
  final String? initialSessionId;

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

  /// The roles the user can pick between, shown as a chip row over the
  /// composer. Empty (every embedded app) draws no chips and routes nothing --
  /// the page runs the one agent exactly as before. Falls back to the
  /// runtime's own [PortalAiRuntime.personas] when the host passes none.
  final List<AiPersona> personas;

  /// Opens the app's own AI settings, when it has any. The model and key live
  /// on the server, so there is nothing to configure here by default.
  final VoidCallback? onSettings;

  /// Starts a fresh thread the host does not persist. Sits beside Settings in
  /// the history panel's footer, next to the navigation it is a sibling of
  /// rather than a third icon in the bar. No entry drawn when null -- a host
  /// with nothing ephemeral to offer gets no dead row.
  final VoidCallback? onNewIncognito;

  /// Extra destinations for the thread panel's quick-access row (New incognito
  /// chat, Scheduler, Plugins...). The host owns them because their routes are
  /// the host's; they render as the icon row above the thread list, the same
  /// row the Start screen's panel shows, so both open one sidebar.
  final List<AiChatQuickAccess> quickAccess;

  /// This thread is never kept: nothing is saved to the [store], no earlier
  /// thread is resumed, and the page says so with a frame round its edge and
  /// a chip over the composer. The host mounts it for a chat started from
  /// [onNewIncognito]; the turns still live in memory while the page does.
  final bool incognito;

  /// The incognito chip's dismiss, which leaves (and so discards) the chat.
  /// The host owns the route, so it also owns the "are you sure". No dismiss
  /// is drawn when null.
  final VoidCallback? onLeaveIncognito;

  /// The glyph of the app named by an [AiCard.app] / [AiAsk.app], or by a
  /// tool's namespace on the confirm card. A generic mark is drawn when this
  /// is null or answers null.
  final Widget? Function(String app)? appMark;

  /// Open on an app card, an ask's head or a receipt, with the app's name.
  /// No Open is drawn when null.
  final void Function(String app)? onOpenApp;

  /// An [AiCardRow] with an `openLabel` was tapped. Those rows are inert when
  /// null.
  final void Function(String app, AiCardRow row)? onOpenCardRow;

  /// The user answered an [AiAsk] block in the thread. The host owns what
  /// accepting means and pushes the ask back as saved or failed; a failed
  /// ask's Retry answers [AiAskAnswer.accept]. The ask's buttons are
  /// disabled when null.
  final void Function(AiAsk ask, AiAskAnswer answer)? onAsk;

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

  /// Opens the OS settings page when the microphone is denied. The package
  /// carries no permission plugin; the host supplies this. Null hides the
  /// button and the voice page tells the user to find Settings themselves.
  final VoidCallback? onOpenSettings;

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

  /// Which of the shown matches prev/next last scrolled to.
  int _matchIndex = 0;

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

  /// The reply as far as it got when the run failed, so the cut-off prose
  /// stays on screen above the failure instead of vanishing with the stream.
  /// Never a completed reply: [_latestReply] does not read it.
  String? _failedPartial;

  /// The last run failed offline before anything came back: the question is
  /// marked "Not sent" and no reply bubble is drawn.
  bool _notSent = false;

  /// The last send could not reach the backend. Drives the header's "Can't
  /// reach" until a send gets through.
  bool _lastSendOffline = false;

  /// The tool waiting on the user, drawn as a card at the end of the thread.
  _PendingConfirm? _pendingConfirm;

  /// The role the user pinned from the chip row. Null means Auto -- the
  /// router picks per message. Pinning skips the router (and its extra call).
  AiPersona? _activePersona;

  /// The personas to offer: the host's list, or the runtime's own.
  List<AiPersona> get _personas => widget.personas.isNotEmpty
      ? widget.personas
      : (widget.runtime?.personas ?? const []);

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
  /// Four on a full page, three in the sheet. Wrapped two-up, four
  /// suggestions plus the shuffle and more-ideas cards make three even rows;
  /// three would leave a single card stranded on the last one.
  late AiSuggestionRotator _rotator = _buildRotator(widget.suggestions);

  AiSuggestionRotator _buildRotator(List<AiSuggestion> pool) =>
      AiSuggestionRotator(pool: pool, visibleCount: widget.fill ? 4 : 3)
        ..refresh();

  /// The deck a persona shows: its own starter prompts when it has them, the
  /// app's default list otherwise (Auto, or a persona that ships none).
  List<AiSuggestion> get _deckPool =>
      (_activePersona?.suggestions.isNotEmpty ?? false)
      ? _activePersona!.suggestions
      : widget.suggestions;

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

  /// The opening screen, and the only place the deck is centred.
  ///
  /// [_showingDeck] already means nothing else has happened yet; this adds
  /// that the page owns the whole screen. In the embedded sheet the deck
  /// stays top-aligned, because there the sheet is sized to its content and
  /// centring it would only add empty space above.
  bool get _deckOnly => _showingDeck && widget.fill;

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

  /// Steps the search to the next (+1) or previous (-1) match, wrapping, and
  /// scrolls it into view without leaving the search.
  void _stepMatch(int delta) {
    final matches = _shownTurns;
    if (matches.isEmpty) return;
    setState(() => _matchIndex = (_matchIndex + delta) % matches.length);
    final turn = matches[_matchIndex];
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

  /// What the device can do without a server; [AiVoiceCapability.none]
  /// until the probe answers, so no microphone is drawn for a frame it then
  /// takes back.
  AiVoiceCapability _voice = AiVoiceCapability.none;

  /// The voice conversation, while one is open on its own page.
  AiVoiceSession? _voiceSession;
  bool get _voiceMode => _voiceSession?.active ?? false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_watchScroll);
    _reloadSessions();
    final initial = widget.initialPrompt?.trim();
    final hasInitial = initial != null && initial.isNotEmpty;
    final sessionId = widget.initialSessionId;
    if (widget.incognito) {
      // a fresh, unsaved thread: never open an earlier one
    } else if (sessionId != null) {
      _adoptSession(sessionId);
    } else if (widget.resumeLastSession && !hasInitial) {
      _resumeLastSession();
    }
    // After the resume: whether the deck shows at all depends on whether a
    // thread was restored, and the rotation timer only runs while it does.
    _syncRotation();
    unawaited(_probeVoice());
    if (!hasInitial) return;
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
    if (store == null || _turns.isEmpty || widget.incognito) return;
    final now = DateTime.now();
    final id = _sessionId ??= now.microsecondsSinceEpoch.toString();
    final existing = store.load(id);
    final first = _turns.first.content.trim();
    try {
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
    } catch (e) {
      // ponytail: chat history is best-effort local storage. The turn is
      // already on screen and in memory; only its survival across a reload is
      // lost. Swallow the save failure here so it can never be mistaken for a
      // *send* failure -- a persist throw used to fall into _send's catch,
      // which drew a false failure foot under a reply that actually arrived
      // and whose Retry then deleted that good turn. Upgrade: surface a
      // "couldn't save" chip if reload-loss ever needs to be visible.
      debugPrint('portal_ai: chat history save failed: $e');
      return;
    }
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
    if (!_adoptSession(id)) return;
    setState(() {});
  }

  /// Restores the newest thread during [initState].
  ///
  /// Separate from [_loadSession] because this runs before the first build,
  /// where there is no state to set -- the fields simply have to be right
  /// by the time [build] reads them.
  void _resumeLastSession() {
    if (_sessions.isEmpty) return;
    // Sorted by the store today, but the newest thread is the whole point of
    // this, so it is found rather than assumed. Pinning reorders the list
    // and must not decide which one reopens.
    var newest = _sessions.first;
    for (final session in _sessions.skip(1)) {
      if (session.updatedAt.isAfter(newest.updatedAt)) newest = session;
    }
    _adoptSession(newest.id);
  }

  /// Swaps the transcript over to [id]. False when the store has no such
  /// session, which leaves everything as it was.
  bool _adoptSession(String id) {
    final session = widget.store?.load(id);
    if (session == null) return false;
    _sessionId = session.id;
    _turns
      ..clear()
      ..addAll(session.turns);
    _steps.clear();
    _reply = null;
    _clearFailure();
    _lastSendOffline = false;
    return true;
  }

  void _newChat() {
    setState(() {
      _sessionId = null;
      _turns.clear();
      _steps.clear();
      _reply = null;
      _clearFailure();
      _lastSendOffline = false;
    });
  }

  /// Forgets the last failure, so a new run starts without its leftovers.
  void _clearFailure() {
    _error = null;
    _failedPartial = null;
    _notSent = false;
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

  /// A [Tooltip] only where the target is actually live.
  ///
  /// The title is the biggest tap target on the screen and it was unnamed;
  /// but it is also inert when there is no backend store to choose from,
  /// and a tooltip on a dead region announces an action that does not
  /// exist.
  Widget _wrapPicker(bool enabled, Widget child) => enabled
      ? Tooltip(message: widget.labels.changeModel, child: child)
      : child;

  Future<void> _showHistory() async {
    final store = widget.store;
    if (store == null) return;

    // On a full page the threads ARE the navigation, so they get the shape
    // navigation has: the shared leading-edge panel, floor to ceiling -- the
    // same one the Start screen opens, so the whole app has one sidebar.
    // Incognito and the host's own destinations ride the quick-access row;
    // settings sits in the footer, the way it does in every app with a drawer.
    if (widget.fill) {
      await showAiHistoryPanel(
        context: context,
        sessions: _sessions,
        selectedId: _sessionId,
        labels: widget.labels,
        subtitleFor: (s) => '${s.turnCount} ${widget.labels.messages}',
        quickAccess: (close) => [
          for (final q in widget.quickAccess)
            AiChatQuickAccess(
              icon: q.icon,
              label: q.label,
              onTap: () {
                close();
                q.onTap();
              },
            ),
        ],
        footer: widget.onSettings == null
            ? null
            : (close) => SafeArea(
                top: false,
                child: PortalListItem(
                  leading: PortalListLeading.icon(Icons.tune_rounded),
                  title: widget.labels.aiSettings,
                  onTap: () {
                    // Close first: settings pushes a route, and leaving the
                    // panel open behind it means coming back to a drawer
                    // nobody asked to reopen.
                    close();
                    widget.onSettings!();
                  },
                ),
              ),
        onSelect: (id) => id == null ? _newChat() : _loadSession(id),
        onRename: _renameSession,
        onSetPinned: _setPinned,
        onDelete: _deleteSession,
      );
      return;
    }

    // Embedded in another app's page: a centred dialog, not a drawer. The page
    // behind it belongs to that app, so a panel covering its leading edge would
    // read as that app's own drawer -- and this page does not own the Scaffold
    // to hang a real Drawer on anyway.
    final chosen = await showDialog<String>(
      context: context,
      builder: (dialogContext) => Dialog(
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
    _voiceSession?.dispose();
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

  Future<void> _probeVoice() async {
    final voice = await PortalAiVoice.describe();
    if (!mounted || !voice.isAvailable) return;
    setState(() => _voice = voice);
    // Launched into a "talk now" context (the system assist gesture): open the
    // voice page once we know the device can. Post-frame so the push sits on a
    // mounted route; _openVoice guards re-entry if the probe races a tap.
    if (widget.openVoice && !_voiceMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_openVoice());
      });
    }
  }

  /// Opens the voice conversation on its own page. Denied microphone is a
  /// decision, not an error: the field stays a text field.
  Future<void> _openVoice() async {
    if (_voiceMode) return;
    final session = _voiceSession ??= AiVoiceSession(
      ask: _voiceAsk,
      interrupt: _stop,
    );
    final started = await session.start();
    if (!mounted) return;
    if (!started) {
      // Denied is a decision: say so on the kit's mic-off page; the field
      // stays a text field behind it.
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          fullscreenDialog: true,
          builder: (_) => AiVoicePage(
            session: session,
            labels: widget.labels,
            micDenied: true,
            onOpenSettings: widget.onOpenSettings,
          ),
        ),
      );
      return;
    }
    setState(() {});
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => AiVoicePage(session: session, labels: widget.labels),
      ),
    );
    session.stop();
    if (mounted) setState(() {});
  }

  /// One spoken question through the ordinary send path. Resolves with the
  /// reply it produced, or null when nothing new came back.
  Future<String?> _voiceAsk(String text) async {
    if (_busy) _stop();
    _input.text = text;
    final before = _latestReply;
    await _send();
    if (!mounted) return null;
    final reply = _latestReply;
    if (reply == null || reply == before || _error != null || _cancelled) {
      return null;
    }
    return reply;
  }

  /// The newest assistant reply in whichever transcript this page shows.
  String? get _latestReply {
    if (_reply case final reply?) return reply;
    final last = _visibleTurns.lastOrNull;
    return last != null && last.isAssistant ? last.content : null;
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
      _clearFailure();
      _steps.clear();
      if (widget.onSend == null) _turns.removeRange(index, _turns.length);
    });
    if (widget.onSend != null) await widget.onRewind?.call(index);
  }

  Future<bool> _confirmRewind(int dropped) async {
    final labels = widget.labels;
    return portalConfirm(
      context,
      title: labels.rewindWarning.replaceAll('@count', '$dropped'),
      confirmLabel: labels.rewind,
      cancelLabel: labels.cancel,
    );
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
        _clearFailure();
      });
      try {
        await send(prompt);
        if (mounted && !_cancelled) {
          setState(() => _lastSendOffline = false);
          _followNewest();
        }
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
      _clearFailure();
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
    final runtime = widget.runtime!;
    try {
      // Auto (no pin) routes per message when there are personas to route
      // between; a pinned persona skips the router and its extra call.
      final persona =
          _activePersona ??
          (_personas.isEmpty
              ? null
              : await runtime.route(prompt, history: history));
      if (!mounted || _cancelled) return;
      final result = await runtime.ask(
        _withAttachment(prompt),
        // A persona with its own tools restricts the run to them; one with
        // none inherits the default set (which carries web search).
        tools: (persona != null && persona.tools.isNotEmpty)
            ? persona.tools
            : widget.tools,
        appDescription: persona?.description,
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
          _voiceSession?.onReplyDelta(delta);
          _followNewest(force: false);
        },
      );
      if (!mounted || _cancelled) return;
      if (!keeping) {
        setState(() {
          _reply = result.message;
          _replyThinking = result.thinking;
          _streamingReply = null;
          _lastSendOffline = false;
        });
        return;
      }
      setState(() {
        _lastSendOffline = false;
        _turns.add(
          AiChatTurn(
            role: 'assistant',
            content: result.message,
            at: DateTime.now(),
            took: clock.elapsed,
            payload: {
              if (persona != null) ...{
                'agent': persona.label,
                'agent_id': persona.id,
              },
              'blocks': [
                for (final step in _steps)
                  for (final block in step.blocks) block.toJson(),
              ],
              // What each step was, so a reload can still draw the receipts
              // ("Add item") once the live step lines are gone.
              if (_steps.isNotEmpty)
                'tools': [
                  for (final step in _steps)
                    {
                      'name': step.call.name,
                      'failed': step.failed,
                      'mutates': _mutates(step.call.name),
                    },
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
      final offline = isAiOfflineError(e);
      final partial = _streamingReply ?? '';
      final cutOff = partial.isNotEmpty || _steps.isNotEmpty;
      setState(() {
        _error = _messageFor(e);
        _lastSendOffline = offline;
        // Nothing came back and the network is why: the question never left,
        // so it carries the "Not sent" mark and there is no reply to draw. A
        // run that got somewhere first failed mid-flight instead, and keeps
        // what it had. No question on screen to mark (a one-shot with no
        // store) falls through to the reply's own failure line.
        _notSent = offline && !cutOff && _lastUserTurn != null;
        _failedPartial = partial.isEmpty ? null : partial;
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
        // Not in a voice conversation, where the next question is spoken.
        if (!_voiceMode) _inputFocus.requestFocus();
      }
    }
  }

  List<AiTool> get _tools =>
      widget.tools ?? widget.runtime?.tools ?? const <AiTool>[];

  /// Whether the tool called [name] changes data. False for one this page no
  /// longer has, which only costs a receipt.
  bool _mutates(String name) => resolveTool(_tools, name)?.mutates ?? false;

  /// Runs an [AiAction] button: same tools, same confirm prompt as a call the
  /// model makes. Nothing here goes back to the model -- the user asked for
  /// this action directly.
  Future<void> _runAction(AiAction action) async {
    if (_busy) return;
    final tool = resolveTool(_tools, action.tool);
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
    final note = result
        .substring(declined.length)
        .replaceFirst(RegExp(r'^ and asked instead: '), '');
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

  /// Names of the data-changing tools a restored turn ran and finished. Reads
  /// as defensively as [_blocksOf]: a thread saved before turns recorded
  /// `tools` has none, and an odd entry is skipped rather than thrown on.
  List<String> _receiptsOf(AiChatTurn turn) {
    final raw = turn.payload?['tools'];
    if (raw is! List) return const [];
    return [
      for (final entry in raw)
        if (entry is Map &&
            entry['name'] is String &&
            entry['mutates'] == true &&
            entry['failed'] != true)
          entry['name'] as String,
    ];
  }

  /// A line per change that went through, under the reply that reports it.
  List<Widget> _receipts(Iterable<String> names) {
    final gap = PortalUiTheme.of(context).tokens.spacing.sm;
    return [
      for (final name in names)
        Padding(
          padding: EdgeInsets.only(top: gap),
          child: AiReceipt(label: aiToolTitle(name)),
        ),
    ];
  }

  Widget _blockBody(AiBlock block, ThemeData theme) {
    final custom = widget.renderers[block.kind];
    if (custom != null) return custom(block);
    if (block.kind == AiBlock.cardKind) {
      final card = block.card;
      return AiAppCard(
        card: card,
        mark: widget.appMark?.call(card.app),
        onOpen: widget.onOpenApp == null
            ? null
            : () => widget.onOpenApp!(card.app),
        onOpenRow: widget.onOpenCardRow == null
            ? null
            : (row) => widget.onOpenCardRow!(card.app, row),
      );
    }
    if (block.kind == AiBlock.askKind) return _askView(block.ask);
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

  /// An [AiAsk] in the thread: the confirm card in its asked, kept or failed
  /// state, answered through [AiAssistantPage.onAsk].
  Widget _askView(AiAsk ask) {
    final answer = widget.onAsk;
    final labels = widget.labels;
    void reply(AiAskAnswer a) => answer?.call(ask, a);
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: ask.label ?? ask.title,
      child: AiConfirmCard(
        toolName: ask.title,
        args: ask.args,
        previewTitle: ask.title,
        coverImageUrl: ask.imageUrl,
        eyebrow: ask.eyebrow,
        mark: widget.appMark?.call(ask.app),
        onOpen: widget.onOpenApp == null
            ? null
            : () => widget.onOpenApp!(ask.app),
        rows: ask.rows,
        onOpenRow: widget.onOpenCardRow == null
            ? null
            : (row) => widget.onOpenCardRow!(ask.app, row),
        receipt: switch (ask.state) {
          AiAskState.saved => ask.receipt ?? const AiCardReceipt('Saved'),
          _ => null,
        },
        failure: switch (ask.state) {
          AiAskState.failed => ask.failure ?? "Couldn't save.",
          _ => null,
        },
        destructive: ask.destructive,
        onAccept: answer == null ? null : () => reply(AiAskAnswer.accept),
        onDecline: answer == null ? null : () => reply(AiAskAnswer.decline),
        onEdit: answer == null ? null : () => reply(AiAskAnswer.edit),
        declineLabel: labels.decline,
        editLabel: labels.edit,
        acceptLabel: ask.acceptLabel ?? labels.accept,
      ),
    );
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
              PortalButton(
                label: action.label,
                variant: PortalButtonVariant.outline,
                size: PortalButtonSize.sm,
                onPressed: _busy ? null : () => _runAction(action),
              ),
          ],
        ),
    ],
  );

  /// One completed tool call: what ran, plus whatever it had to show. A tool
  /// with no blocks of its own is told by its result text instead of its name;
  /// [AiStepLine] keeps that to two lines, since image_search returns a
  /// screenful of Unsplash URLs.
  Widget _stepView(AiAgentStep step, ThemeData theme) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      AiStepLine(
        icon: step.failed
            ? PortalIcons.error_rounded
            : PortalIcons.check_circle_rounded,
        iconColor: step.failed ? theme.colorScheme.error : null,
        text: step.blocks.isEmpty && step.result.trim().isNotEmpty
            ? _stepResultText(step.result)
            : aiToolTitle(step.call.name),
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
      _matchIndex = 0;
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
    setState(() {
      _error = _messageFor(error);
      _lastSendOffline = isAiOfflineError(error);
    });
    _followNewest();
  }

  String _messageFor(Object error) =>
      aiErrorMessage(error, offline: widget.labels.offline);

  void _copyText(String text) {
    Clipboard.setData(ClipboardData(text: text));
    HapticFeedback.selectionClick();
    ScaffoldMessenger.maybeOf(
      context,
    )?.showSnackBar(SnackBar(content: Text(widget.labels.copied)));
  }

  /// `09:14 - 4.2s - 3 steps`, skipping whatever this turn does not know.
  /// Threads saved before turns carried a time show nothing at all.
  String? _meta(AiChatTurn turn) {
    final parts = [
      if (turn.payload?['agent'] case final String agent when agent.isNotEmpty)
        agent,
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

  /// The assistant's mark for a reply foot: small, no presence dot -- the
  /// dot is the header's status line, and repeated down the thread it would
  /// claim every past reply is live.
  Widget get _footMark => _AiPresenceAvatar(
    busy: false,
    local: widget.runtime?.usesLocalModel ?? false,
    avatar: widget.avatar,
    size: 20,
    showDot: false,
  );

  /// The assistant's bubble around [child], with [footer] under it.
  Widget _replyBubble(Widget child, {Widget? footer}) => PortalChatBubble(
    author: PortalChatAuthor.assistant,
    footer: footer,
    child: child,
  );

  /// A reply's body: [text], and a receipt line under it for each change in
  /// [changes] that went through.
  Widget _replyBody(Widget text, List<String> changes) => changes.isEmpty
      ? text
      : Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [text, ..._receipts(changes)],
        );

  /// Whether [at] falls on a different calendar day from [previous].
  static bool _newDay(DateTime? previous, DateTime at) =>
      previous != null &&
      (previous.year != at.year ||
          previous.month != at.month ||
          previous.day != at.day);

  /// One transcript turn. The root carries the [GlobalObjectKey] that
  /// [_revealTurn] scrolls to.
  ///
  /// [notSent] marks the question whose send never left the device;
  /// [newest] is the last turn on screen, the only reply that can be redone;
  /// [canRedo] is whether the page can re-ask the last question at all.
  Widget _turnView(
    AiChatTurn turn, {
    required bool notSent,
    required bool newest,
    required bool canRedo,
  }) {
    final labels = widget.labels;
    final Widget content;
    if (turn.isUser) {
      content = Semantics(
        label: labels.youSaid,
        child: AiUserTurn(
          turn: turn,
          notSent: notSent,
          onRetry: _busy ? null : _retry,
          // Actions live behind a long-press, like every other chat bubble on
          // the platform. Any question can be reworked, not just the newest:
          // the mistake worth fixing is often three turns back. Going back
          // drops the answers after it, so _rewindTo asks before throwing
          // away more than the last exchange.
          onCopy: () => _copyText(turn.content),
          onEdit: !_busy && _canRewind(turn)
              ? () => _rewindTo(_visibleTurns.indexOf(turn))
              : null,
          onDelete: !_busy && _canRewind(turn)
              ? () => _rewindTo(_visibleTurns.indexOf(turn), refill: false)
              : null,
          copy: labels.copy,
          edit: labels.edit,
          delete: labels.delete,
          notSentLabel: labels.notSent,
          retry: labels.retry,
        ),
      );
    } else {
      // The foot's copy button rather than the bubble's long-press menu: the
      // reply is selectable text, and a long press there belongs to the
      // selection.
      content = Semantics(
        label: labels.assistantSaid,
        child: _replyBubble(
          _replyBody(
            AiMarkdown(
              text: turn.content,
              copyCodeLabel: labels.copy,
              copiedLabel: labels.copied,
            ),
            _receiptsOf(turn),
          ),
          footer: _doneFoot(
            meta: _meta(turn),
            onCopy: () => _copyText(turn.content),
            onRegenerate: newest && canRedo && !_busy ? _retry : null,
          ),
        ),
      );
    }
    return Padding(
      key: GlobalObjectKey(turn),
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: _chatQuery.trim().isEmpty ? null : () => _revealTurn(turn),
        child: content,
      ),
    );
  }

  /// The foot of a reply that is still coming: writing, or waiting on the
  /// user's answer to a proposed change.
  AiReplyFoot _liveFoot() {
    final labels = widget.labels;
    return AiReplyFoot(
      mark: _footMark,
      status: _pendingConfirm == null
          ? AiReplyStatus.writing
          : AiReplyStatus.waiting,
      writing: labels.writing,
      waitingForYou: labels.waitingForYou,
    );
  }

  /// The foot of a reply that never arrived (or stopped short): the reason,
  /// and a way to ask again where there is a question to ask.
  AiReplyFoot _failedFoot() => AiReplyFoot(
    status: AiReplyStatus.failed,
    failure: _error,
    onRetry: _lastUserTurn != null && !_busy ? _retry : null,
    retry: widget.labels.retry,
  );

  /// The match counter with prev/next, shown once there is a query.
  Widget? _searchTrailing() {
    final query = _chatQuery.trim();
    if (query.isEmpty) return null;
    final labels = widget.labels;
    final total = _shownTurns.length;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          total == 0
              ? labels.searchNoMatches
              : labels.searchMatches
                    .replaceAll('@current', '${_matchIndex + 1}')
                    .replaceAll('@total', '$total'),
          style: PortalUiTheme.of(context).tokens.textStyles.caption,
        ),
        PortalButton.icon(
          tooltip: labels.searchPrevious,
          icon: PortalIcons.keyboard_arrow_up_rounded,
          variant: PortalButtonVariant.ghost,
          size: PortalButtonSize.sm,
          onPressed: total == 0 ? null : () => _stepMatch(-1),
        ),
        PortalButton.icon(
          tooltip: labels.searchNext,
          icon: PortalIcons.keyboard_arrow_down_rounded,
          variant: PortalButtonVariant.ghost,
          size: PortalButtonSize.sm,
          onPressed: total == 0 ? null : () => _stepMatch(1),
        ),
      ],
    );
  }

  /// A finished reply's foot: copy, and regenerate where redoing it makes
  /// sense. [meta] is the caption (time, how long, steps, model).
  AiReplyFoot _doneFoot({
    required VoidCallback onCopy,
    VoidCallback? onRegenerate,
    String? meta,
  }) {
    final labels = widget.labels;
    return AiReplyFoot(
      mark: _footMark,
      status: AiReplyStatus.done,
      meta: meta,
      onCopy: onCopy,
      onRegenerate: onRegenerate,
      copyReply: labels.copyReply,
      regenerate: labels.regenerate,
    );
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
      // Three ways out, because this sheet had none.
      //
      // `isScrollControlled` plus a child taller than the screen means the
      // sheet fills the viewport: there is no scrim left to tap, and with
      // no handle and no close button the only exit was the Android back
      // button -- which is not an exit at all on iOS, and is not something
      // a screen-reader user is told about anywhere.
      //
      // So: a drag handle, a named close button, and a cap on the height
      // that keeps a strip of scrim reachable above it.
      showDragHandle: true,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.9,
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.labels.aiProvider,
                      style: Theme.of(sheetContext).textTheme.titleMedium,
                    ),
                  ),
                  PortalButton.icon(
                    tooltip: MaterialLocalizations.of(
                      sheetContext,
                    ).closeButtonTooltip,
                    icon: Icons.close_rounded,
                    variant: PortalButtonVariant.ghost,
                    onPressed: () => Navigator.of(sheetContext).pop(),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: AiSettingsSection(
                  store: store,
                  onChanged: (option) {
                    runtime.applyBackend(option);
                    if (mounted) setState(() {});
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) => widget.incognito
      ? Stack(
          fit: widget.fill ? StackFit.expand : StackFit.loose,
          children: [_buildPage(context), _incognitoFrame(context)],
        )
      : _buildPage(context);

  /// A thin ring in the inverse-surface tone with a soft glow, round the
  /// page's edge: charcoal in light, pale in dark, never the brand accent.
  /// Pointer-transparent so it never steals a tap.
  Widget _incognitoFrame(BuildContext context) {
    final t = PortalUiTheme.of(context).tokens;
    final tone = Theme.of(context).colorScheme.inverseSurface;
    final radius = BorderRadius.circular(t.radii.lg);
    // A blurred thick stroke reads as a glow at the edge; a blurred filled
    // box would tint the whole page.
    return Positioned.fill(
      child: IgnorePointer(
        child: SafeArea(
          child: Stack(
            fit: StackFit.expand,
            children: [
              ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: tone.withValues(alpha: .25),
                      width: 12,
                    ),
                    borderRadius: radius,
                  ),
                ),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: tone.withValues(alpha: .6),
                    width: 2,
                  ),
                  borderRadius: radius,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Over the composer: says nothing here is kept; dismiss leaves.
  Widget _incognitoChip() {
    final t = PortalUiTheme.of(context).tokens;
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(bottom: t.spacing.xs),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: cs.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(t.radii.full),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: EdgeInsetsDirectional.only(
                  start: t.spacing.md,
                  end: widget.onLeaveIncognito == null ? t.spacing.md : 0,
                ),
                child: Semantics(
                  container: true,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    spacing: t.spacing.sm,
                    children: [
                      Icon(
                        Icons.masks_rounded,
                        size: 18,
                        color: cs.onSurfaceVariant,
                      ),
                      Text(
                        widget.labels.incognitoChip,
                        style: t.textStyles.body.copyWith(color: cs.onSurface),
                      ),
                    ],
                  ),
                ),
              ),
              if (widget.onLeaveIncognito != null)
                PortalButton.icon(
                  icon: PortalIcons.close_rounded,
                  tooltip: widget.labels.leaveIncognito,
                  onPressed: widget.onLeaveIncognito,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPage(BuildContext context) {
    final theme = Theme.of(context);
    final canPickBackend = widget.runtime?.backendStore != null;
    final shown = _shownTurns;
    final lastUser = _lastUserTurn;
    final streaming = _streamingReply?.isNotEmpty ?? false;
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
                // The threads live off the leading edge, so the affordance
                // for them does too. It used to be a clock icon sitting in a
                // rank of three on the right, which said "one more tool"
                // when what it opens is the app's navigation.
                //
                // Full page only. In the embedded sheet the panel is a
                // centred dialog, not a drawer, and a hamburger there would
                // promise a drawer over the host app's own screen.
                if (widget.fill && widget.store != null)
                  IconButton(
                    tooltip: widget.labels.historyTitle,
                    icon: const Icon(Icons.menu_rounded),
                    iconSize: 22,
                    visualDensity: VisualDensity.compact,
                    onPressed: _showHistory,
                  ),
                Expanded(
                  // Messenger-style stacked title: the name on one tight line
                  // with the backend underneath it, instead of a title row
                  // fighting an ActionChip for horizontal space.
                  //
                  // The face lives INSIDE this tap target rather than beside
                  // it. Outside, it was an unlabelled circle that looked
                  // pressable and was not, sitting in a leading run that now
                  // also carries a back button and a hamburger. Inside, the
                  // face, the name and the backend are one named control
                  // that does the obvious thing: change the model.
                  child: _wrapPicker(
                    canPickBackend,
                    InkWell(
                      onTap: canPickBackend ? _showBackendPicker : null,
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            _AiPresenceAvatar(
                              busy: _busy,
                              local: widget.runtime?.usesLocalModel ?? false,
                              avatar: widget.avatar,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
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
                                      duration: const Duration(
                                        milliseconds: 150,
                                      ),
                                      firstChild: const SizedBox(
                                        height: 0,
                                        width: double.infinity,
                                      ),
                                      secondChild: Text(
                                        _busy
                                            ? widget.labels.thinking
                                            : _lastSendOffline
                                            ? widget.labels.cantReach
                                            : widget.runtime!.backendLabel,
                                        style: theme.textTheme.labelSmall
                                            ?.copyWith(
                                              color: _lastSendOffline && !_busy
                                                  ? theme.colorScheme.error
                                                  : theme
                                                        .colorScheme
                                                        .onSurfaceVariant,
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
                          ],
                        ),
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
                    // No tooltip override: this menu holds find and two
                    // copy formats, and calling it "Share" named it after
                    // something it does not do. MaterialLocalizations'
                    // "Show menu" is both correct and translated.
                    icon: const Icon(Icons.more_vert_rounded),
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
                  // Only where there is no hamburger to open it from.
                  if (!widget.fill)
                    IconButton(
                      tooltip: widget.labels.historyTitle,
                      icon: const Icon(Icons.history_rounded),
                      iconSize: 20,
                      visualDensity: VisualDensity.compact,
                      onPressed: _showHistory,
                    ),
                  // New chat stays on the right, in every mode. It is not
                  // navigation -- it makes the thing you are looking at --
                  // and burying the one action people take most often
                  // behind a panel is how a chat app feels slow.
                  IconButton(
                    tooltip: widget.labels.newChat,
                    icon: const Icon(Icons.add_comment_rounded),
                    iconSize: 20,
                    visualDensity: VisualDensity.compact,
                    onPressed: _newChat,
                  ),
                ],
                // Configuration is not a peer of "new chat". On a full page
                // it moves into the panel's footer; in the sheet there is no
                // panel footer to move it to, so it stays.
                // A fill host with settings but NO store has no panel to
                // put them in -- _showHistory returns early without a store,
                // so the hamburger never opens and the footer never renders.
                // Gating the gear on !fill alone stranded those hosts with
                // no route to settings at all.
                if (widget.onSettings != null &&
                    (!widget.fill || widget.store == null))
                  IconButton(
                    tooltip: widget.labels.aiSettings,
                    icon: const Icon(Icons.tune_rounded),
                    iconSize: 20,
                    visualDensity: VisualDensity.compact,
                    onPressed: widget.onSettings,
                  ),
              ],
            ),
            if (_searching)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: PortalSearchField(
                  focusNode: _searchFocus,
                  hintText: widget.labels.searchInChatHint,
                  onChanged: (value) => setState(() {
                    _chatQuery = value;
                    _matchIndex = 0;
                  }),
                  trailing: _searchTrailing(),
                ),
              ),
            const SizedBox(height: 8),
          ],
          Flexible(
            fit: widget.fill ? FlexFit.tight : FlexFit.loose,
            // The opening screen is centred, not top-aligned. A full-height
            // page with a greeting and four cards pinned under the header
            // leaves two thirds of the screen empty and reads as a list that
            // failed to load. Giving the scroll view a minimum of one
            // viewport lets the deck sit in the middle of it; the moment
            // there is a transcript the alignment goes back to the top, so
            // nothing jumps once the conversation starts.
            child: LayoutBuilder(
              builder: (context, constraints) => Stack(
                children: [
                  SingleChildScrollView(
                    controller: _scroll,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: widget.fill && constraints.maxHeight.isFinite
                            ? constraints.maxHeight
                            : 0,
                      ),
                      child: Column(
                        mainAxisAlignment: _deckOnly
                            ? MainAxisAlignment.center
                            : MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (_showingDeck) ...[
                            if (widget.consent case final consent?
                                when !consent.accepted)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                child: AiConsentCard(consent: consent),
                              )
                            else if (widget.incognito ||
                widget.labels.empty.isNotEmpty) ...[
                              // The mark, once, above the greeting -- the one
                              // place in the app the assistant has a face large
                              // enough to be a face. It is not repeated down the
                              // transcript at this size.
                              if (_deckOnly)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 20),
                                  child: Center(
                                    child: _AiPresenceAvatar(
                                      busy: false,
                                      local:
                                          widget.runtime?.usesLocalModel ??
                                          false,
                                      avatar: widget.avatar,
                                      size: 96,
                                      showDot: false,
                                    ),
                                  ),
                                ),
                              Padding(
                                padding: EdgeInsets.only(
                                  top: _deckOnly ? 0 : 24,
                                  bottom: _deckOnly ? 28 : 24,
                                ),
                                child: Text(
                                  widget.incognito
                                      ? widget.labels.incognitoEmpty
                                      : widget.labels.empty,
                                  textAlign: TextAlign.center,
                                  // A greeting, not body copy: at the centre of
                                  // an otherwise empty screen bodyMedium reads as
                                  // a caption that lost its content.
                                  style: _deckOnly
                                      ? theme.textTheme.headlineSmall
                                      : theme.textTheme.bodyMedium,
                                ),
                              ),
                            ],
                            const SizedBox(height: 8),
                            AiSuggestionCards(
                              suggestions: _rotator.visible,
                              // Wrapped only on the opening screen; above a
                              // transcript the strip is the right shape.
                              wrap: _deckOnly,
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
                          for (final (index, turn) in shown.indexed) ...[
                            if (turn.at case final at?
                                when index > 0 &&
                                    _newDay(shown[index - 1].at, at))
                              AiDayStamp(label: aiDayStamp(context, at)),
                            if (_thinkingOf(turn) case final thinking?)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: AiThinkingTile(
                                  thinking: thinking,
                                  label: widget.labels.thinking,
                                ),
                              ),
                            _turnView(
                              turn,
                              notSent: _notSent && identical(turn, lastUser),
                              newest:
                                  index == shown.length - 1 &&
                                  _chatQuery.trim().isEmpty,
                              canRedo: lastUser != null,
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
                              child: _replyBubble(
                                AiMarkdown(text: partial),
                                footer: _busy ? _liveFoot() : null,
                              ),
                            ),
                          if (_replyThinking case final thinking?)
                            AiThinkingTile(
                              thinking: thinking,
                              label: widget.labels.thinking,
                            ),
                          if (_reply case final reply?)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: _replyBubble(
                                _replyBody(AiMarkdown(text: reply), [
                                  for (final step in _steps)
                                    if (!step.failed &&
                                        _mutates(step.call.name))
                                      step.call.name,
                                ]),
                                footer: _busy
                                    ? null
                                    : _doneFoot(onCopy: () => _copyText(reply)),
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
                              child: AiConfirmCard(
                                toolName: pending.tool.name,
                                // The row the call would change speaks for the
                                // argument dump that held its id; the photo is
                                // still the call's own.
                                args: pending.preview == null
                                    ? pending.call.args
                                    : const {},
                                coverImageUrl: aiPreviewImage(
                                  pending.call.args,
                                ),
                                previewTitle: pending.preview?.title,
                                mark: pending.tool.namespace == null
                                    ? null
                                    : widget.appMark?.call(
                                        pending.tool.namespace!,
                                      ),
                                onAccept: () => _answerConfirm(true),
                                onDecline: () => _answerConfirm(false),
                                onEdit: _canEdit(pending.call)
                                    ? () => _editPending(pending)
                                    : null,
                                declineLabel: widget.labels.decline,
                                editLabel: widget.labels.edit,
                                acceptLabel: widget.labels.accept,
                              ),
                            ),
                          // Nothing to hang the state on yet -- no text, or a
                          // card waiting -- so it stands on its own.
                          if (_busy && !streaming) _liveFoot(),
                          // A failure is part of the conversation, so it reads as
                          // one: under whatever the reply managed to say, with the
                          // reason and a way to ask again. A question that never
                          // left says so under itself instead.
                          if (_error != null && !_notSent)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: switch (_failedPartial) {
                                final partial? => _replyBubble(
                                  AiMarkdown(text: partial),
                                  footer: _failedFoot(),
                                ),
                                null => _failedFoot(),
                              },
                            ),
                        ],
                      ),
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
                        child: const Icon(Icons.arrow_downward_rounded),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (_proposals.isNotEmpty && widget.onAcceptProposal != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: PortalButton(
                onPressed: _acceptAll,
                leading: const Icon(Icons.playlist_add),
                label: '${widget.labels.addAll} (${_proposals.length})',
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
          if (_personas.isNotEmpty) _personaBar(),
          if (widget.incognito) _incognitoChip(),
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
            onMic: _voice.isAvailable ? _openVoice : null,
            listening: _voiceMode,
            stopLabel: widget.labels.stop,
            attachLabel: widget.labels.attach,
            micLabel: widget.labels.speak,
            micStopLabel: widget.labels.stopListening,
            hintText: _gated
                ? widget.labels.consentBlocked
                : (_busy && _pendingConfirm == null)
                ? widget.labels.working
                : _pendingConfirm != null
                ? widget.labels.typeAChange
                : widget.labels.inputHint,
          ),
        ],
      ),
    );
  }

  /// The role picker: Auto (the router decides per message) plus one chip per
  /// persona. Selecting a persona pins it for the thread; Auto clears the pin.
  /// One mutually-exclusive group, so a screen reader hears it as a choice.
  Widget _personaBar() {
    final selectedId = _activePersona?.id;
    final portal = PortalUiTheme.of(context);
    return PortalFilterChipRow(
      semanticLabel: widget.labels.assistantRole,
      children: [
        PortalFilterChip(
          label: widget.labels.autoRole,
          selected: selectedId == null,
          exclusive: true,
          onTap: () => _pickPersona(null),
        ),
        for (final persona in _personas)
          PortalFilterChip(
            label: persona.label,
            selected: selectedId == persona.id,
            exclusive: true,
            // Tint the mark to the chip's own ink so it flips with selection
            // like a themed Icon would.
            leading: persona.icon == null
                ? null
                : PortalGlyph(
                    persona.icon!,
                    size: 18,
                    tintColor: selectedId == persona.id
                        ? portal.onPrimary
                        : portal.onSurfaceVariant,
                  ),
            onTap: () => _pickPersona(persona),
          ),
      ],
    );
  }

  /// Pins [persona] (null = Auto) and swaps the opening deck to its starter
  /// prompts. The deck only shows before the first message, but rebuilding it
  /// off-screen is cheap and keeps the two in step.
  void _pickPersona(AiPersona? persona) {
    setState(() {
      _activePersona = persona;
      _rotator = _buildRotator(_deckPool);
    });
    _syncRotation();
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
                      PortalButton(
                        onPressed: onAccept,
                        variant: PortalButtonVariant.ghost,
                        size: PortalButtonSize.sm,
                        leading: const Icon(Icons.add, size: 18),
                        label: labels.add,
                      ),
                    if (onEdit != null)
                      PortalButton(
                        onPressed: onEdit,
                        variant: PortalButtonVariant.ghost,
                        size: PortalButtonSize.sm,
                        leading: const Icon(Icons.edit_outlined, size: 18),
                        label: labels.edit,
                      ),
                    if (onDiscard != null)
                      PortalButton(
                        onPressed: onDiscard,
                        variant: PortalButtonVariant.ghost,
                        size: PortalButtonSize.sm,
                        leading: const Icon(Icons.close, size: 18),
                        label: labels.discard,
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
          // The default face is the orb, not a glyph. A flat sparkle is a
          // logo; a drifting gradient reads as something that is running,
          // which is what this widget is actually reporting. A host that
          // passes its own [avatar] still wins -- portal_gym wants its own
          // mark, not a generic presence.
          if (widget.avatar case final avatar?)
            CircleAvatar(
              radius: box * 0.44,
              backgroundColor: scheme.primaryContainer,
              child: ClipOval(child: avatar),
            )
          else if (widget.local)
            // On-device: a fixed glyph rather than the orb, so "this is
            // running on your phone" is legible at a glance instead of
            // being one more thing the orb could mean.
            CircleAvatar(
              radius: box * 0.44,
              backgroundColor: scheme.primaryContainer,
              child: Icon(
                Icons.offline_bolt,
                size: box * 0.47,
                color: scheme.onPrimaryContainer,
              ),
            )
          else
            Center(
              child: AiPresenceOrb(size: box * 0.88, busy: widget.busy),
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
                        : PortalSemanticColors.of(context).success,
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
