import '../chat/ai_chat_session.dart';
import '../clients/ai_completion_client.dart';
import '../clients/ai_completion_client_factory.dart';
import '../clients/fallback_completion_client.dart';
import '../clients/ollama_completion_client.dart';
import '../clients/openai_compatible_completion_client.dart';
import '../clients/server_completion_client.dart';
import '../models/ai_backend_kind.dart';
import '../models/ai_dev_env_keys.dart';
import '../models/ai_routing_mode.dart';
import '../models/ai_sampler_config.dart';
import '../models/ai_backend_option.dart';
import '../prefs/ai_backend_store.dart';
import '../tools/ai_agent.dart';
import '../tools/ai_tool.dart';
import '../tools/web_search_tool.dart';

/// One-call AI wiring for a Portal app: completion client plus the
/// tool-calling agent.
///
/// Production runs through the Portal server, which holds the Gemini key,
/// chooses the model and enforces the per-user quota — no API key is ever
/// bundled into an app. Setting [AiDevEnvKeys.ollamaModel] in the app's `.env`
/// swaps in a local Ollama model instead, so development and testing cost
/// nothing.
///
/// ```dart
/// final ai = PortalAiRuntime.create(
///   post: Get.find<ApiClient>().post,
///   env: dotenv.env,
///   feature: 'gym-assistant',
///   appDescription: 'Portal Gym - workouts, routines and exercise logs.',
///   tools: gymAiTools(),
/// );
/// Get.put(ai, permanent: true);
/// ```
class PortalAiRuntime {
  PortalAiRuntime({
    required AiCompletionClient client,
    this.appDescription = '',
    this.tools = const [],
    this._store,
    this._clientFactory,
    this._serverClient,
    Map<String, String> env = const {},
    String? configurationHint,
    // ignore: prefer_initializing_formals
  }) : _client = client,
       // ignore: prefer_initializing_formals
       _env = env,
       // ignore: prefer_initializing_formals
       _configurationHint = configurationHint;

  /// Builds the runtime from app config.
  ///
  /// [post] is the app's authenticated JSON POST (`ApiClient.post`). It may be
  /// omitted only by apps with no Portal server session, which must then set
  /// [AiDevEnvKeys.ollamaModel].
  /// [postStream] is the same app's streaming POST (`ApiClient.postStream`).
  /// Without it the server answers in one piece, as it always did; with it
  /// the assistant renders the reply as the model writes it.
  factory PortalAiRuntime.create({
    AiPostJson? post,
    AiPostStream? postStream,
    Map<String, String> env = const {},
    String feature = 'assistant',
    String appDescription = '',
    List<AiTool> tools = const [],
    AiBackendStore? store,
    AiCompletionClientFactory? clientFactory,
  }) {
    final server = post == null
        ? null
        : ServerCompletionClient(
            post: post,
            postStream: postStream,
            feature: feature,
          );
    final factory = clientFactory ?? AiCompletionClientFactory();

    AiCompletionClient? client;
    String? hint;

    // A dev override in .env still wins, so a checkout can be pointed at a
    // local model without touching anyone's saved settings.
    final ollamaModel = env[AiDevEnvKeys.ollamaModel]?.trim();
    if (ollamaModel != null && ollamaModel.isNotEmpty) {
      client = OllamaCompletionClient(
        baseUrl: env[AiDevEnvKeys.ollamaHost]?.trim().isNotEmpty ?? false
            ? env[AiDevEnvKeys.ollamaHost]!.trim()
            : defaultOllamaBaseUrl,
        model: ollamaModel,
      );
    } else {
      final resolved = _clientForStored(store, factory, server, env);
      client = resolved.client;
      hint = resolved.hint;
    }

    // Only genuinely nothing to build reaches here -- routing degrades to
    // the server with a hint (see `_clientForStored`) rather than a null
    // client, precisely so a bad stored choice never throws out of `create`,
    // which apps call unguarded at boot.
    if (client == null) {
      throw ArgumentError(
        'PortalAiRuntime needs either a server transport, an AI backend '
        'selected in settings, or ${AiDevEnvKeys.ollamaModel} in .env.',
      );
    }

    // Search is offered to every app, or to none: an app does not ask for it,
    // it is there when a key is configured. Absent key means the model keeps
    // answering from what it knows, which is the behaviour without this tool.
    final searchKey = env[AiSearchEnvKeys.tavilyKey]?.trim();

    return PortalAiRuntime(
      client: client,
      appDescription: appDescription,
      tools: [
        ...tools,
        if (searchKey != null && searchKey.isNotEmpty)
          webSearchTool(apiKey: searchKey),
      ],
      store: store,
      clientFactory: factory,
      serverClient: server,
      env: env,
      configurationHint: hint,
    );
  }

