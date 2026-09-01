import '../chat/ai_chat_session.dart';
import '../clients/ai_completion_client.dart';
import '../clients/ai_completion_client_factory.dart';
import '../clients/ollama_completion_client.dart';
import '../clients/server_completion_client.dart';
import '../models/ai_backend_kind.dart';
import '../models/ai_backend_option.dart';
import '../prefs/ai_backend_store.dart';
import '../tools/ai_agent.dart';
import '../tools/ai_tool.dart';

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

    return PortalAiRuntime(
      client: client,
      appDescription: appDescription,
      tools: tools,
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

  /// Runs [prompt] through the tool loop. See [AiAgent.run] for [confirm].
  Future<AiAgentResult> ask(
    String prompt, {
    List<AiTool>? tools,
    Future<bool> Function(AiTool tool, AiToolCall call)? confirm,
    void Function(AiAgentStep step)? onStep,
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
      history: history,
    );
  }
}
