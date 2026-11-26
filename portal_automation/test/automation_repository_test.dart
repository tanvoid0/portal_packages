import 'package:flutter_test/flutter_test.dart';
import 'package:portal_automation/portal_automation.dart';
import 'package:portal_platform/portal_platform.dart';

class _Api extends ApiClient {
  final bodies = <Object?>[];

  @override
  Future<dynamic> post(String endpoint, {dynamic body}) async {
    bodies.add(body);
  }

  @override
  Future<dynamic> put(String endpoint, {dynamic body}) async {
    bodies.add(body);
  }

  // The pull after the push is not under test; failing it skips the database.
  @override
  Future<dynamic> get(
    String endpoint, {
    Map<String, String>? queryParams,
  }) async => throw ApiException.networkFailure();
}

class _Queue extends SyncQueue {
  _Queue(this.ops);
  final List<SyncOperation> ops;

  @override
  Future<List<SyncOperation>> getByEntityType(String entityType) async =>
      List.of(ops);
  @override
  Future<bool> markAttempted(String operationId) async =>
      ops.any((o) => o.id == operationId);
  @override
  Future<void> enqueue(SyncOperation op) async =>
      ops[ops.indexWhere((o) => o.id == op.id)] = op;
  @override
  Future<void> remove(String operationId) async =>
      ops.removeWhere((o) => o.id == operationId);
}

class _Repo extends AutomationRepository {
  _Repo(this.cache, this.syncQueue, this.api);
  final List<Automation> cache;
  @override
  final SyncQueue syncQueue;
  @override
  final ApiClient api;

  @override
  ConnectivityService get connectivity => ConnectivityService();
  @override
  String get apiBasePath => '/automations';
  @override
  Future<List<Automation>> readCache() async => cache;
}

void main() {
  test('sync adds conditions to writes queued without them', () async {
    final gated = Automation.create(
      name: 'gated',
      trigger: const ManualTrigger(),
      conditions: const [
        WeekdayCondition(weekdays: {5}),
      ],
    );
    final open = Automation.create(
      name: 'open',
      trigger: const ManualTrigger(),
    );
    // As the old toWireJson left them: no `conditions` key.
    final queue = _Queue([
      SyncOperation(
        entityType: 'automation',
        entityId: gated.id,
        type: SyncOperationType.create,
        data: {'id': gated.id},
      ),
      SyncOperation(
        entityType: 'automation',
        entityId: open.id,
        type: SyncOperationType.update,
        data: {'name': 'open'},
      ),
    ]);
    final api = _Api();

    await _Repo([gated, open], queue, api).sync();

    expect(api.bodies, [
      {
        'id': gated.id,
        'conditions': [gated.conditions.single.toJson()],
      },
      // Nothing cached to send, so the server keeps whatever it has.
      {'name': 'open'},
    ]);
    expect(queue.ops, isEmpty);
  });

  test('toWireJson carries conditions, including an explicit empty list', () {
    final automation = Automation.create(
      name: 't',
      trigger: const ManualTrigger(),
      conditions: const [
        WeekdayCondition(weekdays: {5}),
      ],
      actions: const [],
    );
    final repository = AutomationRepository();

    final wire = repository.toWireJson(automation, isCreate: false);
    expect(wire['conditions'], [automation.conditions.single.toJson()]);

    // Clearing conditions must reach the server, so the key stays.
    final cleared = repository.toWireJson(
      automation.copyWith(conditions: const []),
      isCreate: false,
    );
    expect(cleared['conditions'], isEmpty);
    expect(cleared.containsKey('conditions'), isTrue);
  });
}
