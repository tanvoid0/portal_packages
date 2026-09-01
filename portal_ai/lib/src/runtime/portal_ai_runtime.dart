import '../clients/ai_completion_client.dart';
import '../clients/ollama_completion_client.dart';
import '../clients/server_completion_client.dart';
import '../models/ai_backend_kind.dart';
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
    required this.client,
    required this.usesLocalModel,
    this.appDescription = '',
    this.tools = const [],
  });

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
  }) {
    final ollamaModel = env[AiDevEnvKeys.ollamaModel]?.trim();

    if (ollamaModel != null && ollamaModel.isNotEmpty) {
      return PortalAiRuntime(
        client: OllamaCompletionClient(
          baseUrl: env[AiDevEnvKeys.ollamaHost]?.trim().isNotEmpty ?? false
              ? env[AiDevEnvKeys.ollamaHost]!.trim()
              : defaultOllamaBaseUrl,
          model: ollamaModel,
        ),
        usesLocalModel: true,
        appDescription: appDescription,
        tools: tools,
      );
    }

    if (post == null) {
      throw ArgumentError(
        'PortalAiRuntime needs either a server transport or '
        '${AiDevEnvKeys.ollamaModel} in .env.',
      );
    }

    return PortalAiRuntime(
      client: ServerCompletionClient(post: post, feature: feature),
      usesLocalModel: false,
      appDescription: appDescription,
      tools: tools,
    );
  }

  final AiCompletionClient client;

  /// True when running against a local Ollama model instead of the server.
  final bool usesLocalModel;

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
  }) {
    final agent = AiAgent(
      client: client,
      tools: tools ?? this.tools,
      appDescription: appDescription,
      maxSteps: maxSteps,
    );
    return agent.run(prompt, confirm: confirm, onStep: onStep);
  }
}
