import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';

import '../config/app_config.dart';
import '../auth/local_user_auth.dart';
import '../observability/portal_error_handlers.dart';
import '../observability/portal_logger.dart';
import '../observability/portal_sentry.dart';
import '../routing/deep_link_service.dart';
import '../services/api_client.dart';
import '../session/session_controller.dart';

/// Registers shared platform services used by standalone Portal apps.
class PortalBootstrap {
  PortalBootstrap._();

  /// Loads `.env`, initializes [ApiClient], [DeepLinkService], [SessionController],
  /// and stores [config]. Returns whether the user has a valid session.
  static Future<bool> init({
    String envFileName = '.env',
    AppConfig? configOverride,
    bool registerNotifications = false,
    String sourceName = 'portal-app',
  }) async {
    WidgetsFlutterBinding.ensureInitialized();
    if (!dotenv.isInitialized) {
      await dotenv.load(fileName: envFileName);
    }

    if (!PortalLogger.isInitialized) {
      await PortalLogger.init(sourceName: sourceName);
      PortalErrorHandlers.install();
    }

    await PortalSentry.initFromEnv(envFileName: envFileName, loadEnv: false);

    final config = configOverride ?? AppConfig.fromEnv();

    await Get.putAsync<ApiClient>(
      () => ApiClient().init(baseUrl: config.apiBaseUrl),
    );
    Get.put<DeepLinkService>(DeepLinkService(), permanent: true);
    Get.put<SessionController>(SessionController(), permanent: true);
    Get.put<AppConfig>(config, permanent: true);

    var isLoggedIn = await Get.find<ApiClient>().isLoggedIn();
    if (!isLoggedIn && config.autoLocalAuth) {
      isLoggedIn = await LocalUserAuth.ensureRegistered();
    }
    if (isLoggedIn && Get.isRegistered<SessionController>()) {
      await Get.find<SessionController>().reloadFromStorage();
    }

    return isLoggedIn;
  }
}
