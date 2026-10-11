import 'package:meta/meta.dart';

import 'trigger.dart' show DeviceStateKind;

/// A gate an [Automation] checks before it runs its actions. All of
/// [Automation.conditions] must hold ("AND") — no condition at all means the
/// trigger alone decides.
///
/// Same survival rule as [Trigger]/[AutomationAction]: an unrecognised `type`
/// decodes to [UnknownCondition] and evaluates as **true** (non-blocking) —
/// a client that predates a new condition kind should not silently stop every
/// routine that uses it.
@immutable
sealed class Condition {
  const Condition();

  String get type;

  Map<String, dynamic> toJson();

  static Condition fromJson(Map<String, dynamic> json) {
    switch (json['type']) {
      case TimeWindowCondition.kind:
        return TimeWindowCondition.fromJson(json);
      case WeekdayCondition.kind:
        return WeekdayCondition.fromJson(json);
      case DeviceStateCondition.kind:
        return DeviceStateCondition.fromJson(json);
      case VariableCondition.kind:
        return VariableCondition.fromJson(json);
      default:
        return UnknownCondition(json);
    }
  }
}

/// Compares a run-scoped variable (set by `SetVariableAction` earlier in the
/// same run) against a literal. Missing/unset reads as `null`.
enum VariableOp { equals, notEquals, greaterThan, lessThan, contains, isSet }

class VariableCondition extends Condition {
  const VariableCondition({
    required this.name,
    required this.op,
    this.value,
  });
  static const kind = 'variable';

  final String name;
  final VariableOp op;

  /// Unused for [VariableOp.isSet].
  final Object? value;

  /// Evaluated by the engine, which holds the run's variable map -- this
  /// class only carries the comparison, same split as [DeviceStateCondition].
  bool holdsFor(Object? current) => switch (op) {
        VariableOp.isSet => current != null,
        VariableOp.equals => current == value,
        VariableOp.notEquals => current != value,
        VariableOp.contains =>
          current != null && '$current'.contains('$value'),
        VariableOp.greaterThan => _compare(current, value) > 0,
        VariableOp.lessThan => _compare(current, value) < 0,
      };

  static num _compare(Object? a, Object? b) {
    final an = a is num ? a : num.tryParse('$a');
    final bn = b is num ? b : num.tryParse('$b');
    if (an == null || bn == null) return 0;
    return (an - bn).sign;
  }

  @override
  String get type => kind;

  @override
  Map<String, dynamic> toJson() => {
        'type': kind,
        'name': name,
        'op': op.name,
        if (value != null) 'value': value,
      };

  factory VariableCondition.fromJson(Map<String, dynamic> json) =>
      VariableCondition(
        name: json['name'] as String? ?? '',
        op: VariableOp.values.firstWhere(
          (o) => o.name == json['op'],
          orElse: () => VariableOp.isSet,
        ),
        value: json['value'],
      );
}

/// True while the current time of day is within [startHour]:[startMinute] ..
/// [endHour]:[endMinute], inclusive of the start and exclusive of the end.
/// A window that wraps past midnight (e.g. 22:00..06:00) is supported.
class TimeWindowCondition extends Condition {
  const TimeWindowCondition({
    required this.startHour,
    required this.startMinute,
    required this.endHour,
    required this.endMinute,
  });
  static const kind = 'time_window';

  final int startHour;
  final int startMinute;
  final int endHour;
  final int endMinute;

  bool holdsAt(DateTime time) {
    final minuteOfDay = time.hour * 60 + time.minute;
    final start = startHour * 60 + startMinute;
    final end = endHour * 60 + endMinute;
    if (start == end) return true; // zero-width window = always on
    if (start < end) return minuteOfDay >= start && minuteOfDay < end;
    return minuteOfDay >= start || minuteOfDay < end; // wraps midnight
  }

  @override
  String get type => kind;

  @override
  Map<String, dynamic> toJson() => {
        'type': kind,
        'startHour': startHour,
        'startMinute': startMinute,
        'endHour': endHour,
        'endMinute': endMinute,
      };

  factory TimeWindowCondition.fromJson(Map<String, dynamic> json) =>
      TimeWindowCondition(
        startHour: (json['startHour'] as num?)?.toInt() ?? 0,
        startMinute: (json['startMinute'] as num?)?.toInt() ?? 0,
        endHour: (json['endHour'] as num?)?.toInt() ?? 23,
        endMinute: (json['endMinute'] as num?)?.toInt() ?? 59,
      );
}

/// True on the given days (1=Mon .. 7=Sun). Empty set means every day.
class WeekdayCondition extends Condition {
  const WeekdayCondition({required this.weekdays});
  static const kind = 'weekday';

  final Set<int> weekdays;

  bool holdsAt(DateTime time) => weekdays.isEmpty || weekdays.contains(time.weekday);

  @override
  String get type => kind;

  @override
  Map<String, dynamic> toJson() =>
      {'type': kind, 'weekdays': (weekdays.toList()..sort())};

  factory WeekdayCondition.fromJson(Map<String, dynamic> json) =>
      WeekdayCondition(
        weekdays: {
          for (final d in (json['weekdays'] as List? ?? const []))
            (d as num).toInt(),
        },
      );
}

/// True while a device-state kind currently holds (not just "becoming true"
/// like [DeviceStateTrigger] — this reads the live snapshot). Needs a host
/// (the app's native bridge) to supply the current value; the engine's
/// `ConditionEvaluator` is the seam.
class DeviceStateCondition extends Condition {
  const DeviceStateCondition({required this.state, this.args = const {}});
  static const kind = 'device_state';

  final DeviceStateKind state;
  final Map<String, dynamic> args;

  @override
  String get type => kind;

  @override
  Map<String, dynamic> toJson() => {
        'type': kind,
        'state': state.name,
        if (args.isNotEmpty) 'args': args,
      };

  factory DeviceStateCondition.fromJson(Map<String, dynamic> json) =>
      DeviceStateCondition(
        state: DeviceStateKind.values.firstWhere(
          (k) => k.name == json['state'],
          orElse: () => DeviceStateKind.charging,
        ),
        args: Map<String, dynamic>.from(json['args'] as Map? ?? const {}),
      );
}

/// A condition kind this build does not understand. Round-trips the raw JSON
/// and evaluates as true (see class doc on [Condition]).
class UnknownCondition extends Condition {
  const UnknownCondition(this.raw);
  final Map<String, dynamic> raw;

  @override
  String get type => raw['type'] as String? ?? 'unknown';

  @override
  Map<String, dynamic> toJson() => raw;
}
