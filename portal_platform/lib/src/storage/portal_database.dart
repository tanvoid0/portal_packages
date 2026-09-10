import 'dart:async';

import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

/// The one local SQLite database every Portal app writes through.
///
/// It replaced a pile of `SharedPreferences` JSON blobs — one per repository
/// cache, one for the sync queue — and the reason was not speed. Those blobs
/// could not share a transaction, so a kill between "write the cache" and
/// "queue the mutation" left an edit that looked saved and would never be
/// pushed. Cache and queue live here together precisely so that pair can be
/// one commit; see [transaction].
///
/// Payloads stay JSON in a column. Giving each of the fleet's ~16 entity
/// types real columns would mean a migration each for queries no screen runs
/// yet. An entity graduates to its own table when a screen needs to filter
/// server-side of Dart — not before.
abstract final class PortalDatabase {
  static const _fileName = 'portal_platform.db';
  static const _version = 1;

  static Database? _db;
  static Future<Database>? _opening;

  /// Overridable so tests can open an in-memory database. Production never
  /// sets it.
  static String? overrideFilePath;

  static Future<Database> get instance {
    final open = _db;
    if (open != null) return Future.value(open);
    return _opening ??= _open();
  }

  static Future<Database> _open() async {
    final path = overrideFilePath ??
        '${await getDatabasesPath()}/$_fileName';
    // sqflite keeps ONE native handle per path per process and its transaction
    // lock is Dart-side, so it does not span isolates. A background isolate
    // sharing that handle issues its own BEGIN/COMMIT against the connection
    // the app isolate is mid-transaction on, and the app's commit then fails
    // with "no current transaction" — measured, not theorised. A secondary
    // isolate therefore gets a connection of its own and SQLite's own file
    // locking does the arbitration.
    final isRootIsolate = RootIsolateToken.instance != null;
    final db = await openDatabase(
      path,
      version: _version,
      onCreate: _create,
      onConfigure: _configure,
      singleInstance: isRootIsolate,
    );
    _db = db;
    _opening = null;
    return db;
  }

  static Future<void> _configure(Database db) async {
    // Two connections to one file is the normal case here — the app and the
    // isolate that schedules notifications. WAL lets the reader carry on while
    // the other writes, and the busy timeout makes the writer wait its turn
    // instead of failing instantly, which in the background would be an alert
    // that silently never fires.
    // Both of these return a row, so they are queries, not statements —
    // execute() is rejected outright on Android.
    //
    // The timeout goes FIRST. Setting the journal mode takes a write lock
    // itself, so a second connection opening while the first is mid
    // transaction fails on that very pragma unless it already knows to wait.
    await db.rawQuery('PRAGMA busy_timeout = 5000');
    await db.rawQuery('PRAGMA journal_mode = WAL');
  }

  static Future<void> _create(Database db, int version) async {
    // `store` is the repository's scopedCacheKey, so the per-user isolation
    // the prefs keys had is carried over verbatim rather than reinvented as
    // a separate scope column.
    //
    // `ord` preserves the order the server sent, which the JSON list gave for
    // free and rows do not. Thirteen repositories render straight from this
    // list; a silent reordering across all of them is not worth saving a
    // column.
    await db.execute('''
      CREATE TABLE entities (
        store      TEXT    NOT NULL,
        entity_id  TEXT    NOT NULL,
        ord        INTEGER NOT NULL,
        payload    TEXT    NOT NULL,
        updated_at INTEGER NOT NULL,
        PRIMARY KEY (store, entity_id)
      )
    ''');
    await db.execute(
      'CREATE INDEX entities_store_ord ON entities (store, ord)',
    );
    // The sync queue and the one-shot migration flags. The queue stays a
    // single encrypted blob: its dedup, prune and eviction rules are
    // whole-list operations over at most 500 entries, and splitting it into
    // rows would mean per-row crypto for no behaviour anyone asked for. What
    // it needed was to be in *this* database, so it can share a transaction
    // with the cache.
    await db.execute(
      'CREATE TABLE kv (k TEXT PRIMARY KEY, v TEXT NOT NULL)',
    );
  }

  /// Run [action] as one commit. Everything written through the executor it
  /// hands back lands together or not at all.
  static Future<T> transaction<T>(
    Future<T> Function(DatabaseExecutor txn) action,
  ) async {
    final db = await instance;
    return db.transaction(action);
  }

  // ─── Entity rows ───────────────────────────────────────────────────

  /// Payloads for [store] in the order they were last written.
  static Future<List<String>> readPayloads(String store) async {
    final db = await instance;
    final rows = await db.query(
      'entities',
      columns: ['payload'],
      where: 'store = ?',
      whereArgs: [store],
      orderBy: 'ord',
    );
    return [for (final r in rows) r['payload'] as String];
  }

  /// Replace the contents of [store] with [rows], in order.
  ///
  /// Mark-and-sweep rather than delete-all-then-insert: a row whose payload
  /// has not changed keeps its `updated_at`, which is what a later
  /// newest-wins merge has to compare against. The sweep is an `ord < 0`
  /// delete rather than a `NOT IN (...)` so a long list cannot hit SQLite's
  /// bound-variable limit.
  static Future<void> writePayloads(
    DatabaseExecutor txn,
    String store,
    List<({String id, String payload})> rows,
  ) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await txn.update('entities', {'ord': -1},
        where: 'store = ?', whereArgs: [store]);
    final batch = txn.batch();
    for (var i = 0; i < rows.length; i++) {
      batch.rawInsert('''
        INSERT INTO entities (store, entity_id, ord, payload, updated_at)
        VALUES (?, ?, ?, ?, ?)
        ON CONFLICT (store, entity_id) DO UPDATE SET
          ord        = excluded.ord,
          payload    = excluded.payload,
          updated_at = CASE WHEN entities.payload = excluded.payload
                            THEN entities.updated_at
                            ELSE excluded.updated_at END
      ''', [store, rows[i].id, i, rows[i].payload, now]);
    }
    await batch.commit(noResult: true);
    await txn.delete('entities',
        where: 'store = ? AND ord < 0', whereArgs: [store]);
  }

  // ─── Key/value ─────────────────────────────────────────────────────

  static Future<String?> kvGet(String key, {DatabaseExecutor? txn}) async {
    final db = txn ?? await instance;
    final rows = await db.query('kv',
        columns: ['v'], where: 'k = ?', whereArgs: [key], limit: 1);
    return rows.isEmpty ? null : rows.first['v'] as String;
  }

  static Future<void> kvPut(String key, String value,
      {DatabaseExecutor? txn}) async {
    final db = txn ?? await instance;
    await db.insert('kv', {'k': key, 'v': value},
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// [kvGet], importing the value once from [SharedPreferences] if this
  /// database has never held it.
  ///
  /// Every store in the fleet kept its JSON under a prefs key before this
  /// database existed, so every one of them needs the same one-shot move. The
  /// prefs entry is left in place for one release, and an empty string is
  /// stored even when there was nothing to import, so "prefs has nothing" is
  /// answered once rather than on every read.
  static Future<String> kvGetOrImportFromPrefs(String key,
      {DatabaseExecutor? txn}) async {
    final existing = await kvGet(key, txn: txn);
    if (existing != null) return existing;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key) ?? '';
    await kvPut(key, raw, txn: txn);
    return raw;
  }

  /// Closes and forgets the open database. Tests only.
  static Future<void> resetForTest() async {
    await _db?.close();
    _db = null;
    _opening = null;
  }
}
