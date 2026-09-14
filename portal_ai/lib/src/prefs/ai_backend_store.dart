import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/ai_backend_kind.dart';
import '../models/ai_backend_option.dart';
import '../models/ai_routing_mode.dart';

/// Persists AI backend preferences per app.
class AiBackendStore {
  AiBackendStore({
    required this._prefs,
    this.keyPrefix = 'portal_ai',
    FlutterSecureStorage? secureStorage,
  }) : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  final SharedPreferences _prefs;
  final String keyPrefix;
  final FlutterSecureStorage _secureStorage;

  String get _selectedBackendKey => '${keyPrefix}_selected_backend_id';
  String get _ollamaHostKey => '${keyPrefix}_ollama_host';
  String get _openAiBaseUrlKey => '${keyPrefix}_openai_base_url';
  String get _openAiApiKeyKey => '${keyPrefix}_openai_api_key';
  String get _routingModeKey => '${keyPrefix}_routing_mode';

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

  String get openAiBaseUrl => _prefs.getString(_openAiBaseUrlKey) ?? '';

  Future<void> setOpenAiBaseUrl(String baseUrl) =>
      _prefs.setString(_openAiBaseUrlKey, baseUrl.trim());

  /// The stored key, once [loadOpenAiApiKey] (or a prior [setOpenAiApiKey])
  /// has warmed the cache this run.
  ///
  /// ponytail: secure storage has no synchronous read, so a key set in an
  /// earlier run reads empty here until loaded once -- call
  /// [loadOpenAiApiKey] during startup (AI settings' `initState` is fine)
  /// before relying on this. Upgrade path if that gap ever bites: make store
  /// construction itself async and warm every secret up front.
  String get openAiApiKey => _openAiApiKeyCache ?? '';
  String? _openAiApiKeyCache;

  Future<void> loadOpenAiApiKey() async {
    _openAiApiKeyCache = await _secureStorage.read(key: _openAiApiKeyKey) ?? '';
  }

  /// Writes to secure storage first; the cache only moves once that succeeds,
  /// and a throwing write propagates rather than leaving the cache claiming a
  /// key that was never actually persisted. The caller (AI settings) is what
  /// turns that into a SnackBar.
  Future<void> setOpenAiApiKey(String key) async {
    final trimmed = key.trim();
    if (trimmed.isEmpty) {
      await _secureStorage.delete(key: _openAiApiKeyKey);
    } else {
      await _secureStorage.write(key: _openAiApiKeyKey, value: trimmed);
    }
    _openAiApiKeyCache = trimmed;
  }

  AiRoutingMode get routingMode =>
      AiRoutingModeIds.fromId(_prefs.getString(_routingModeKey)) ??
      AiRoutingMode.serverFirst;

  Future<void> setRoutingMode(AiRoutingMode mode) =>
      _prefs.setString(_routingModeKey, mode.id);

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