  /// The client for whatever the user picked in AI settings, weighed against
  /// [AiBackendStore.routingMode]. Cloud stays on the server transport
  /// whenever there is one: the server holds the key, the model choice and
  /// the quota, and it is what "no local backend chosen" means below.
  static ({AiCompletionClient? client, String? hint}) _clientForStored(
    AiBackendStore? store,
    AiCompletionClientFactory factory,
    ServerCompletionClient? server,
    Map<String, String> env,
  ) {
    final kind = store?.selectedKind;
    if (store == null || kind == null || kind == AiBackendKind.cloudGemini) {
      return (client: server, hint: null);
    }

    AiCompletionClient? local;
    try {
      local = factory.create(kind: kind, store: store, env: env);
    } on AiCompletionException {
      // Selected but not usable yet (no Ollama model picked, Edge Gallery
      // chosen as a delegate, OpenAI-compatible with no base URL).
      local = null;
    }

    if (server == null) {
      // No server transport: the stored backend or nothing, same as before
      // routing existed -- there is nothing to route between.
      return (client: local, hint: null);
    }

    return switch (store.routingMode) {
      AiRoutingMode.serverOnly => (client: server, hint: null),
      // A server exists, so "nothing to build" is never true here even when
      // local-only has nothing usable -- degrade to the server (carrying a
      // hint the settings row / first reply can show) rather than throwing
      // out of `create()`. That throw is reachable from prefs sync landing
      // an unbuildable choice (e.g. `openai_compatible` with no base URL)
      // made on another device, which the app never gets a chance to guard.
      AiRoutingMode.localOnly => local == null
          ? (
              client: server,
              hint:
                  'AI routing is set to local-only but no local backend is '
                  'configured, so the server is answering instead. Pick a '
                  'backend in AI settings, or switch routing to include the '
                  'server.',
            )
          : (client: local, hint: null),
      // A local backend not being usable yet is not an error here -- the
      // server is a working assistant on its own, same as before fallback
      // routing existed.
      AiRoutingMode.serverFirst => local == null
          ? (client: server, hint: null)
          : (
              client: FallbackCompletionClient(primary: server, fallback: local),
              hint: null,
            ),
    };
  }

  AiCompletionClient _client;
  final AiBackendStore? _store;
  final AiCompletionClientFactory? _clientFactory;
  final ServerCompletionClient? _serverClient;
  final Map<String, String> _env;
  String? _configurationHint;

  /// The client the assistant is talking to right now.
  AiCompletionClient get client => _client;

  /// Set when [_clientForStored] had to degrade rather than build exactly
  /// what routing asked for -- today, only local-only with no usable local
  /// backend, which answers on the server instead. Null the rest of the
  /// time. A settings row or the first reply can surface this; nothing here
  /// shows it on its own.
  String? get configurationHint => _configurationHint;

  /// Where the provider and model choice is kept, for a UI that wants to
  /// offer the switch itself. Null for a runtime built without one, which is
  /// every app that only ever talks to the server.
  AiBackendStore? get backendStore => _store;

  /// The provider actually answering right now.
  ///
  /// Not the same as the stored choice. [_clientForStored] and [applyBackend]
  /// both keep the server when the selected provider will not build — Edge
  /// Gallery picked as a delegate, Ollama with no model — so a badge read off
  /// the stored kind names a provider that never runs, and disagrees with the
  /// assistant row in Settings, which reports what answered.
  AiBackendKind get activeBackendKind {
    final client = _client;
    if (client is FallbackCompletionClient) {
      return _kindOfClient(
        client.lastAnsweredBy == AiAnsweredBy.fallback
            ? client.fallback
            : client.primary,
      );
    }
    return _kindOfClient(client);
  }

  AiBackendKind _kindOfClient(AiCompletionClient client) {
    if (client is ServerCompletionClient) return AiBackendKind.cloudGemini;
    if (client is OllamaCompletionClient) return AiBackendKind.ollama;
    if (client is OpenAiCompatibleCompletionClient) {
      return AiBackendKind.openAiCompatible;
    }
    return _store?.selectedKind ?? AiBackendKind.cloudGemini;
  }

  /// What to call the model in a one-line badge: the chosen model's own name
  /// where there is one, the provider otherwise.
  String get backendLabel {
    final store = _store;
    final kind = activeBackendKind;
    final model = store?.modelFor(kind);
    if (model != null && model.isNotEmpty) return model;
    return switch (kind) {
      AiBackendKind.cloudGemini => 'Cloud',
      AiBackendKind.ollama => 'Ollama',
      AiBackendKind.systemOnDevice => 'On-device',
      AiBackendKind.edgeGalleryDelegate => 'Edge Gallery',
      AiBackendKind.openAiCompatible => 'OpenAI-compatible',
    };
  }

  /// True when generation happens on this device or another machine rather
  /// than the Portal server -- including a [FallbackCompletionClient] whose
  /// most recent call actually landed on its local side.
  bool get usesLocalModel => activeBackendKind != AiBackendKind.cloudGemini;

  /// Re-points the assistant after the user changes provider in settings, so
  /// the change takes effect without an app restart.
  ///
  /// Only text generation moves. Tools run in Dart either way, so the actions
  /// the assistant can take are the same on-device as on the server.
  ///
  /// Routes through [_clientForStored] -- the same resolution `create` uses
  /// at boot -- rather than building [option]'s client directly, so a switch
  /// made here still respects [AiBackendStore.routingMode] (server-first
  /// wraps it in a [FallbackCompletionClient] same as it would have at boot).
  void applyBackend(AiBackendOption option) {
    if (!option.supportsInAppInference) return;
    _rebuildFromStore();
  }

