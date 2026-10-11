import 'package:meta/meta.dart';

/// What makes a routine run.
///
/// Sealed: each variant carries a `type` discriminator so a stored definition
/// survives a reload and a schema rename. An unrecognised `type` decodes to
/// [UnknownTrigger] rather than throwing — a client that predates a new
/// trigger kind round-trips it untouched instead of losing the routine, the
/// same rule the assistant's `AiBlock.fromJson` uses.
@immutable
sealed class Trigger {
  const Trigger();

  /// Stable wire discriminator.
  String get type;

  Map<String, dynamic> toJson();

  static Trigger fromJson(Map<String, dynamic> json) {
    switch (json['type']) {
      case ManualTrigger.kind:
        return const ManualTrigger();
      case TimeTrigger.kind:
        return TimeTrigger.fromJson(json);
      case DeviceStateTrigger.kind:
        return DeviceStateTrigger.fromJson(json);
      case GeofenceTrigger.kind:
        return GeofenceTrigger.fromJson(json);
      case NfcTrigger.kind:
        return NfcTrigger.fromJson(json);
      default:
        return UnknownTrigger(json);
    }
  }
}

/// Runs only when the user taps "run" (or via a quick-settings tile / the
/// assistant). No arming, no background wake — the baseline every app gets.
class ManualTrigger extends Trigger {
  const ManualTrigger();
  static const kind = 'manual';

  @override
  String get type => kind;

  @override
  Map<String, dynamic> toJson() => {'type': kind};
}

/// Fires at a time of day, on the given [weekdays] (1=Mon .. 7=Sun; empty =
/// every day), or once at [oneShotEpochMs] if set.
class TimeTrigger extends Trigger {
  const TimeTrigger({
    required this.hour,
    required this.minute,
    this.weekdays = const {},
    this.oneShotEpochMs,
  });
  static const kind = 'time';

  final int hour; // 0-23
  final int minute; // 0-59
  final Set<int> weekdays;
  final int? oneShotEpochMs;

  bool get isOneShot => oneShotEpochMs != null;

  @override
  String get type => kind;

  @override
  Map<String, dynamic> toJson() => {
        'type': kind,
        'hour': hour,
        'minute': minute,
        'weekdays': (weekdays.toList()..sort()),
        if (oneShotEpochMs != null) 'oneShotEpochMs': oneShotEpochMs,
      };

  factory TimeTrigger.fromJson(Map<String, dynamic> json) => TimeTrigger(
        hour: (json['hour'] as num?)?.toInt() ?? 0,
        minute: (json['minute'] as num?)?.toInt() ?? 0,
        weekdays: {
          for (final d in (json['weekdays'] as List? ?? const []))
            (d as num).toInt(),
        },
        oneShotEpochMs: (json['oneShotEpochMs'] as num?)?.toInt(),
      );
}

/// A device condition becoming true: charging started, battery dropped below a
/// threshold, wifi connected, DND turned on, etc. Armed by the native bridge.
enum DeviceStateKind {
  charging,
  unplugged,
  batteryBelow,
  wifiConnected,
  wifiDisconnected,
  bluetoothConnected,
  headphonesConnected,
  dndEnabled,
}

class DeviceStateTrigger extends Trigger {
  const DeviceStateTrigger({required this.state, this.args = const {}});
  static const kind = 'device_state';

  final DeviceStateKind state;

  /// Per-kind parameters, e.g. `{'threshold': 20}` for [DeviceStateKind.batteryBelow]
  /// or `{'ssid': 'home'}` for wifi.
  final Map<String, dynamic> args;

  @override
  String get type => kind;

  @override
  Map<String, dynamic> toJson() => {
        'type': kind,
        'state': state.name,
        if (args.isNotEmpty) 'args': args,
      };

  factory DeviceStateTrigger.fromJson(Map<String, dynamic> json) =>
      DeviceStateTrigger(
        state: DeviceStateKind.values.firstWhere(
          (k) => k.name == json['state'],
          orElse: () => DeviceStateKind.charging,
        ),
        args: Map<String, dynamic>.from(json['args'] as Map? ?? const {}),
      );
}

/// Fires on entering or leaving a circular region. Armed by the native bridge;
/// needs background-location permission.
class GeofenceTrigger extends Trigger {
  const GeofenceTrigger({
    required this.latitude,
    required this.longitude,
    required this.radiusMeters,
    this.onEnter = true,
  });
  static const kind = 'geofence';

  final double latitude;
  final double longitude;
  final double radiusMeters;

  /// True = fire on enter, false = fire on exit.
  final bool onEnter;

  @override
  String get type => kind;

  @override
  Map<String, dynamic> toJson() => {
        'type': kind,
        'latitude': latitude,
        'longitude': longitude,
        'radiusMeters': radiusMeters,
        'onEnter': onEnter,
      };

  factory GeofenceTrigger.fromJson(Map<String, dynamic> json) => GeofenceTrigger(
        latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
        longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
        radiusMeters: (json['radiusMeters'] as num?)?.toDouble() ?? 100,
        onEnter: json['onEnter'] as bool? ?? true,
      );
}

/// Fires when a specific NFC tag is tapped. [tagId] is matched against the
/// tag's serial; empty means "any tag".
class NfcTrigger extends Trigger {
  const NfcTrigger({this.tagId = ''});
  static const kind = 'nfc';

  final String tagId;

  @override
  String get type => kind;

  @override
  Map<String, dynamic> toJson() => {
        'type': kind,
        if (tagId.isNotEmpty) 'tagId': tagId,
      };

  factory NfcTrigger.fromJson(Map<String, dynamic> json) =>
      NfcTrigger(tagId: json['tagId'] as String? ?? '');
}

/// A trigger kind this build does not understand. Holds the raw JSON so the
/// routine round-trips intact instead of being dropped on load.
class UnknownTrigger extends Trigger {
  const UnknownTrigger(this.raw);
  final Map<String, dynamic> raw;

  @override
  String get type => raw['type'] as String? ?? 'unknown';

  @override
  Map<String, dynamic> toJson() => raw;
}
