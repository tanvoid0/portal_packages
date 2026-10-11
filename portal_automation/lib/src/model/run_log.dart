import 'package:meta/meta.dart';

import 'action.dart';
import '../engine/availability.dart';

/// How one step of a run ended.
enum StepOutcome { ok, skipped, failed }

/// The result of running one [AutomationAction].
@immutable
class StepResult {
  const StepResult({
    required this.actionType,
    required this.outcome,
    this.message = '',
  });

  factory StepResult.ok(AutomationAction a, String message) =>
      StepResult(actionType: a.type, outcome: StepOutcome.ok, message: message);

  /// The handler reported the action cannot run (missing permission / support).
  factory StepResult.skipped(AutomationAction a, Availability why) => StepResult(
        actionType: a.type,
        outcome: StepOutcome.skipped,
        message: switch (why) {
          Ready() => '',
          NeedsPermission(:final explanation) => explanation,
          Unsupported(:final reason) => reason,
        },
      );

  factory StepResult.failed(AutomationAction a, String message) => StepResult(
        actionType: a.type,
        outcome: StepOutcome.failed,
        message: message,
      );

  final String actionType;
  final StepOutcome outcome;
  final String message;

  Map<String, dynamic> toJson() => {
        'actionType': actionType,
        'outcome': outcome.name,
        if (message.isNotEmpty) 'message': message,
      };
}

/// The result of running a whole routine.
@immutable
class RunResult {
  const RunResult({
    required this.automationId,
    required this.ranAt,
    required this.steps,
  });

  final String automationId;
  final DateTime ranAt;
  final List<StepResult> steps;

  /// True when no step failed. A skipped step (unavailable) is not a failure.
  bool get ok => steps.every((s) => s.outcome != StepOutcome.failed);

  int get failedCount =>
      steps.where((s) => s.outcome == StepOutcome.failed).length;

  Map<String, dynamic> toJson() => {
        'automationId': automationId,
        'ranAt': ranAt.toIso8601String(),
        'ok': ok,
        'steps': [for (final s in steps) s.toJson()],
      };
}
