import 'package:flutter/widgets.dart' show VoidCallback;

import 'portal_toast_host.dart';

/// Shared toast helpers for Portal apps. Prefer this over raw [Get.snackbar].
///
/// The one feedback API: the apps' `AppFeedback` copies (shopping, lifestyle)
/// and the recipe `portal_snackbar` re-export retire onto it. The caller picks
/// success or error; the copies guessed the variant from keywords in the title
/// ("saved", "fail"), which breaks in any other language. [failure] is for a
/// caught error: it never falls through to a success tone. A write that
/// fails is shown here or queued, never swallowed.
abstract final class PortalAppFeedback {
  PortalAppFeedback._();

  /// Lets an app teach [messageFrom] its own error types without ui_core
  /// depending on them: `PortalAppFeedback.errorMessageResolver = (e) =>
  /// e is ApiException ? e.message : null;` once at startup. Return null to
  /// fall through: a `String` error is shown as it is, anything else gets the fallback (an `Exception`'s `toString()` is not user text).
  static String? Function(Object error)? errorMessageResolver;

  /// User-facing text for a thrown [error]; [fallback] for null or empty.
  static String messageFrom(
    Object? error, {
    String fallback = 'Something went wrong.',
  }) {
    if (error == null) return fallback;
    String? resolved;
    try {
      resolved = errorMessageResolver?.call(error);
    } catch (_) {
      // A resolver that throws must not turn one error into another.
    }
    final text = (resolved ?? (error is String ? error : '')).trim();
    return text.isEmpty ? fallback : text;
  }

  /// An error toast from a caught [error], e.g. a failed write.
  static void failure(
    Object? error, {
    String title = 'Something went wrong',
    String fallback = 'Something went wrong.',
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 4),
  }) {
    AppToast.error(
      title,
      description: messageFrom(error, fallback: fallback),
      actionLabel: actionLabel,
      onAction: onAction,
      duration: duration,
    );
  }

  static void show(
    String title, {
    String? message,
    String? description,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 4),
  }) {
    final body = _body(message, description);
    AppToast.show(
      title,
      description: body,
      actionLabel: actionLabel,
      onAction: onAction,
      duration: duration,
    );
  }

  static void success(
    String title, {
    String? message,
    String? description,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 3),
  }) {
    final body = _body(message, description);
    AppToast.success(
      title,
      description: body,
      actionLabel: actionLabel,
      onAction: onAction,
      duration: duration,
    );
  }

  static void error(
    String title, {
    String? message,
    String? description,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 4),
  }) {
    final body = _body(message, description);
    AppToast.error(
      title,
      description: body,
      actionLabel: actionLabel,
      onAction: onAction,
      duration: duration,
    );
  }

  static void info(
    String title, {
    String? message,
    String? description,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 3),
  }) {
    show(
      title,
      message: message,
      description: description,
      actionLabel: actionLabel,
      onAction: onAction,
      duration: duration,
    );
  }

  static String? _body(String? message, String? description) {
    final text = (description ?? message)?.trim();
    if (text == null || text.isEmpty) return null;
    return text;
  }
}
