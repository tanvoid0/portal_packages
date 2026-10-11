/// Trigger-to-action automation engine for Portal apps.
///
/// A [Automation] (routine) is one [Trigger] plus an ordered list of
/// [AutomationAction]s. [AutomationEngine] runs the actions through a
/// [HandlerRegistry]; the host app wires handlers — [ServerCallHandler] in
/// this package, and [CallbackActionHandler]s for notifications, the assistant
/// and the [NativeAutomationBridge] (device settings / triggers).
///
/// The engine is pure Dart and reusable: portal_assistant, the Routines app,
/// or any Portal app can build one and register its own handlers.
library;

export 'src/model/automation.dart';
export 'src/model/trigger.dart';
export 'src/model/condition.dart';
export 'src/model/action.dart';
export 'src/model/run_log.dart';

export 'src/engine/availability.dart';
export 'src/engine/action_handler.dart';
export 'src/engine/automation_engine.dart';
export 'src/engine/condition_evaluator.dart';
export 'src/engine/server_call_handler.dart';

export 'src/native/native_automation_bridge.dart';

export 'src/data/automation_repository.dart';
export 'src/data/run_log_store.dart';
