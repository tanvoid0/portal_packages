import '../config/gemini_model_catalog.dart';
import '../models/ai_backend_kind.dart';
import '../models/ai_backend_option.dart';
import '../prefs/ai_backend_store.dart';
import 'ai_completion_client.dart';
import 'gemini_completion_client.dart';
import 'ollama_completion_client.dart';

/// Builds an [AiCompletionClient] for the selected backend.
class AiCompletionClientFactory {
  AiCompletionClientFactory({GeminiModelCatalog? geminiCatalog})
      : _geminiCatalog = geminiCatalog;

  final GeminiModelCatalog? _geminiCatalog;

  AiCompletionClient create({
    required AiBackendKind kind,
    required AiBackendStore store,
    AiBackendOption? option,
  }) {
    switch (kind) {
      case AiBackendKind.cloudGemini:
        final catalog = _geminiCatalog;
        if (catalog == null || !catalog.isConfigured) {
          return const CloudGeminiCompletionClient();
        }
        final model = catalog.resolveModel(
          store.geminiModel ??
              (option?.models.isNotEmpty == true ? option!.models.first : null),
        );
        return GeminiCompletionClient(catalog: catalog, model: model);
      case AiBackendKind.ollama:
        final host = store.ollamaHost;
        final model = store.ollamaModel ??
            (option?.models.isNotEmpty == true ? option!.models.first : null);
        if (model == null || model.isEmpty) {
          throw const AiCompletionException(
            'Select an Ollama model in AI settings.',
          );
        }
        return OllamaCompletionClient(baseUrl: host, model: model);
      case AiBackendKind.onDeviceLiteRt:
        return const OnDeviceLiteRtCompletionClient();
      case AiBackendKind.edgeGalleryDelegate:
        throw const AiCompletionException(
          'Edge Gallery is an external app, not an in-app backend.',
        );
    }
  }
}
