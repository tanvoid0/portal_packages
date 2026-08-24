import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'models/portal_notification_models.dart';

/// Persists notification entries for UI and recovery after restart.
class PortalNotificationStore {
  PortalNotificationStore({
    required this.storageKey,
    SharedPreferences? preferences,
  }) : _preferences = preferences;

  final String storageKey;
  SharedPreferences? _preferences;

  Future<SharedPreferences> _prefs() async {
    return _preferences ??= await SharedPreferences.getInstance();
  }

  Future<List<PortalNotificationEntry>> load() async {
    final raw = (await _prefs()).getString(storageKey);
    if (raw == null || raw.isEmpty) return const [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list.map(_decodeEntry).toList();
  }

  PortalNotificationEntry _decodeEntry(dynamic entry) {
    final map = Map<String, dynamic>.from(entry as Map);
    if (map.containsKey('intentId') || map.containsKey('source')) {
      return PortalNotificationEntry.fromJson(map);
    }
    return PortalNotificationEntry.fromPersistedV1(map);
  }

  Future<void> save(List<PortalNotificationEntry> entries) async {
    final encoded = jsonEncode(entries.map((entry) => entry.toJson()).toList());
    await (await _prefs()).setString(storageKey, encoded);
  }

  Future<void> clear() async {
    await (await _prefs()).remove(storageKey);
  }
}
