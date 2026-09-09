import 'portal_toast_host.dart';

/// Shared toast helpers for Portal apps. Prefer this over raw [Get.snackbar].
abstract final class PortalAppFeedback {
  PortalAppFeedback._();

  static void show(
    String title, {
    String? message,
    String? description,
    Duration duration = const Duration(seconds: 4),
  }) {
    final body = _body(message, description);
    AppToast.show(title, description: body, duration: duration);
  }

  static void success(
    String title, {
    String? message,
    String? description,
    Duration duration = const Duration(seconds: 3),
  }) {
    final body = _body(message, description);
    AppToast.success(title, description: body, duration: duration);
  }

  static void error(
    String title, {
    String? message,
    String? description,
    Duration duration = const Duration(seconds: 4),
  }) {
    final body = _body(message, description);
    AppToast.error(title, description: body, duration: duration);
  }

  static void info(
    String title, {
    String? message,
    String? description,
    Duration duration = const Duration(seconds: 3),
  }) {
    show(title, message: message, description: description, duration: duration);
  }

  static String? _body(String? message, String? description) {
    final text = (description ?? message)?.trim();
    if (text == null || text.isEmpty) return null;
    return text;
  }
}
