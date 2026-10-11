import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:portal_platform/portal_platform.dart';

import '../model/run_log.dart';

/// Local-only history of routine runs. Execution is always on-device (see
/// [AutomationRepository]'s doc comment), so this never syncs -- it is a
/// device log, not a server resource.
class RunLogStore {
  static const _key = 'portal_automation_run_log';

  /// Oldest entries are dropped past this; a run log is a convenience, not a
  /// record that needs to grow forever.
  static const _maxEntries = 50;

  Future<void> append(RunResult result) async {
    final all = await getAll();
    all.insert(0, result);
    final capped = all.take(_maxEntries).toList();
    await PortalDatabase.kvPut(
      _key,
      jsonEncode([for (final r in capped) r.toJson()]),
    );
  }

  /// Newest first. A row that fails to decode is skipped, not fatal.
  Future<List<RunResult>> getAll() async {
    final raw = await PortalDatabase.kvGet(_key);
    if (raw == null || raw.isEmpty) return [];
    final decoded = jsonDecode(raw) as List;
    final results = <RunResult>[];
    for (final row in decoded) {
      try {
        results.add(RunResult.fromJson(Map<String, dynamic>.from(row as Map)));
      } catch (e) {
        debugPrint('[automation] run log read error, skipping a row: $e');
      }
    }
    return results;
  }
}
