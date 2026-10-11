import 'package:flutter_test/flutter_test.dart';
import 'package:portal_automation/portal_automation.dart';

void main() {
  group('AutomationEngine.run', () {
    test('records ok / skipped / failed / no-handler per step, in order', () async {
      final registry = HandlerRegistry()
        ..register(CallbackActionHandler(
          type: 'ok',
          onRun: (_) async => 'did it',
        ))
        ..register(CallbackActionHandler(
          type: 'boom',
          onRun: (_) async => throw StateError('kaboom'),
        ))
        ..register(CallbackActionHandler(
          type: 'blocked',
          onRun: (_) async => 'should not run',
          onAvailability: (_) async => const NeedsPermission('grant X'),
        ));

      final engine = AutomationEngine(registry);
      final automation = Automation.create(
        name: 'test',
        trigger: const ManualTrigger(),
        actions: const [
          UnknownAction({'type': 'ok'}),
          UnknownAction({'type': 'boom'}),
          UnknownAction({'type': 'blocked'}),
          UnknownAction({'type': 'unregistered'}),
        ],
      );

      final result = await engine.run(automation);

      expect(result.steps.map((s) => s.outcome).toList(), [
        StepOutcome.ok,
        StepOutcome.failed,
        StepOutcome.skipped,
        StepOutcome.failed, // no handler
      ]);
      expect(result.ok, isFalse);
      expect(result.failedCount, 2);
      expect(result.steps[2].message, 'grant X');
      expect(result.steps[3].message, contains('no handler'));
    });

    test('onRunComplete fires with the result', () async {
      RunResult? seen;
      final engine = AutomationEngine(
        HandlerRegistry()..register(CallbackActionHandler(type: 'ok', onRun: (_) async => '')),
        onRunComplete: (r) => seen = r,
      );
      await engine.run(Automation.create(
        name: 't',
        trigger: const ManualTrigger(),
        actions: const [UnknownAction({'type': 'ok'})],
      ));
      expect(seen, isNotNull);
      expect(seen!.ok, isTrue);
    });
  });

  group('round-trip', () {
    test('unknown trigger/action survive a JSON round-trip', () {
      final json = {
        'id': 'a1',
        'name': 'r',
        'enabled': true,
        'trigger': {'type': 'from_the_future', 'x': 1},
        'actions': [
          {'type': 'notify', 'title': 'hi', 'body': 'there'},
          {'type': 'also_future', 'y': 2},
        ],
        'createdAt': '2026-10-11T00:00:00.000Z',
        'updatedAt': '2026-10-11T00:00:00.000Z',
      };
      final back = Automation.fromJson(json).toJson();
      expect(back['trigger'], {'type': 'from_the_future', 'x': 1});
      expect((back['actions'] as List)[1], {'type': 'also_future', 'y': 2});
      expect((back['actions'] as List)[0]['title'], 'hi');
    });
  });
}
