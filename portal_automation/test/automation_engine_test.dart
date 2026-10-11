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

  group('conditions', () {
    test('an unmet condition blocks every action and skips the run', () async {
      var ran = false;
      final engine = AutomationEngine(
        HandlerRegistry()
          ..register(CallbackActionHandler(
            type: 'ok',
            onRun: (_) async {
              ran = true;
              return '';
            },
          )),
        conditionEvaluator: ConditionEvaluator(now: () => DateTime(2026, 1, 1, 3)),
      );
      final result = await engine.run(Automation.create(
        name: 't',
        trigger: const ManualTrigger(),
        conditions: const [
          TimeWindowCondition(startHour: 9, startMinute: 0, endHour: 17, endMinute: 0),
        ],
        actions: const [UnknownAction({'type': 'ok'})],
      ));
      expect(result.conditionsMet, isFalse);
      expect(result.steps, isEmpty);
      expect(result.ok, isTrue); // blocked is not a failure
      expect(ran, isFalse);
    });

    test('a window that wraps midnight and a matching weekday both hold', () async {
      final engine = AutomationEngine(
        HandlerRegistry()..register(CallbackActionHandler(type: 'ok', onRun: (_) async => '')),
        // Friday 2026-01-02, 23:30 -- inside a 22:00..06:00 window.
        conditionEvaluator: ConditionEvaluator(now: () => DateTime(2026, 1, 2, 23, 30)),
      );
      final result = await engine.run(Automation.create(
        name: 't',
        trigger: const ManualTrigger(),
        conditions: const [
          TimeWindowCondition(startHour: 22, startMinute: 0, endHour: 6, endMinute: 0),
          WeekdayCondition(weekdays: {5}), // Fri
        ],
        actions: const [UnknownAction({'type': 'ok'})],
      ));
      expect(result.conditionsMet, isTrue);
      expect(result.steps.single.outcome, StepOutcome.ok);
    });
  });

  group('branch / variables', () {
    test('set_variable then a branch reads it back and takes the true side', () async {
      final log = <String>[];
      final registry = HandlerRegistry()
        ..register(CallbackActionHandler(
          type: 'log',
          onRun: (a) async {
            log.add((a as UnknownAction).raw['label'] as String);
            return '';
          },
        ));
      final engine = AutomationEngine(registry);

      await engine.run(Automation.create(
        name: 't',
        trigger: const ManualTrigger(),
        actions: [
          const SetVariableAction(name: 'level', value: 5),
          BranchAction(
            condition: const VariableCondition(
              name: 'level',
              op: VariableOp.greaterThan,
              value: 3,
            ),
            then: const [UnknownAction({'type': 'log', 'label': 'high'})],
            otherwise: const [UnknownAction({'type': 'log', 'label': 'low'})],
          ),
        ],
      ));

      expect(log, ['high']);
    });

    test('an unset variable takes the false side, and a branch can nest', () async {
      final log = <String>[];
      final registry = HandlerRegistry()
        ..register(CallbackActionHandler(
          type: 'log',
          onRun: (a) async {
            log.add((a as UnknownAction).raw['label'] as String);
            return '';
          },
        ));
      final engine = AutomationEngine(registry);

      await engine.run(Automation.create(
        name: 't',
        trigger: const ManualTrigger(),
        actions: [
          BranchAction(
            condition: const VariableCondition(name: 'missing', op: VariableOp.isSet),
            then: const [UnknownAction({'type': 'log', 'label': 'unreachable'})],
            otherwise: [
              const SetVariableAction(name: 'nested', value: 'yes'),
              BranchAction(
                condition: const VariableCondition(
                  name: 'nested',
                  op: VariableOp.equals,
                  value: 'yes',
                ),
                then: const [UnknownAction({'type': 'log', 'label': 'inner'})],
              ),
            ],
          ),
        ],
      ));

      expect(log, ['inner']);
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
