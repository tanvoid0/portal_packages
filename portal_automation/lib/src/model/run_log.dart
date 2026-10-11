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

  factory StepResult.fromJson(Map<String, dynamic> json) => StepResult(
        actionType: json['actionType'] as String? ?? '',
        outcome: StepOutcome.values.byName(json['outcome'] as String? ?? 'ok'),
        message: json['message'] as String? ?? '',
      );
}

/// The result of running a whole routine.
@immutable
class RunResult {
  const RunResult({
    required this.automationId,
    required this.automationName,
    required this.ranAt,
    required this.steps,
    this.conditionsMet = true,
  });

  final String automationId;

  /// The routine's name at the time it ran -- a snapshot, so history still
  /// reads right after the routine is renamed or deleted.
  final String automationName;
  final DateTime ranAt;
  final List<StepResult> steps;

  /// False when a condition blocked the run -- [steps] is then empty; this is
  /// what distinguishes "didn't run, gate closed" from "ran zero actions".
  final bool conditionsMet;

  /// True when no step failed. A skipped step (unavailable), or a run a
  /// condition blocked before any step started, is not a failure.
  bool get ok => steps.every((s) => s.outcome != StepOutcome.failed);

  int get failedCount =>
      steps.where((s) => s.outcome == StepOutcome.failed).length;

  Map<String, dynamic> toJson() => {
        'automationId': automationId,
        'automationName': automationName,
        'ranAt': ranAt.toIso8601String(),
        'ok': ok,
        'conditionsMet': conditionsMet,
        'steps': [for (final s in steps) s.toJson()],
      };

  factory RunResult.fromJson(Map<String, dynamic> json) => RunResult(
        automationId: json['automationId'] as String? ?? '',
        automationName: json['automationName'] as String? ?? '',
        ranAt: DateTime.tryParse(json['ranAt'] as String? ?? '') ??
            DateTime.now().toUtc(),
        conditionsMet: json['conditionsMet'] as bool? ?? true,
        steps: [
          for (final s in (json['steps'] as List? ?? const []))
            StepResult.fromJson(Map<String, dynamic>.from(s as Map)),
        ],
      );
}
