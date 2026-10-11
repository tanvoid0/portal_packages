import '../model/action.dart';
import '../model/automation.dart';
import '../model/trigger.dart';
import '../engine/availability.dart';

/// The seam to Android for everything a pure-Dart engine cannot do: arming
/// device/geofence/NFC triggers to wake the app in the background, and
/// applying device-setting actions (DND, brightness…).
///
/// The package declares this interface; an app provides the concrete
/// implementation (a MethodChannel to its Kotlin plugin). The engine and the
/// callback handlers depend only on this, so an app with no device needs —
/// portal_assistant running routines of server calls and prompts — wires no
/// native code at all.
///
/// Implementations land in M2+ (device state), M3 (geofence), M4 (NFC). M1
/// ships only time/manual triggers, which need no bridge.
abstract class NativeAutomationBridge {
  /// Whether [trigger] can be armed on this device right now.
  Future<Availability> triggerAvailability(Trigger trigger);

  /// Register [automation]'s trigger so the OS wakes the app when it fires.
  /// Idempotent: arming an already-armed routine re-registers it cleanly.
  Future<void> arm(Automation automation);

  /// Remove a previously armed trigger. Idempotent.
  Future<void> disarm(String automationId);

  /// Whether a device-setting action can run (permission / OS support).
  Future<Availability> deviceActionAvailability(DeviceSettingAction action);

  /// Apply a device-setting action. Idempotent.
  Future<void> applyDeviceAction(DeviceSettingAction action);
}
