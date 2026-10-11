import '../model/action.dart';
import '../model/automation.dart';
import '../model/run_log.dart';
import 'action_handler.dart';
import 'availability.dart';
import 'condition_evaluator.dart';

/// Runs a routine's actions in order, after checking its conditions.
///
/// Conditions gate as a group: any one unmet skips the whole run before any
/// action starts (nothing half-runs). Each action step is then independent:
/// one that is unavailable is **skipped** and one that throws is recorded as
/// **failed**, and the run continues either way. Nothing is swallowed —
/// every outcome lands in the [RunResult], and [onRunComplete] lets the host
/// surface a failure (a notification, a log entry) instead of a routine that
/// silently did nothing.
class AutomationEngine {
  AutomationEngine(
    this.registry, {
    this.onRunComplete,
    ConditionEvaluator? conditionEvaluator,
  }) : conditionEvaluator = conditionEvaluator ?? const ConditionEvaluator();

  final HandlerRegistry registry;
  final ConditionEvaluator conditionEvaluator;
  final void Function(RunResult result)? onRunComplete;

  Future<RunResult> run(Automation automation) async {
    if (!await conditionEvaluator.evaluateAll(automation.conditions)) {
      final result = RunResult(
        automationId: automation.id,
        automationName: automation.name,
        ranAt: DateTime.now().toUtc(),
        steps: const [],
        conditionsMet: false,
      );
      onRunComplete?.call(result);
      return result;
    }

    final steps = <StepResult>[];
    // Scoped to this run -- `SetVariableAction` writes here, a `BranchAction`
    // reads it via a `VariableCondition`. Nothing persists between runs.
    final variables = <String, Object?>{};
    await _runActions(automation.actions, variables, steps);

    final result = RunResult(
      automationId: automation.id,
      automationName: automation.name,
      ranAt: DateTime.now().toUtc(),
      steps: steps,
    );
    onRunComplete?.call(result);
    return result;
  }

  /// Runs [actions] in order, appending to [steps]. `set_variable` and
  /// `branch` are handled here rather than through [registry] -- they need
  /// this run's [variables] and the ability to recurse, which a host-supplied
  /// [ActionHandler] cannot reach.
  Future<void> _runActions(
    List<AutomationAction> actions,
    Map<String, Object?> variables,
    List<StepResult> steps,
  ) async {
    for (final action in actions) {
      if (action is SetVariableAction) {
        variables[action.name] = action.value;
        steps.add(StepResult.ok(action, 'set'));
        continue;
      }
      if (action is BranchAction) {
        final holds = await conditionEvaluator.evaluate(
          action.condition,
          variables: variables,
        );
        await _runActions(holds ? action.then : action.otherwise, variables, steps);
        continue;
      }

      final handler = registry.find(action.type);
      if (handler == null) {
        steps.add(StepResult.failed(action, 'no handler for "${action.type}"'));
        continue;
      }

      final availability = await handler.availability(action);
      if (availability is! Ready) {
        steps.add(StepResult.skipped(action, availability));
        continue;
      }

      try {
        final message = await handler.run(action);
        steps.add(StepResult.ok(action, message));
      } catch (e) {
        steps.add(StepResult.failed(action, '$e'));
      }
    }
  }
}
