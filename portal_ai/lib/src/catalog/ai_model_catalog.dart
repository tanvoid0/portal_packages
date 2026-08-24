import '../config/gemini_model_catalog.dart';
import '../discovery/ai_backend_discovery.dart';
import '../models/ai_backend_kind.dart';
import '../models/ai_backend_option.dart';

/// Unified API for available models per AI backend.
class AiModelCatalog {
  AiModelCatalog({
    required GeminiModelCatalog gemini,
    AiBackendDiscovery? discovery,
  })  : _gemini = gemini,
        _discovery = discovery ?? AiBackendDiscovery(geminiCatalog: gemini);

  final GeminiModelCatalog _gemini;
  final AiBackendDiscovery _discovery;

  /// Gemini model ids from app `.env` ([GeminiEnvKeys.models] / [GeminiEnvKeys.model]).
  List<String> get geminiModels => _gemini.availableModels;

  GeminiModelCatalog get gemini => _gemini;

  /// Returns configured models for [kind].
  ///
  /// Gemini reads from `.env`. Ollama and on-device models come from the latest
  /// [discover] probe unless [cachedOptions] is supplied.
  Future<List<String>> modelsFor(
    AiBackendKind kind, {
    List<AiBackendOption>? cachedOptions,
    bool cloudEligible = true,
    String ollamaHost = kDefaultOllamaBaseUrl,
    String? onDeviceModelPath,
  }) async {
    switch (kind) {
      case AiBackendKind.cloudGemini:
        return _gemini.availableModels;
      case AiBackendKind.ollama:
      case AiBackendKind.onDeviceLiteRt:
      case AiBackendKind.edgeGalleryDelegate:
        final options = cachedOptions ??
            await _discovery.discover(
              cloudEligible: cloudEligible,
              ollamaHost: ollamaHost,
              onDeviceModelPath: onDeviceModelPath,
            );
        return _modelsFromOptions(options, kind);
    }
  }

  /// Runs discovery and returns the option (including [AiBackendOption.models]).
  Future<AiBackendOption?> optionFor(
    AiBackendKind kind, {
    bool cloudEligible = true,
    String ollamaHost = kDefaultOllamaBaseUrl,
    String? onDeviceModelPath,
  }) async {
    final options = await _discovery.discover(
      cloudEligible: cloudEligible,
      ollamaHost: ollamaHost,
      onDeviceModelPath: onDeviceModelPath,
    );
    return _firstWhereOrNull(options, (o) => o.kind == kind);
  }

  static List<String> _modelsFromOptions(
    List<AiBackendOption> options,
    AiBackendKind kind,
  ) {
    final match = _firstWhereOrNull(options, (o) => o.kind == kind);
    return match?.models ?? const [];
  }
}

AiBackendOption? _firstWhereOrNull(
  Iterable<AiBackendOption> items,
  bool Function(AiBackendOption item) test,
) {
  for (final item in items) {
    if (test(item)) return item;
  }
  return null;
}
