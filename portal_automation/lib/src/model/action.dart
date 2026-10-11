import 'package:meta/meta.dart';

import 'condition.dart';

/// One step a routine runs. Steps run in order; see `AutomationEngine`.
///
/// Sealed with a `type` discriminator, same survival rule as `Trigger`: an
/// unknown `type` decodes to [UnknownAction] and round-trips untouched rather
/// than throwing.
@immutable
sealed class AutomationAction {
  const AutomationAction();

  String get type;

  Map<String, dynamic> toJson();

  static AutomationAction fromJson(Map<String, dynamic> json) {
    switch (json['type']) {
      case NotifyAction.kind:
        return NotifyAction.fromJson(json);
      case DeepLinkAction.kind:
        return DeepLinkAction.fromJson(json);
      case ServerCallAction.kind:
        return ServerCallAction.fromJson(json);
      case AssistantPromptAction.kind:
        return AssistantPromptAction.fromJson(json);
      case DeviceSettingAction.kind:
        return DeviceSettingAction.fromJson(json);
      case SetVariableAction.kind:
        return SetVariableAction.fromJson(json);
      case BranchAction.kind:
        return BranchAction.fromJson(json);
      case SetAlarmAction.kind:
        return SetAlarmAction.fromJson(json);
      default:
        return UnknownAction(json);
    }
  }
}

/// Stores a value under [name] for the rest of this run -- read back by a
/// later [BranchAction]'s [VariableCondition], or by another step's handler.
/// Scoped to one run: nothing persists between runs. Handled by the engine
/// itself, not a registered [ActionHandler] -- it mutates run state no host
/// handler can see.
class SetVariableAction extends AutomationAction {
  const SetVariableAction({required this.name, this.value});
  static const kind = 'set_variable';

  final String name;
  final Object? value;

  @override
  String get type => kind;

  @override
  Map<String, dynamic> toJson() =>
      {'type': kind, 'name': name, if (value != null) 'value': value};

  factory SetVariableAction.fromJson(Map<String, dynamic> json) =>
      SetVariableAction(name: json['name'] as String? ?? '', value: json['value']);
}

/// Runs [then] if [condition] holds, otherwise [otherwise]. Nests like a
/// routine's own action list -- a branch's steps can include another branch.
/// Handled by the engine itself, which recurses the same way it runs the top
/// level and flattens the chosen side's steps into the run's step list.
class BranchAction extends AutomationAction {
  const BranchAction({
    required this.condition,
    this.then = const [],
    this.otherwise = const [],
  });
  static const kind = 'branch';

  final Condition condition;
  final List<AutomationAction> then;
  final List<AutomationAction> otherwise;

  @override
  String get type => kind;

  @override
  Map<String, dynamic> toJson() => {
        'type': kind,
        'condition': condition.toJson(),
        'then': [for (final a in then) a.toJson()],
        'otherwise': [for (final a in otherwise) a.toJson()],
      };

  factory BranchAction.fromJson(Map<String, dynamic> json) => BranchAction(
        condition: Condition.fromJson(
          Map<String, dynamic>.from(json['condition'] as Map? ?? const {}),
        ),
        then: [
          for (final a in (json['then'] as List? ?? const []))
            AutomationAction.fromJson(Map<String, dynamic>.from(a as Map)),
        ],
        otherwise: [
          for (final a in (json['otherwise'] as List? ?? const []))
            AutomationAction.fromJson(Map<String, dynamic>.from(a as Map)),
        ],
      );
}

/// Posts a local notification. Handler injected by the host (portal_notifications).
class NotifyAction extends AutomationAction {
  const NotifyAction({required this.title, this.body = ''});
  static const kind = 'notify';

  final String title;
  final String body;

  @override
  String get type => kind;

  @override
  Map<String, dynamic> toJson() =>
      {'type': kind, 'title': title, if (body.isNotEmpty) 'body': body};

  factory NotifyAction.fromJson(Map<String, dynamic> json) => NotifyAction(
        title: json['title'] as String? ?? '',
        body: json['body'] as String? ?? '',
      );
}

/// Opens a Portal deep link (another app, or a screen in this one). Handler
/// injected by the host (portal_platform's deep-link service).
class DeepLinkAction extends AutomationAction {
  const DeepLinkAction({required this.uri});
  static const kind = 'deep_link';

