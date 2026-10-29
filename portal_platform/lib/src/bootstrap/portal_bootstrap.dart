import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../auth/device_security/device_security_binding.dart';
import '../auth/device_security/device_security_controller.dart';
import '../auth/device_security/portal_device_security_strings.dart';
import '../config/app_config.dart';
import '../auth/local_user_auth.dart';
import '../observability/portal_error_handlers.dart';
import '../observability/portal_logger.dart';
import '../observability/portal_sentry.dart';
import '../routing/deep_link_service.dart';
import '../services/api_client.dart';
import '../session/session_controller.dart';
import '../sync/connectivity_service.dart';
import '../sync/sync_manager.dart';
import '../sync/sync_queue.dart';
import '../testing/fake_backend.dart';
import '../update/portal_update_service.dart';
import '../update/portal_update_tile.dart';

/// Registers shared platform services used by standalone Portal apps.
class PortalBootstrap {
  PortalBootstrap._();

  static bool _isLoggedIn = false;

  /// True once the full shared bootstrap has run (the hub runs it once; a
  /// standalone app on its single [init]). A later [init] is then a module
  /// open and takes only the per-module tail ([initModule]).
  static bool _sharedReady = false;

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

  static Future<GetStorage> _defaultPrefs() async {
    await GetStorage.init();
    return GetStorage();
  }

  /// Loads `.env`, initializes [ApiClient], [DeepLinkService], [SessionController],
  /// and stores [config]. Returns whether the user has a valid session.
  static Future<bool> init({
    String envFileName = '.env',
    AppConfig? configOverride,
    bool registerNotifications = false,
    String sourceName = 'portal-app',
    bool checkForUpdatesOnLaunch = true,
    GetStorage? deviceSecurityPrefs,
    PortalDeviceSecurityStrings? deviceSecurityStrings,
  }) async {
    // Once shared bootstrap has run, a later init is a module open: run only
    // the per-module tail so the process-wide singletons (preserved across the
    // switch by [resetForModuleSwitch]) are reused, not rebuilt. A standalone
    // app calls init exactly once, so it always takes the full path below.
    if (_sharedReady) {
      return initModule(configOverride ?? AppConfig.fromEnv());
    }
    WidgetsFlutterBinding.ensureInitialized();
    if (defaultTargetPlatform == TargetPlatform.android) {
      unawaited(FlutterDisplayMode.setHighRefreshRate().catchError((_) {}));
    }
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
      () => (kPortalFake ? FakeApi() : ApiClient()).init(
        baseUrl: config.apiBaseUrl,
        appName: config.appTitle,
      ),
    );
    Get.put<DeepLinkService>(DeepLinkService(), permanent: true);
    Get.put<SessionController>(
      kPortalFake ? FakeSession(kPortalFakeUser) : SessionController(),
      permanent: true,
    );
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

    // PORTAL_FAKE boots signed in with no tokens: the FakeSession above already
    // holds the demo user, so skip the storage probe that would report false.
    var isLoggedIn = kPortalFake || await Get.find<ApiClient>().isLoggedIn();
    if (!isLoggedIn && config.autoLocalAuth) {
      isLoggedIn = await LocalUserAuth.ensureRegistered();
    }
    // The app lock, same for every app: the local-only login needs it (the
    // phone lock is that session's only credential) and PortalAppRoot gates
    // on it. An app passes its own wording and prefs box; a cold start locks
    // only when there is a session to protect.
    if (!Get.isRegistered<DeviceSecurityController>()) {
      DeviceSecurityBinding(
        prefs: deviceSecurityPrefs ?? await _defaultPrefs(),
        strings: deviceSecurityStrings,
      ).dependencies();
    }
    await Get.find<DeviceSecurityController>().init(lockOnStart: isLoggedIn);
    if (isLoggedIn && Get.isRegistered<SessionController>()) {
      await Get.find<SessionController>().reloadFromStorage();
    }

    _isLoggedIn = isLoggedIn;
    _sharedReady = true;
    return isLoggedIn;
  }

  /// The per-module tail of [init], run on every hub module open once shared
  /// bootstrap is done: register this module's [config] and refresh the
  /// signed-in answer. The process-wide services were preserved across the
  /// switch by [resetForModuleSwitch], so they are reused in memory, not
  /// rebuilt. Also the startup gate's cheap retry path (a retry re-runs [init],
  /// which lands here).
  static Future<bool> initModule(AppConfig config) async {
    Get.put<AppConfig>(config, permanent: true);
    _isLoggedIn = kPortalFake || await Get.find<ApiClient>().isLoggedIn();
    _scheduleDeepLinkAttach();
    return _isLoggedIn;
  }

  /// Hub only: a [Get.reset] that keeps the process-wide singletons alive
  /// across a module switch, so they are reused instead of rebuilt from disk.
  ///
  /// Re-putting a live instance does not re-run its `onInit` (GetX guards that
  /// with the instance's own init flag) and runs no constructor, so the kept
  /// services do not re-listen. The route tree still clears, which is the only
  /// thing the swap needs. [SyncManager] is the exception: it is force-deleted
  /// first so its `onClose` cancels the retry timer and removes its reconnect
  /// listener from the shared [ConnectivityService] (closing the leak the bare
  /// `Get.reset` left); the opening module recreates it and registers its own
  /// repos. Per-module state (AppConfig, theme, AI runtime, module services) is
  /// intentionally dropped and rebuilt by the opening module's startup — only
  /// add process-wide services to the kept list, or a stale value survives
  /// silently.
  static void resetForModuleSwitch() {
    T? keep<T>() => Get.isRegistered<T>() ? Get.find<T>() : null;
    final api = keep<ApiClient>();
    final links = keep<DeepLinkService>();
    final session = keep<SessionController>();
    final update = keep<PortalUpdateService>();
    final security = keep<DeviceSecurityController>();
    final connectivity = keep<ConnectivityService>();
    final queue = keep<SyncQueue>();
    if (Get.isRegistered<SyncManager>()) Get.delete<SyncManager>(force: true);
    Get.reset();
    if (api != null) Get.put<ApiClient>(api, permanent: true);
    if (links != null) Get.put<DeepLinkService>(links, permanent: true);
    if (session != null) Get.put<SessionController>(session, permanent: true);
    if (update != null) Get.put<PortalUpdateService>(update, permanent: true);
    if (security != null) {
      Get.put<DeviceSecurityController>(security, permanent: true);
    }
    if (connectivity != null) {
      Get.put<ConnectivityService>(connectivity, permanent: true);
    }
    if (queue != null) Get.put<SyncQueue>(queue, permanent: true);
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
