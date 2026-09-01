import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'ai_chat_session.dart';

/// Threads kept in shared preferences, one bucket per [keyPrefix].
///
/// Every app gets its own key, so Portal Gym's threads never show up in Portal
/// Recipe. shared_preferences is already a dependency here (the backend picker
/// uses it), so this costs nothing extra and works on every platform the apps
/// run on.
class PrefsAiChatStore implements AiChatStore {
  PrefsAiChatStore({required this.prefs, required this.keyPrefix});


  static Future<PrefsAiChatStore> open(String keyPrefix) async =>
      PrefsAiChatStore(
        prefs: await SharedPreferences.getInstance(),
        keyPrefix: keyPrefix,
      );

  final SharedPreferences prefs;
  final String keyPrefix;

  String get _key => '${keyPrefix}_sessions_v1';

  /// ponytail: whole list rewritten on every save. Chat history is tens of
  /// threads, not thousands; split into one key per session if that changes.
  List<AiChatSession> _all() {
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    try {
      return (jsonDecode(raw) as List<dynamic>)
          .map((e) =>
              aiChatSessionFromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      // A thread written by an older shape is not worth crashing the sheet for.
      return [];
    }
  }

  Future<void> _write(List<AiChatSession> sessions) => prefs.setString(
        _key,
        jsonEncode(sessions.map((s) => s.toJson()).toList()),
      );

  @override
  List<AiChatSessionSummary> listSummaries() => (_all()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt)))
      .map(
        (s) => AiChatSessionSummary(
          id: s.id,
          title: s.title,
          updatedAt: s.updatedAt,
          turnCount: s.turns.length,
          payload: s.payload,
        ),
      )
      .toList();

  @override
  AiChatSession? load(String id) {
    for (final session in _all()) {
      if (session.id == id) return session;
    }
    return null;
  }

  @override
  Future<void> save(AiChatSession session) async {
    final rest = _all().where((s) => s.id != session.id).toList();
    await _write([session, ...rest]);
  }

  @override
  Future<void> delete(String id) =>
      _write(_all().where((s) => s.id != id).toList());
}
