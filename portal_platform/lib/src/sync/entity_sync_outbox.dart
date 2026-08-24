import 'package:get/get.dart';

import 'sync_mutation.dart';
import 'sync_operation.dart';
import 'sync_queue.dart';

/// Generic outbox over [SyncQueue] for a single [entityType].
final class EntitySyncOutbox<M extends SyncMutation> {
  EntitySyncOutbox({
    required this.entityType,
    required this.fromSyncOperation,
  });

  final String entityType;
  final M Function(SyncOperation) fromSyncOperation;

  Future<void> enqueue(M mutation) async {
    await Get.find<SyncQueue>().enqueue(mutation.toSyncOperation());
  }

  Future<List<M>> pending() async {
    final ops = await Get.find<SyncQueue>().getByEntityType(entityType);
    return ops.map(fromSyncOperation).toList();
  }

  Future<List<SyncOperation>> readOperations() async {
    return Get.find<SyncQueue>().getByEntityType(entityType);
  }

  Future<void> removeApplied(Iterable<String> operationIds) async {
    final queue = Get.find<SyncQueue>();
    for (final id in operationIds) {
      await queue.remove(id);
    }
  }

  Future<void> clearPending() async {
    if (!Get.isRegistered<SyncQueue>()) return;
    await Get.find<SyncQueue>().clearEntityType(entityType);
  }

  Future<void> replaceOperations(List<SyncOperation> ops) async {
    final queue = Get.find<SyncQueue>();
    await queue.clearEntityType(entityType);
    for (final op in ops) {
      await queue.enqueue(op);
    }
  }
}
