import 'package:get/get.dart';

import '../config/app_config.dart';
import '../observability/portal_sentry.dart';
import '../routing/deep_link_service.dart';
import '../routing/portal_navigation.dart';
import '../services/api_client.dart';

/// Holds the cached user profile from storage and refreshes after auth.
/// Registered as permanent in [main.dart].
class SessionController extends GetxController {
  final ApiClient _api = Get.find<ApiClient>();

  final Rxn<Map<String, dynamic>> user = Rxn<Map<String, dynamic>>();

  @override
  void onInit() {
    super.onInit();
    reloadFromStorage();
  }

  /// Reloads [user] from secure storage (after login or cold start).
  Future<void> reloadFromStorage() async {
    final loggedIn = await _api.isLoggedIn();
    if (!loggedIn) {
      user.value = null;
      PortalSentry.syncUser(null);
      return;
    }
    user.value = await _api.getCurrentUser();
    PortalSentry.syncUser(user.value);
  }

  /// Renames the signed-in profile.
  ///
  /// The profile is one record shared by every Portal app, so this is not a
  /// per-app display name — changing it here changes it everywhere. Re-reads
  /// from the server afterwards rather than assuming the write took the value
  /// verbatim; the server trims and length-caps it.
  Future<void> updateName(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    await _api.put('/auth/me', body: {'name': trimmed});
    await _api.syncProfileFromServer();
    await reloadFromStorage();
  }

  /// Clears tokens, session cache, pending deep links, and returns to login.
  Future<void> signOut() async {
    await _api.logout();
    user.value = null;
    PortalSentry.syncUser(null);
    Get.find<DeepLinkService>().clearPending();
    PortalNavigation.require.go(Get.find<AppConfig>().routeLoggedOut);
  }

  static String initialsFor(Map<String, dynamic>? u) {
    if (u == null) return '?';
    final name = (u['name'] as String?)?.trim();
    if (name != null && name.isNotEmpty) {
      final parts = name.split(RegExp(r'\s+'));
      if (parts.length >= 2 &&
          parts[0].isNotEmpty &&
          parts[1].isNotEmpty) {
        return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      }
      return name.substring(0, 1).toUpperCase();
    }
    final email = (u['email'] as String?)?.trim();
    if (email != null && email.isNotEmpty) {
      return email.substring(0, 1).toUpperCase();
    }
    return '?';
  }
}
