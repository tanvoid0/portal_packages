import 'package:meta/meta.dart';

/// Whether an action or trigger can run right now, and if not, why.
///
/// A separate type rather than a boolean because the *reason* is what the UI
/// must show: "your phone cannot do this" and "you have not granted this yet"
/// need different words and different buttons. An automation that silently
/// does nothing is the failure mode this whole design exists to avoid.
/// (Mirrors portal_launcher's `AutomationAvailability`.)
@immutable
sealed class Availability {
  const Availability();
}

/// Ready to run.
class Ready extends Availability {
  const Ready();
}

/// Needs a permission the user grants outside the app. [settingsKey] names the
/// system screen the native bridge should open; [explanation] is shown first.
class NeedsPermission extends Availability {
  const NeedsPermission(this.explanation, {this.settingsKey});
  final String explanation;
  final String? settingsKey;
}

/// Cannot work on this device or OS version at all. Say so; offer no button.
class Unsupported extends Availability {
  const Unsupported(this.reason);
  final String reason;
}
