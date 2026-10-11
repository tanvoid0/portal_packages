import '../model/automation.dart';
import '../model/run_log.dart';
import 'action_handler.dart';
import 'availability.dart';

/// Runs a routine's actions in order.
///
/// Each step is independent: an action that is unavailable is **skipped** and
/// one that throws is recorded as **failed**, and the run continues either
/// way. Nothing is swallowed — every outcome lands in the [RunResult], and
/// [onRunComplete] lets the host surface a failure (a notification, a log
/// entry) instead of a routine that silently did nothing.
class AutomationEngine {
  AutomationEngine(this.registry, {this.onRunComplete});

  final HandlerRegistry registry;
  final void Function(RunResult result)? onRunComplete;

  Future<RunResult> run(Automation automation) async {
    final steps = <StepResult>[];

    for (final action in automation.actions) {
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

    final result = RunResult(
      automationId: automation.id,
      ranAt: DateTime.now().toUtc(),
      steps: steps,
    );
    onRunComplete?.call(result);
    return result;
  }
}
