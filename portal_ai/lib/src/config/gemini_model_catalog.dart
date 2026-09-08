/// Default Gemini model when [GEMINI_MODELS] is omitted but a key is set.
const kDefaultGeminiModel = 'gemini-2.0-flash';

/// Environment keys read by [GeminiModelCatalog.fromEnvironment].
abstract final class GeminiEnvKeys {
  static const apiKey = 'GEMINI_API_KEY';
  static const models = 'GEMINI_MODELS';
  static const model = 'GEMINI_MODEL';
}

/// Gemini models and API key loaded from app environment (.env).
class GeminiModelCatalog {
  const GeminiModelCatalog({required this.apiKey, required this.models});

  final String apiKey;
  final List<String> models;

  bool get hasApiKey => apiKey.isNotEmpty;

  bool get hasModels => models.isNotEmpty;

  /// Configured when an API key and at least one model name are present.
  bool get isConfigured => hasApiKey && hasModels;

  /// Model ids exposed to settings and clients.
  List<String> get availableModels => List.unmodifiable(models);

  String get defaultModel => models.first;

  String resolveModel(String? selected) {
    if (selected != null && selected.isNotEmpty && models.contains(selected)) {
      return selected;
    }
    return defaultModel;
  }

  /// Builds from a string map (e.g. [dotenv.env] after load).
  factory GeminiModelCatalog.fromEnvironment(Map<String, String> env) {
    final apiKey = env[GeminiEnvKeys.apiKey]?.trim() ?? '';
    final parsed = _parseModelList(
      env[GeminiEnvKeys.models],
      env[GeminiEnvKeys.model],
    );

    final models = parsed.isNotEmpty
        ? parsed
        : (apiKey.isNotEmpty ? [kDefaultGeminiModel] : const <String>[]);

    return GeminiModelCatalog(apiKey: apiKey, models: models);
  }

  static List<String> _parseModelList(String? modelsRaw, String? singleModel) {
    final fromList = _splitCsv(modelsRaw);
    if (fromList.isNotEmpty) return fromList;

    final single = singleModel?.trim();
    if (single != null && single.isNotEmpty) return [single];

    return const [];
  }

  static List<String> _splitCsv(String? raw) {
    if (raw == null || raw.trim().isEmpty) return const [];
    return raw
        .split(',')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();
  }
}
