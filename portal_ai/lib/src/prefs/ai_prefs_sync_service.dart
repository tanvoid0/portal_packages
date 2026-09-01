import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/ai_backend_kind.dart';
import 'ai_backend_store.dart';

/// Matches `ApiClient.get` in portal_platform, so apps pass that directly.
typedef AiGetJson = Future<dynamic> Function(String path);

/// Matches `ApiClient.put` in portal_platform, so apps pass that directly.
typedef AiPutJson = Future<dynamic> Function(String path, {dynamic body});

/// Keeps one [AiBackendStore] in sync with the account's shared choice on
/// the Portal server, so picking a provider or model in one app carries over
/// to every other Portal app signed into the same account.
///
/// Each Portal app is a separate install with its own local storage — there
/// is no on-device sharing between them. [store] stays the offline-first
/// source of truth (the app always runs on whatever is stored locally); this
/// service only best-effort pushes local changes and pulls the account's
/// current choice, same spirit as `SyncableRepository`: local wins until a
/// push confirms, and a flaky server never blocks the app.
class AiPrefsSyncService {
  AiPrefsSyncService({
    required this.store,
    required this.get,
    required this.put,
    this.path = '/common/ai-prefs',
  });

  final AiBackendStore store;
  final AiGetJson get;
  final AiPutJson put;
  final String path;

  String get _dirtyKey => '${store.keyPrefix}_prefs_dirty';

  /// Push a local change that has not reached the server yet, then pull
  /// whatever the account's current choice is. Called at startup and after
  /// [markChanged]; never throws.
  Future<void> sync() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_dirtyKey) ?? false) {
      if (!await _push()) return; // still dirty; local choice keeps winning
      await prefs.setBool(_dirtyKey, false);
    }
    await _pull();
  }

  /// Call after the user changes provider, model, or Ollama host.
  Future<void> markChanged() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_dirtyKey, true);
    await sync();
  }

  Future<bool> _push() async {
    try {
      await put(path, body: _toJson());
      return true;
    } catch (e) {
      debugPrint('[AiPrefsSync] push failed, will retry later: $e');
      return false;
    }
  }

  Future<void> _pull() async {
    try {
      final data = await get(path);
      if (data is! Map) return;
      await _applyRemote(Map<String, dynamic>.from(data));
    } catch (e) {
      debugPrint('[AiPrefsSync] pull failed, keeping local: $e');
    }
  }

  Map<String, dynamic> _toJson() {
    final models = <String, String>{};
    for (final kind in AiBackendKind.values) {
      final model = store.modelFor(kind);
      if (model != null) models[kind.id] = model;
    }
    return {
      'selected_backend_id': store.selectedBackendId,
      'models': models,
    };
  }

  Future<void> _applyRemote(Map<String, dynamic> json) async {
    final selected = json['selected_backend_id'] as String?;
    if (selected != null && selected != store.selectedBackendId) {
      await store.setSelectedBackendId(selected);
    }
    final models = json['models'];
    if (models is Map) {
      for (final entry in models.entries) {
        final kind = AiBackendKindIds.fromId(entry.key as String);
        final model = entry.value as String?;
        if (kind != null && model != null && model.isNotEmpty) {
          await store.setModelFor(kind, model);
        }
      }
    }
  }
}
