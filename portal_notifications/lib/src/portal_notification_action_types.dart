/// Canonical notification action type strings.
abstract final class PortalNotificationActionTypes {
  static const openTask = 'open_task';
  static const openRoute = 'open_route';

  /// Bare task id string when the OS payload is not structured JSON.
  static const taskIdValue = 'task_id_value';

  /// Stored type from older app versions; normalized on read.
  static const _storedTaskIdValueV1 = 'legacy_payload';

  static String normalize(String type) =>
      type == _storedTaskIdValueV1 ? taskIdValue : type;
}
