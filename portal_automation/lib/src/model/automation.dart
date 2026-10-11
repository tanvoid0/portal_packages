import 'package:meta/meta.dart';
import 'package:uuid/uuid.dart';

import 'action.dart';
import 'trigger.dart';

const _uuid = Uuid();

/// A routine: one [trigger] plus an ordered list of [actions] the device runs
/// when the trigger fires.
@immutable
class Automation {
  const Automation({
    required this.id,
    required this.name,
    required this.trigger,
    this.actions = const [],
    this.enabled = true,
    required this.createdAt,
    required this.updatedAt,
  });

  /// New routine with a generated id and timestamps.
  factory Automation.create({
    required String name,
    required Trigger trigger,
    List<AutomationAction> actions = const [],
    bool enabled = true,
  }) {
    final now = DateTime.now().toUtc();
    return Automation(
      id: _uuid.v4(),
      name: name,
      trigger: trigger,
      actions: actions,
      enabled: enabled,
      createdAt: now,
      updatedAt: now,
    );
  }

  final String id;
  final String name;
  final bool enabled;
  final Trigger trigger;
  final List<AutomationAction> actions;
  final DateTime createdAt;
  final DateTime updatedAt;

  Automation copyWith({
    String? name,
    bool? enabled,
    Trigger? trigger,
    List<AutomationAction>? actions,
  }) =>
      Automation(
        id: id,
        name: name ?? this.name,
        enabled: enabled ?? this.enabled,
        trigger: trigger ?? this.trigger,
        actions: actions ?? this.actions,
        createdAt: createdAt,
        updatedAt: DateTime.now().toUtc(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'enabled': enabled,
        'trigger': trigger.toJson(),
        'actions': [for (final a in actions) a.toJson()],
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory Automation.fromJson(Map<String, dynamic> json) => Automation(
        id: json['id'] as String? ?? _uuid.v4(),
        name: json['name'] as String? ?? '',
        enabled: json['enabled'] as bool? ?? true,
        trigger: Trigger.fromJson(
          Map<String, dynamic>.from(json['trigger'] as Map? ?? const {}),
        ),
        actions: [
          for (final a in (json['actions'] as List? ?? const []))
            AutomationAction.fromJson(Map<String, dynamic>.from(a as Map)),
        ],
        // The Portal server serialises snake_case (`created_at`); the local
        // cache round-trips camelCase. Accept either so a server read keeps
        // real timestamps instead of silently resetting them to now() — which
        // would defeat the newest-wins rule in AutomationRepository.updatedAt.
        createdAt: _parseDate(json['createdAt'] ?? json['created_at']),
        updatedAt: _parseDate(json['updatedAt'] ?? json['updated_at']),
      );

  static DateTime _parseDate(Object? raw) =>
      DateTime.tryParse(raw as String? ?? '')?.toUtc() ?? DateTime.now().toUtc();
}
