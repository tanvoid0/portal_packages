import '../chat/ai_chat_session.dart';
import '../clients/ai_completion_client.dart';
import '../clients/ai_completion_client_factory.dart';
import '../clients/ollama_completion_client.dart';
import '../clients/server_completion_client.dart';
import '../models/ai_backend_kind.dart';
import '../models/ai_sampler_config.dart';
import '../models/ai_backend_option.dart';
import '../prefs/ai_backend_store.dart';
import '../tools/ai_agent.dart';
import '../tools/ai_tool.dart';
import '../tools/web_search_tool.dart';

/// Env keys that point the assistant at a local model during development.
abstract final class AiDevEnvKeys {
  /// Set to an Ollama model (e.g. `gemma4`) to bypass the server while testing.
  static const ollamaModel = 'AI_OLLAMA_MODEL';

  /// Optional Ollama host override.
  static const ollamaHost = 'AI_OLLAMA_HOST';
}

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
    // ignore: prefer_initializing_formals
  }) : _client = client;

  /// Builds the runtime from app config.
  ///
  /// [post] is the app's authenticated JSON POST (`ApiClient.post`). It may be
  /// omitted only by apps with no Portal server session, which must then set
  /// [AiDevEnvKeys.ollamaModel].
  factory PortalAiRuntime.create({
    AiPostJson? post,
    Map<String, String> env = const {},
    String feature = 'assistant',
    String appDescription = '',
    List<AiTool> tools = const [],
    AiBackendStore? store,
    AiCompletionClientFactory? clientFactory,
  }) {
    final server = post == null
        ? null
        : ServerCompletionClient(post: post, feature: feature);
    final factory = clientFactory ?? AiCompletionClientFactory();

    AiCompletionClient? client;

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
      client = _clientForStored(store, factory, server);
    }

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
    );
  }

  /// The client for whatever the user picked in AI settings, falling back to
  /// the server. Cloud stays on the server transport whenever there is one:
  /// the server holds the key, the model choice and the quota.
  static AiCompletionClient? _clientForStored(
    AiBackendStore? store,
    AiCompletionClientFactory factory,
    ServerCompletionClient? server,
  ) {
    final kind = store?.selectedKind;
    if (store == null || kind == null || kind == AiBackendKind.cloudGemini) {
      return server;
    }
    try {
      return factory.create(kind: kind, store: store);
    } on AiCompletionException {
      // Selected but not usable yet (no Ollama model picked, Edge Gallery
      // chosen as a delegate). The server is a working assistant; a thrown
      // exception at startup is not.
      return server;
    }
  }

  AiCompletionClient _client;
  final AiBackendStore? _store;
  final AiCompletionClientFactory? _clientFactory;
  final ServerCompletionClient? _serverClient;

  /// The client the assistant is talking to right now.
  AiCompletionClient get client => _client;

  /// Where the provider and model choice is kept, for a UI that wants to
  /// offer the switch itself. Null for a runtime built without one, which is
  /// every app that only ever talks to the server.
  AiBackendStore? get backendStore => _store;

  /// What to call the model in a one-line badge: the chosen model's own name
  /// where there is one, the provider otherwise.
  String get backendLabel {
    final store = _store;
    final kind = store?.selectedKind ?? AiBackendKind.cloudGemini;
    final model = store?.modelFor(kind);
    if (model != null && model.isNotEmpty) return model;
    return switch (kind) {
      AiBackendKind.cloudGemini => 'Cloud',
      AiBackendKind.ollama => 'Ollama',
      AiBackendKind.systemOnDevice => 'On-device',
      AiBackendKind.edgeGalleryDelegate => 'Edge Gallery',
    };
  }

  /// True when generation happens on this device rather than on the server.
  bool get usesLocalModel => _client is! ServerCompletionClient;

  /// Re-points the assistant after the user changes provider in settings, so
  /// the change takes effect without an app restart.
  ///
  /// Only text generation moves. Tools run in Dart either way, so the actions
  /// the assistant can take are the same on-device as on the server.
  void applyBackend(AiBackendOption option) {
    final store = _store;
    final factory = _clientFactory;
    if (store == null || factory == null) return;
    if (option.kind == AiBackendKind.cloudGemini && _serverClient != null) {
      _client = _serverClient;
      return;
    }
    if (!option.supportsInAppInference) return;
    try {
      _client = factory.create(kind: option.kind, store: store, option: option);
    } on AiCompletionException {
      // Leave the working client in place rather than breaking the assistant
      // on a half-configured provider.
    }
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
        systemPrompt: 'You suggest things a user could ask an in-app '
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
        systemPrompt: 'You name chat threads. $appDescription. '
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
    Future<bool> Function(AiTool tool, AiToolCall call)? confirm,
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
