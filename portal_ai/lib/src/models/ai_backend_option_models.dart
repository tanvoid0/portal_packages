import 'ai_backend_kind.dart';
import 'ai_backend_option.dart';

/// Helpers for displaying model lists on backend options.
extension AiBackendOptionModels on AiBackendOption {
  bool get hasModels => models.isNotEmpty;

  /// Short summary for settings subtitles, e.g. "gemini-2.0-flash" or "3 models".
  String? get modelsSummary {
    if (models.isEmpty) return null;
    if (models.length == 1) return models.first;
    final preview = models.take(2).join(', ');
    if (models.length > 2) return '$preview +${models.length - 2} more';
    return preview;
  }
}

Future<void> applyDefaultModelForBackend({
  required AiBackendOption option,
  required Future<void> Function(String model) setOllamaModel,
  required Future<void> Function(String model) setGeminiModel,
  String? currentOllamaModel,
  String? currentGeminiModel,
}) async {
  if (option.models.isEmpty) return;

  switch (option.kind) {
    case AiBackendKind.ollama:
      if (currentOllamaModel == null ||
          !option.models.contains(currentOllamaModel)) {
        await setOllamaModel(option.models.first);
      }
    case AiBackendKind.cloudGemini:
      if (currentGeminiModel == null ||
          !option.models.contains(currentGeminiModel)) {
        await setGeminiModel(option.models.first);
      }
    default:
      break;
  }
}
