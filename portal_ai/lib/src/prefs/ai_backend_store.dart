import 'package:shared_preferences/shared_preferences.dart';

import '../models/ai_backend_kind.dart';
import '../models/ai_backend_option.dart';

/// Persists AI backend preferences per app.
class AiBackendStore {
  AiBackendStore({
    required this._prefs,
    this.keyPrefix = 'portal_ai',
  });

  final SharedPreferences _prefs;
  final String keyPrefix;

  String get _selectedBackendKey => '${keyPrefix}_selected_backend_id';
  String get _ollamaHostKey => '${keyPrefix}_ollama_host';
  String get _ollamaModelKey => '${keyPrefix}_ollama_model';
  String get _geminiModelKey => '${keyPrefix}_gemini_model';
  String get _onDeviceModelPathKey => '${keyPrefix}_on_device_model_path';

  AiBackendKind? get selectedKind =>
      AiBackendKindIds.fromId(_prefs.getString(_selectedBackendKey));

  String? get selectedBackendId => _prefs.getString(_selectedBackendKey);

  String get ollamaHost =>
      _prefs.getString(_ollamaHostKey) ?? kDefaultOllamaBaseUrl;

  String? get ollamaModel => _prefs.getString(_ollamaModelKey);

  String? get geminiModel => _prefs.getString(_geminiModelKey);

  String? get onDeviceModelPath => _prefs.getString(_onDeviceModelPathKey);

  Future<void> setSelectedKind(AiBackendKind kind) =>
      _prefs.setString(_selectedBackendKey, kind.id);

  Future<void> setSelectedBackendId(String? id) async {
    if (id == null || id.isEmpty) {
      await _prefs.remove(_selectedBackendKey);
      return;
    }
    await _prefs.setString(_selectedBackendKey, id);
  }

  Future<void> setOllamaHost(String host) =>
      _prefs.setString(_ollamaHostKey, host.trim());

  Future<void> setOllamaModel(String model) =>
      _prefs.setString(_ollamaModelKey, model.trim());

  Future<void> setGeminiModel(String model) =>
      _prefs.setString(_geminiModelKey, model.trim());

  Future<void> setOnDeviceModelPath(String? path) async {
    if (path == null || path.isEmpty) {
      await _prefs.remove(_onDeviceModelPathKey);
      return;
    }
    await _prefs.setString(_onDeviceModelPathKey, path);
  }

  /// Picks the stored backend when still available, otherwise the first
  /// available inference backend, otherwise cloud.
  Future<AiBackendKind> resolveSelectedKind(
    List<AiBackendOption> discovered,
  ) async {
    final stored = selectedKind;
    if (stored != null) {
      final match = _firstWhereOrNull(discovered, (o) => o.kind == stored);
      if (match != null && match.available) {
        if (match.supportsInAppInference ||
            match.kind == AiBackendKind.edgeGalleryDelegate) {
          return stored;
        }
      }
    }

    for (final option in discovered) {
      if (option.available && option.supportsInAppInference) {
        await setSelectedKind(option.kind);
        return option.kind;
      }
    }

    await setSelectedKind(AiBackendKind.cloudGemini);
    return AiBackendKind.cloudGemini;
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
