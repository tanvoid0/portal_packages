import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../storage/user_storage_scope.dart';
import '../sync/syncable_repository.dart';
import 'api_client.dart';

/// The fleet's single XP ledger, client side.
///
/// One ledger, or none: a finished workout in `portal_gym` and a completed
/// task in `portal_task` raise the same level, because both call this and the
/// server holds one row per person. **Per-app XP would be worse than no XP**,
/// so nothing here keeps a local score — the server owns the total, the level
/// and what each action is worth. A client that names its own reward is a
/// client that can print money, and `POST /xp/events` does not even accept an
/// `xp` field.
///
/// Awards are idempotent server-side on
/// `(source, action, entity_id, calendar day)`, which is what makes the retry
/// below safe: a habit ticked, unticked and ticked again scores once, and so
/// does the same event replayed from two devices.
class PortalXp {
  PortalXp._();

  static const String _pendingKey = 'portal_xp_pending';

  /// A ceiling on the retry backlog. Reaching it means weeks offline, and an
  /// unbounded list rewritten on every write is the cost this avoids.
  static const int _maxPending = 200;

  /// Records one action. Never throws: XP is a reward, and a reward failing
  /// must not fail the write that earned it — the workout is saved whether or
  /// not the ledger heard about it.
  ///
  /// A failure is **queued, not swallowed**: the event is kept and retried on
  /// the next record or [flushPending], because a lost award is a number the
  /// user can see is wrong.
  static Future<void> record({
    required String source,
    required String action,
    required String entityId,
    DateTime? occurredAt,
  }) async {
    final event = <String, dynamic>{
      'source': source,
      'action': action,
      'entity_id': entityId,
      'occurred_at': (occurredAt ?? DateTime.now()).toIso8601String(),
    };

    await flushPending();
    if (!await _post(event)) await _enqueue(event);
  }

  /// Retries everything a previous [record] could not deliver. Safe to call
  /// on app start or on reconnect; a delivered event is dropped from the
  /// backlog, and a rejected one is dropped too — a 400 will not become a 200
  /// by being sent again.
  static Future<void> flushPending() async {
    final pending = await _readPending();
    if (pending.isEmpty) return;

    for (var i = 0; i < pending.length; i++) {
      if (await _post(pending[i])) continue;
      // The first failure is almost always "no connection", so stop rather
      // than spend the rest of the backlog proving it. Everything from here
      // on stays queued, in order.
      await _writePending(pending.sublist(i));
      return;
    }
    await _writePending(const []);
  }

  /// The ledger as the server computes it: total, level, progress into the
  /// level, and what the next one costs. Null when there is no API or the
  /// read fails — the caller shows nothing rather than a stale level.
  static Future<Map<String, dynamic>?> fetch() async {
    final api = _api;
    if (api == null) return null;
    try {
      final data = await api.get('/xp');
      if (data is! Map) return null;
      return Map<String, dynamic>.from(data);
    } catch (_) {
      return null;
    }
  }

  static ApiClient? get _api =>
      Get.isRegistered<ApiClient>() ? Get.find<ApiClient>() : null;

  /// True when the event is settled — delivered, or refused for a reason
  /// resending cannot fix.
  static Future<bool> _post(Map<String, dynamic> event) async {
    final api = _api;
    if (api == null) return false;
    try {
      await api.post('/xp/events', body: event);
      return true;
    } catch (e) {
      // A 4xx is the server saying this event is wrong — an unknown action, a
      // dead session. Keeping it would retry it forever.
      final permanent = isPermanentSyncFailure(e);
      if (permanent) {
        debugPrint('[xp] dropping ${event['action']}: $e');
      }
      return permanent;
    }
  }

  static String get _key => UserStorageScope.scopeKey(_pendingKey);

  static Future<List<Map<String, dynamic>>> _readPending() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    try {
      return (jsonDecode(raw) as List)
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> _writePending(List<Map<String, dynamic>> events) async {
    final prefs = await SharedPreferences.getInstance();
    if (events.isEmpty) {
      await prefs.remove(_key);
      return;
    }
    await prefs.setString(_key, jsonEncode(events));
  }

  static Future<void> _enqueue(Map<String, dynamic> event) async {
    final pending = await _readPending();
    pending.add(event);
    // Oldest first out: a three-week-old award matters less than today's.
    final trimmed = pending.length > _maxPending
        ? pending.sublist(pending.length - _maxPending)
        : pending;
    await _writePending(trimmed);
  }
}
