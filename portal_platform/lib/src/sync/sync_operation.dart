import 'dart:convert';
import 'package:uuid/uuid.dart';

/// The kind of mutation a [SyncOperation] represents.
enum SyncOperationType {
  /// A new entity that must be `POST`-ed to the server.
  create,

  /// An existing entity whose fields changed; pushed via `PUT`.
  update,

  /// An entity that should be removed from the server via `DELETE`.
  delete,
}

/// A single queued mutation that has not yet been pushed to the server.
///
/// Each operation captures the full entity [data] (for creates/updates)
/// so that the sync layer can replay it when the device comes back
/// online.  Deletes only need [entityId].
///
/// Operations are persisted to disk by [SyncQueue] and are processed
/// in creation-order during [SyncableRepository.sync].
class SyncOperation {
  /// Unique identifier for this operation (auto-generated UUID v4).
  final String id;

  /// Logical entity type this operation belongs to (e.g. `'recipe'`).
  /// Must match [SyncableRepository.entityType].
  final String entityType;

  /// The ID of the entity being mutated.
  final String entityId;

  /// Whether this is a create, update, or delete.
  final SyncOperationType type;

  /// Full JSON payload of the entity.  `null` for deletes.
  final Map<String, dynamic>? data;

  /// When this operation was enqueued.
  final DateTime createdAt;

  SyncOperation({
    String? id,
    required this.entityType,
    required this.entityId,
    required this.type,
    this.data,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  /// Returns a shallow copy with optional field overrides.
  SyncOperation copyWith({
    SyncOperationType? type,
    Map<String, dynamic>? data,
  }) {
    return SyncOperation(
      id: id,
      entityType: entityType,
      entityId: entityId,
      type: type ?? this.type,
      data: data ?? this.data,
      createdAt: createdAt,
    );
  }

  // ─── Serialisation ────────────────────────────────────────────────

  Map<String, dynamic> toJson() => {
        'id': id,
        'entityType': entityType,
        'entityId': entityId,
        'type': type.name,
        'data': data,
        'createdAt': createdAt.toIso8601String(),
      };

  factory SyncOperation.fromJson(Map<String, dynamic> json) => SyncOperation(
        id: json['id'] as String,
        entityType: json['entityType'] as String,
        entityId: json['entityId'] as String,
        type: SyncOperationType.values.byName(json['type'] as String),
        data: json['data'] != null
            ? Map<String, dynamic>.from(json['data'] as Map)
            : null,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  /// Decode a JSON string into a list of [SyncOperation]s.
  static List<SyncOperation> listFromJson(String raw) {
    if (raw.isEmpty) return [];
    final list = jsonDecode(raw) as List;
    return list
        .map((e) => SyncOperation.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// Encode a list of [SyncOperation]s into a JSON string.
  static String listToJson(List<SyncOperation> ops) =>
      jsonEncode(ops.map((o) => o.toJson()).toList());
}
