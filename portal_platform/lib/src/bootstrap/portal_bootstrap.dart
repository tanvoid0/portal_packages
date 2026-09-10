import 'dart:async';

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
import '../update/portal_update_service.dart';
import '../update/portal_update_tile.dart';

/// Registers shared platform services used by standalone Portal apps.
class PortalBootstrap {
  PortalBootstrap._();

  static bool _isLoggedIn = false;

  /// Whether [init] found a valid session. Same value [init] returned.
  static bool get isLoggedIn => _isLoggedIn;

  /// The route an app should open on: [AppConfig.routeLoggedIn] when [init]
  /// found a session, [AppConfig.routeLoggedOut] otherwise.
  ///
  /// This is the fleet's one answer to "onboarding or home?". Deciding it
  /// before the first route is built is the whole point — an app that instead
  /// boots to onboarding and navigates away once it has checked shows the
  /// onboarding screen to a signed-in user for a frame or two every launch.
  /// [init] has already restored the session by the time it returns, so there
  /// is nothing left to wait for here.
  static String get startRoute {
    final config = Get.find<AppConfig>();
    return _isLoggedIn ? config.routeLoggedIn : config.routeLoggedOut;
  }

  /// Loads `.env`, initializes [ApiClient], [DeepLinkService], [SessionController],
  /// and stores [config]. Returns whether the user has a valid session.
  static Future<bool> init({
    String envFileName = '.env',
    AppConfig? configOverride,
    bool registerNotifications = false,
    String sourceName = 'portal-app',
    bool checkForUpdatesOnLaunch = true,
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
      () => ApiClient().init(
        baseUrl: config.apiBaseUrl,
        appName: config.appTitle,
      ),
    );
    Get.put<DeepLinkService>(DeepLinkService(), permanent: true);
    Get.put<SessionController>(SessionController(), permanent: true);
    Get.put<AppConfig>(config, permanent: true);
    Get.put<PortalUpdateService>(
      PortalUpdateService(
        manifestUrl: config.updateManifestUrl,
        appName: config.appTitle,
      ),
      permanent: true,
    );
    if (checkForUpdatesOnLaunch) _scheduleUpdateCheck();
    _scheduleDeepLinkAttach();

    var isLoggedIn = await Get.find<ApiClient>().isLoggedIn();
    if (!isLoggedIn && config.autoLocalAuth) {
      isLoggedIn = await LocalUserAuth.ensureRegistered();
    }
    if (isLoggedIn && Get.isRegistered<SessionController>()) {
      await Get.find<SessionController>().reloadFromStorage();
    }

    _isLoggedIn = isLoggedIn;
    return isLoggedIn;
  }

  /// Starts deep-link handling after the first frame.
  ///
  /// [DeepLinkService.attach] both consumes the URI the app was launched with
  /// and subscribes to later ones, and it navigates -- so it has to wait until
  /// there is a navigator to navigate. Every app got this wrong in the same
  /// way (only one of them called it at all), so bootstrap does it for them;
  /// an app that calls [DeepLinkService.attach] itself is unaffected, the
  /// initial link is consumed once either way.
  static void _scheduleDeepLinkAttach() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(Get.find<DeepLinkService>().attach());
    });
  }

  /// Prompts for a sideload update after the first frame.
  ///
  /// Portal ships outside the Play Store for now, so nothing else tells an
  /// installed build that a newer one exists. Deferred to a post-frame
  /// callback because there is no navigator to show a dialog on until the app
  /// has actually built one, and left entirely to
  /// [portalPromptForUpdateOnLaunch] to stay quiet: it asks once per published
  /// version, never re-asks one the user refused, and swallows every failure.
  static void _scheduleUpdateCheck() {
    final service = Get.find<PortalUpdateService>();
    if (!service.isEnabled) return;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final context = Get.context;
      if (context == null || !context.mounted) return;
      await portalPromptForUpdateOnLaunch(context, service);
    });
  }
}
