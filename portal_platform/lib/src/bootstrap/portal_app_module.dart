import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

import '../../portal_deep_link.dart';
import '../config/app_config.dart';
import '../web/portal_url_strategy.dart';
import 'portal_app_root.dart';

/// One Portal app, described the way both its own `main()` and the super app
/// (`apps/portal_hub`) can run it — without either copying the other.
///
/// It bundles the exact pieces a standalone app builds by hand today: the
/// [PortalStartupGate] steps, the [GetPage] route tree and the themed
/// [PortalAppRoot]. [runPortalApp] turns a module back into that same tree, so
/// `main()` becomes a one-liner and the behaviour is unchanged. The hub imports
/// the same module value and mounts its [pages] nested, so a route or theme the
/// app changes shows up in the hub with no edit — the app package stays the one
/// source of truth.
///
/// The fields beyond [pages]/[startup] ([slug], [icon], [routeLoggedIn/Out],
/// [deepLink]) are metadata the hub reads to build its launcher and its
/// scheme→resolver deep-link map; standalone they are carried by the startup
/// steps the app already runs.
class PortalAppModule {
  const PortalAppModule({
    required this.slug,
    required this.title,
    required this.icon,
    required this.identity,
    required this.lightTheme,
    required this.darkTheme,
    required this.routeLoggedIn,
    required this.routeLoggedOut,
    required this.pages,
    required this.startup,
    this.deepLink,
    this.themeMode = ThemeMode.system,
    this.onPreStart,
    this.builder,
  });

  /// URL scheme / package suffix, e.g. `journey` → `portal-journey`,
  /// `com.tanvoid0.portal_journey`. The hub keys its module map by this.
  final String slug;

  /// The app's display name — the same string the app passes as
  /// `AppConfig.appTitle` and `GetMaterialApp.title`.
  final String title;

  /// Launcher glyph. An app's [identity] already carries its mark, so this is
  /// normally `identity.icon`.
  final IconData icon;

  /// Mark, name and tagline shown on the startup splash.
  final PortalAppIdentity identity;

  /// Built from the stored palette seed (null = the app's own default). The
  /// splash reuses these at `lightTheme(null)` / `darkTheme(null)`.
  final ThemeData Function(Color? seedColor) lightTheme;
  final ThemeData Function(Color? seedColor) darkTheme;

  /// Where the app opens signed in / signed out.
  final String routeLoggedIn;
  final String routeLoggedOut;

  /// The full route tree, exactly what the app's `PortalAppRoot.getPages` holds.
  final List<GetPage> pages;

  /// Startup work, run in order by the gate — the app's `main()` steps,
  /// unchanged.
  final List<PortalStartupStep> startup;

  /// Resolves this app's deep links (`portal-<slug>://…`). The startup steps
  /// still register it standalone; the hub reads it to build its scheme map.
  final DeepLinkPathResolver? deepLink;

  /// Splash theme mode. An app that ships dark (gym) passes
  /// [ThemeMode.dark] so the splash matches before the theme controller loads.
  final ThemeMode themeMode;

  /// Synchronous work an app must do before `runApp` (gym registers a package
  /// license here). Runs after the binding and URL strategy are set up.
  final VoidCallback? onPreStart;

  /// The app's own [PortalAppRoot.builder], when it needs one (recipe overlays
  /// a floating cooking panel and sync banner, and paints its own
  /// scaffold background). Null uses the fleet's [portalDefaultAppBuilder]. The
  /// super app wraps whichever applies with its launcher chrome.
  final Widget Function(BuildContext context, Widget? child)? builder;
}

/// The widget tree [runPortalApp] runs: the [PortalStartupGate] over the
/// module's themed [PortalAppRoot]. Exposed (not inlined in [runPortalApp]) so
/// the super app can mount the exact same tree under its own chrome without
/// copying the wiring.
///
/// [wrapContent] wraps the app's content — the super app injects its launcher
/// chrome here. It receives the fleet's default-wrapped content
/// ([portalDefaultAppBuilder]'s output), so the clamp, overlay and toast host
/// an app relies on are already applied. Null leaves the app exactly as
/// standalone.
///
/// [module.onPreStart] is the caller's responsibility: [runPortalApp] calls it
/// before `runApp`; the super app calls it before first mounting the module.
Widget portalAppView(
  PortalAppModule module, {
  Widget Function(BuildContext context, Widget content)? wrapContent,
}) {
  return PortalStartupGate(
    identity: module.identity,
    theme: module.lightTheme(null),
    darkTheme: module.darkTheme(null),
    themeMode: module.themeMode,
    steps: module.startup,
    builder: (_) => PortalAppRoot(
      title: module.title,
      lightTheme: module.lightTheme,
      darkTheme: module.darkTheme,
      getPages: module.pages,
      // Standalone: the app's own builder (or null = the fleet default).
      // Under the hub: wrap that same content with the launcher chrome.
      builder: wrapContent == null
          ? module.builder
          : (ctx, child) => wrapContent(
              ctx,
              (module.builder ?? portalDefaultAppBuilder)(ctx, child),
            ),
      // Both apps passed config.debugShowCheckedModeBanner; the config is
      // registered by PortalBootstrap.init in a startup step, so it is
      // available by the time the gate builds the app.
      debugShowCheckedModeBanner:
          Get.find<AppConfig>().debugShowCheckedModeBanner,
    ),
  );
}

/// Runs [module] as a standalone app: the exact [PortalStartupGate] +
/// [PortalAppRoot] its `main()` built by hand. Behaviour-preserving — the
/// startup steps still build the config, register the deep-link resolver and
/// wire sync.
void runPortalApp(PortalAppModule module) {
  WidgetsFlutterBinding.ensureInitialized();
  usePortalUrlStrategy();
  module.onPreStart?.call();
  runApp(portalAppView(module));
}
