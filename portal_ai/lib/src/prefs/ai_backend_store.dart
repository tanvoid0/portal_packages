import 'package:shared_preferences/shared_preferences.dart';

import '../models/ai_backend_kind.dart';
import '../models/ai_backend_option.dart';

/// Persists AI backend preferences per app.
class AiBackendStore {
  AiBackendStore({required this._prefs, this.keyPrefix = 'portal_ai'});

  final SharedPreferences _prefs;
  final String keyPrefix;

  String get _selectedBackendKey => '${keyPrefix}_selected_backend_id';
  String get _ollamaHostKey => '${keyPrefix}_ollama_host';

  /// Gemini and Ollama keep their original key names so an existing install
  /// does not silently forget the model the user picked.
  String _modelKey(AiBackendKind kind) => switch (kind) {
    AiBackendKind.ollama => '${keyPrefix}_ollama_model',
    AiBackendKind.cloudGemini => '${keyPrefix}_gemini_model',
    _ => '${keyPrefix}_model_${kind.id}',
  };

  AiBackendKind? get selectedKind =>
      AiBackendKindIds.fromId(_prefs.getString(_selectedBackendKey));

  String? get selectedBackendId => _prefs.getString(_selectedBackendKey);

  String get ollamaHost =>
      _prefs.getString(_ollamaHostKey) ?? defaultOllamaBaseUrl;

  /// The model chosen for [kind], if any. Providers report their own model
  /// lists; nothing here assumes what those contain.
  String? modelFor(AiBackendKind kind) => _prefs.getString(_modelKey(kind));

  String? get ollamaModel => modelFor(AiBackendKind.ollama);

  String? get geminiModel => modelFor(AiBackendKind.cloudGemini);

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

  Future<void> setModelFor(AiBackendKind kind, String model) =>
      _prefs.setString(_modelKey(kind), model.trim());

  Future<void> setOllamaModel(String model) =>
      setModelFor(AiBackendKind.ollama, model);

  Future<void> setGeminiModel(String model) =>
      setModelFor(AiBackendKind.cloudGemini, model);

  /// Makes sure the model stored for [option]'s provider is one that provider
  /// actually offers, defaulting to its first. A provider that reports no
  /// models (Edge Gallery, or a device model the platform does not name) keeps
  /// whatever is stored.
  Future<void> ensureModelFor(AiBackendOption option) async {
    if (option.models.isEmpty) return;
    final current = modelFor(option.kind);
    if (current != null && option.models.contains(current)) return;
    await setModelFor(option.kind, option.models.first);
  }

  /// Picks the stored backend when there is one, otherwise defaults to the
  /// first available inference backend, otherwise cloud.
  ///
  /// A stored choice is never overwritten by a fallback: Ollama being
  /// unreachable for one scan (daemon not started, LAN hiccup) must not
  /// silently switch the user to another provider and persist that switch —
  /// the row still shows disabled with a reason, same as any other
  /// momentarily-unavailable option.
  Future<AiBackendKind> resolveSelectedKind(
    List<AiBackendOption> discovered,
  ) async {
    final stored = selectedKind;
    if (stored != null) return stored;

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