  /// Re-resolves the client from the store as it stands right now.
  ///
  /// [applyBackend] calls this after a specific pick; the AI settings
  /// screen's routing control calls it (via the same `onChanged` the app
  /// already wires to [applyBackend]) after a routing-mode change alone --
  /// nothing about the selected backend moved, but server-first vs.
  /// local-only vs. server-only changes what [_clientForStored] builds.
  void _rebuildFromStore() {
    final store = _store;
    final factory = _clientFactory;
    if (store == null || factory == null) return;
    final resolved = _clientForStored(store, factory, _serverClient, _env);
    final client = resolved.client;
    // A null result (nothing buildable) leaves the previous working client
    // in place, same spirit as swallowing AiCompletionException used to.
    if (client != null) _client = client;
    _configurationHint = resolved.hint;
  }

  final String appDescription;

  /// Actions the assistant may take in this app.
  final List<AiTool> tools;

  /// Whether the backing model can be reached right now. The server client
  /// answers optimistically; Ollama is probed.
  Future<bool> get isReady => client.isAvailable();

  /// Asks the model for a handful of things worth trying in this app.
  ///
  /// The apps ship a fixed list of example prompts, which goes stale the
  /// moment someone has read it twice. This regenerates them from the same
  /// app description the agent already runs on, so the chips stay varied
  /// without every app maintaining its own copy. [seed] is the app's own
  /// list, passed to the model as the house style to imitate.
  ///
  /// Returns an empty list on any failure: suggestions are a nicety, and a
  /// broken backend must not take the assistant down with it.
  Future<List<String>> suggestPrompts({
    List<String> seed = const [],
    int count = 4,
  }) async {
    try {
      final reply = await client.complete(
        systemPrompt:
            'You suggest things a user could ask an in-app '
            'assistant. $appDescription. '
            'Reply with JSON only: {"prompts": ["...", "..."]}. '
            'Each prompt is a short first-person request, under 8 words, '
            'phrased as the user would type it. No numbering, no quotes '
            'inside the strings.',
        userPrompt: seed.isEmpty
            ? 'Give $count varied prompts.'
            : 'Give $count varied prompts in the style of these, but '
                  'different from them: ${seed.join(' | ')}',
        jsonMode: true,
        sampler: const AiSamplerConfig(temperature: 1),
      );
      final decoded = extractJsonObject(splitThinking(reply).rest);
      final prompts = decoded?['prompts'];
      if (prompts is! List) return const [];
      return [
        for (final p in prompts)
          if (p is String && p.trim().isNotEmpty) p.trim(),
      ].take(count).toList();
    } catch (_) {
      return const [];
    }
  }

  /// A short name for a thread, from what has been said in it so far.
  ///
  /// The first message truncated is a poor title -- half the threads in an
  /// app start "can you" -- so the model names them once the exchange is old
  /// enough to have a subject. Returns an empty string on any failure, and
  /// the caller keeps whatever title it already had.
  Future<String> suggestTitle(List<AiChatTurn> turns) async {
    if (turns.isEmpty) return '';
    final transcript = [
      for (final t in turns.take(6))
        '${t.isUser ? 'User' : 'Assistant'}: ${t.content.trim()}',
    ].join('\n');
    try {
      final reply = await client.complete(
        systemPrompt:
            'You name chat threads. $appDescription. '
            'Reply with JSON only: {"title": "..."}. '
            'The title is 2-5 words naming what the thread is about, in the '
            "user's own language. No quotes, no trailing punctuation.",
        userPrompt: transcript,
        jsonMode: true,
      );
      final title = extractJsonObject(splitThinking(reply).rest)?['title'];
      if (title is! String) return '';
      final trimmed = title.trim();
      return trimmed.length <= 48 ? trimmed : '${trimmed.substring(0, 45)}...';
    } catch (_) {
      return '';
    }
  }

  /// The instructions the agent runs on, for a transcript export.
  String systemPromptFor([List<AiTool>? tools]) => AiAgent(
    client: client,
    tools: tools ?? this.tools,
    appDescription: appDescription,
  ).systemPrompt;

  /// Runs [prompt] through the tool loop. See [AiAgent.run] for [confirm].
  Future<AiAgentResult> ask(
    String prompt, {
    List<AiTool>? tools,
    Future<AiToolDecision> Function(AiTool tool, AiToolCall call)? confirm,
    void Function(AiAgentStep step)? onStep,
    void Function(String delta)? onReply,
    int maxSteps = 6,
    List<AiChatTurn> history = const [],
  }) {
    final agent = AiAgent(
      client: client,
      tools: tools ?? this.tools,
      appDescription: appDescription,
      maxSteps: maxSteps,
    );
    return agent.run(
      prompt,
      confirm: confirm,
      onStep: onStep,
      onReply: onReply,
      history: history,
    );
  }
}