  final String uri;

  @override
  String get type => kind;

  @override
  Map<String, dynamic> toJson() => {'type': kind, 'uri': uri};

  factory DeepLinkAction.fromJson(Map<String, dynamic> json) =>
      DeepLinkAction(uri: json['uri'] as String? ?? '');
}

/// Calls a Portal server route with the app's authenticated client — the main
/// way a routine acts on another Portal app (create a task, log a workout…).
/// Handled in-package by `ServerCallHandler`.
class ServerCallAction extends AutomationAction {
  const ServerCallAction({
    required this.path,
    this.method = 'POST',
    this.body = const {},
  });
  static const kind = 'server_call';

  /// Module-relative path, e.g. `task/tasks`. Resolved against the API base.
  final String path;

  /// GET / POST / PUT / DELETE (case-insensitive).
  final String method;
  final Map<String, dynamic> body;

  @override
  String get type => kind;

  @override
  Map<String, dynamic> toJson() => {
        'type': kind,
        'path': path,
        'method': method,
        if (body.isNotEmpty) 'body': body,
      };

  factory ServerCallAction.fromJson(Map<String, dynamic> json) =>
      ServerCallAction(
        path: json['path'] as String? ?? '',
        method: json['method'] as String? ?? 'POST',
        body: Map<String, dynamic>.from(json['body'] as Map? ?? const {}),
      );
}

/// Runs a prompt through the in-app assistant. Handler injected by the host
/// (portal_ai's `AiAgent`).
class AssistantPromptAction extends AutomationAction {
  const AssistantPromptAction({required this.prompt});
  static const kind = 'assistant_prompt';

  final String prompt;

  @override
  String get type => kind;

  @override
  Map<String, dynamic> toJson() => {'type': kind, 'prompt': prompt};

  factory AssistantPromptAction.fromJson(Map<String, dynamic> json) =>
      AssistantPromptAction(prompt: json['prompt'] as String? ?? '');
}

/// Toggles a device setting (DND, brightness, greyscale, power-saver…).
/// Handled by the native bridge; [setting] is a bridge-known key.
class DeviceSettingAction extends AutomationAction {
  const DeviceSettingAction({required this.setting, this.value});
  static const kind = 'device_setting';

  final String setting;
  final Object? value;

  @override
  String get type => kind;

  @override
  Map<String, dynamic> toJson() =>
      {'type': kind, 'setting': setting, if (value != null) 'value': value};

  factory DeviceSettingAction.fromJson(Map<String, dynamic> json) =>
      DeviceSettingAction(
        setting: json['setting'] as String? ?? '',
        value: json['value'],
      );
}

/// What [SetAlarmAction] does to the alarm it names: arm it, disarm it, or
/// skip just its next occurrence (it re-arms normally after that one fires).
enum SetAlarmMode { arm, skipNext, disarm }

/// Arms, disarms, or skips the next ring of a Smart Alarm (app-level, not in
/// this package -- the host's handler looks [alarmId] up in its own alarm
/// store). Lets a routine's trigger/condition control an alarm, e.g. a
/// geofence "arrive home" arming the "Work" alarm.
class SetAlarmAction extends AutomationAction {
  const SetAlarmAction({required this.alarmId, required this.mode});
  static const kind = 'set_alarm';

  final String alarmId;
  final SetAlarmMode mode;

  @override
  String get type => kind;

  @override
  Map<String, dynamic> toJson() =>
      {'type': kind, 'alarmId': alarmId, 'mode': mode.name};

  factory SetAlarmAction.fromJson(Map<String, dynamic> json) => SetAlarmAction(
        alarmId: json['alarmId'] as String? ?? '',
        mode: SetAlarmMode.values.firstWhere(
          (m) => m.name == json['mode'],
          orElse: () => SetAlarmMode.arm,
        ),
      );
}

/// An action kind this build does not understand. Round-trips the raw JSON.
class UnknownAction extends AutomationAction {
  const UnknownAction(this.raw);
  final Map<String, dynamic> raw;

  @override
  String get type => raw['type'] as String? ?? 'unknown';

  @override
  Map<String, dynamic> toJson() => raw;
}
