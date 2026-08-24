import 'package:get/get.dart';

import '../session/session_controller.dart';

/// Prefixes storage keys with the signed-in user id so caches stay isolated.
abstract final class UserStorageScope {
  /// Returns [baseKey] suffixed with `_<userId>` when a user is signed in.
  static String scopeKey(String baseKey) {
    final userId = currentUserId;
    if (userId == null || userId.isEmpty) return baseKey;
    return '${baseKey}_$userId';
  }

  static String? get currentUserId {
    if (!Get.isRegistered<SessionController>()) return null;
    return Get.find<SessionController>().user.value?['id']?.toString();
  }
}
