import '../config/gemini_model_catalog.dart';
import '../models/ai_backend_kind.dart';
import '../models/ai_backend_option.dart';
import '../models/ai_dev_env_keys.dart';
import '../prefs/ai_backend_store.dart';
import 'ai_completion_client.dart';
import 'gemini_completion_client.dart';
import 'ollama_completion_client.dart';
import 'openai_compatible_completion_client.dart';
import 'system_ai_completion_client.dart';

/// Builds an [AiCompletionClient] for the selected backend.
class AiCompletionClientFactory {
  AiCompletionClientFactory({this._geminiCatalog});

  final GeminiModelCatalog? _geminiCatalog;

  AiCompletionClient create({
    required AiBackendKind kind,
    required AiBackendStore store,
    AiBackendOption? option,
    Map<String, String> env = const {},
  }) {
    switch (kind) {
      case AiBackendKind.cloudGemini:
        final catalog = _geminiCatalog;
        if (catalog == null || !catalog.isConfigured) {
          return const CloudGeminiCompletionClient();
        }
        final model = catalog.resolveModel(
          store.modelFor(AiBackendKind.cloudGemini) ??
              (option?.models.isNotEmpty == true ? option!.models.first : null),
        );
        return GeminiCompletionClient(catalog: catalog, model: model);
      case AiBackendKind.ollama:
        final host = store.ollamaHost;
        final model =
            store.modelFor(AiBackendKind.ollama) ??
            (option?.models.isNotEmpty == true ? option!.models.first : null);
        if (model == null || model.isEmpty) {
          throw const AiCompletionException(
            'Select an Ollama model in AI settings.',
          );
        }
        return OllamaCompletionClient(baseUrl: host, model: model);
      case AiBackendKind.systemOnDevice:
        return const SystemAiCompletionClient();
      case AiBackendKind.edgeGalleryDelegate:
        throw const AiCompletionException(
          'Edge Gallery is an external app, not an in-app backend.',
        );
      case AiBackendKind.openAiCompatible:
        final baseUrl = store.openAiBaseUrl.isNotEmpty
            ? store.openAiBaseUrl
            : env[AiDevEnvKeys.openAiBaseUrl]?.trim() ?? '';
        final model =
            store.modelFor(AiBackendKind.openAiCompatible) ??
            (env[AiDevEnvKeys.openAiModel]?.trim().isNotEmpty ?? false
                ? env[AiDevEnvKeys.openAiModel]!.trim()
                : null);
        if (baseUrl.isEmpty || model == null || model.isEmpty) {
          throw const AiCompletionException(
            'OpenAI-compatible backend is not configured: set a base URL '
            'and model in AI settings.',
          );
        }
        final apiKey = store.openAiApiKey.isNotEmpty
            ? store.openAiApiKey
            : env[AiDevEnvKeys.openAiApiKey]?.trim() ?? '';
        return OpenAiCompatibleCompletionClient(
          baseUrl: baseUrl,
          model: model,
          apiKey: apiKey,
        );
    }
  }
}
