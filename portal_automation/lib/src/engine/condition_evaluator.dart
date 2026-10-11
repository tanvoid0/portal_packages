import '../model/condition.dart';

/// Checks whether a [Condition] currently holds. [TimeWindowCondition] and
/// [WeekdayCondition] are pure (answered from the clock alone); a
/// [DeviceStateCondition] needs a live device snapshot, which only the host
/// app (via its native bridge) can supply — inject one via [deviceStateCheck].
///
/// A [DeviceStateCondition] with no [deviceStateCheck] passes (true): a
/// routine should not silently stop firing just because this build's host
/// did not wire the snapshot seam yet.
class ConditionEvaluator {
  const ConditionEvaluator({this.deviceStateCheck, this.now});

  /// Returns whether the given device-state kind+args currently holds.
  final Future<bool> Function(DeviceStateCondition condition)? deviceStateCheck;

  /// Override for tests; defaults to [DateTime.now].
  final DateTime Function()? now;

  Future<bool> evaluate(
    Condition condition, {
    Map<String, Object?> variables = const {},
  }) async {
    final time = (now ?? DateTime.now)();
    return switch (condition) {
      TimeWindowCondition() => condition.holdsAt(time),
      WeekdayCondition() => condition.holdsAt(time),
      DeviceStateCondition() =>
        deviceStateCheck == null ? true : await deviceStateCheck!(condition),
      VariableCondition() => condition.holdsFor(variables[condition.name]),
      UnknownCondition() => true,
    };
  }

  Future<bool> evaluateAll(
    List<Condition> conditions, {
    Map<String, Object?> variables = const {},
  }) async {
    for (final condition in conditions) {
      if (!await evaluate(condition, variables: variables)) return false;
    }
    return true;
  }
}
