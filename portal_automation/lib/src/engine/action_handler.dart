import '../model/action.dart';
import 'availability.dart';

/// Runs one kind of [AutomationAction]. One handler per [type].
///
/// The engine only ever sees this interface, which keeps actions as *data*:
/// adding a new action kind is one handler and one registry entry, not a new
/// branch in the executor.
abstract class ActionHandler {
  /// The [AutomationAction.type] this handler runs.
  String get type;

  /// Whether this action can run now. Default [Ready]; override for handlers
  /// gated on a permission or device capability.
  Future<Availability> availability(AutomationAction action) async =>
      const Ready();

  /// Perform the action. Returns a short human line for the run log. Throws on
  /// failure — the engine records it, never swallows it.
  Future<String> run(AutomationAction action);
}

/// Builds a handler from callbacks, so the host app wires a real dependency
/// (notifications, the assistant, the native bridge) without this package
/// importing it.
class CallbackActionHandler extends ActionHandler {
  CallbackActionHandler({
    required this.type,
    required Future<String> Function(AutomationAction action) onRun,
    Future<Availability> Function(AutomationAction action)? onAvailability,
  })  : _run = onRun,
        _availability = onAvailability;

  @override
  final String type;
  final Future<String> Function(AutomationAction action) _run;
  final Future<Availability> Function(AutomationAction action)? _availability;

  @override
  Future<Availability> availability(AutomationAction action) =>
      _availability?.call(action) ?? Future.value(const Ready());

  @override
  Future<String> run(AutomationAction action) => _run(action);
}

/// The set of handlers an engine can run. Unknown action types resolve to
/// null and the engine records a failed step rather than crashing a run.
class HandlerRegistry {
  final _byType = <String, ActionHandler>{};

  void register(ActionHandler handler) => _byType[handler.type] = handler;

  void registerAll(Iterable<ActionHandler> handlers) {
    for (final h in handlers) {
      register(h);
    }
  }

  ActionHandler? find(String type) => _byType[type];

  Iterable<String> get types => _byType.keys;
}
