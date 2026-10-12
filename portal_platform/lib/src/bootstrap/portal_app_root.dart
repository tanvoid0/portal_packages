import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

import '../auth/device_security/portal_device_security_gate.dart';
import '../settings/portal_theme_controller.dart';
import 'portal_bootstrap.dart';

/// The themed [GetMaterialApp] root every standalone Portal app builds the
/// same way: an [Obx] that reacts to the stored palette, light/dark themes
/// built from that seed, [PortalBootstrap.startRoute] as the start route, and
/// the fleet's shared [builder] unless the app needs its own.
///
/// Eight apps (gym, journey, lifestyle, shopping, recipe, automation,
/// finance, task) build this identically; this is that shape, once. What
/// stays with the app: [getPages] (every route is app-specific), the theme
/// functions themselves, and — via [PortalAppRoot.router] — whether the app
/// is on GetX nav2 instead of the named-route push model.
class PortalAppRoot extends StatefulWidget {
  const PortalAppRoot({
    super.key,
    required this.title,
    required this.lightTheme,
    required this.darkTheme,
    required this.getPages,
    this.debugShowCheckedModeBanner = false,
    this.builder,
    this.shouldGuardRoute,
  })  : routerDelegate = null,
        routeInformationParser = null,
        backButtonDispatcher = null,
        scaffoldMessengerKey = null;

  /// For an app on GetX nav2 (nested/section-outlet route trees) instead of
  /// the named-route push model the plain constructor builds — task's
  /// `AppPages.usesSectionOutlet`/`Get.routeTree.matchRoute` needs
  /// `GetMaterialApp.router`, which the plain constructor can't express.
  /// Everything else — theme, [shouldGuardRoute], [builder] — works exactly
  /// the same; only the underlying `GetMaterialApp` constructor differs.
  ///
  /// [shouldGuardRoute] is driven by [routerDelegate]'s own `ChangeNotifier`
  /// here, not `routingCallback` — `GetMaterialApp.router` never wires
  /// `routingCallback` (`GetDelegate.build` passes a bare `GetObserver()`),
  /// so the plain constructor's mechanism is silently dead in router mode.
  const PortalAppRoot.router({
    super.key,
    required this.title,
    required this.lightTheme,
    required this.darkTheme,
    required this.getPages,
    required GetDelegate this.routerDelegate,
    required GetInformationParser this.routeInformationParser,
    this.backButtonDispatcher,
    this.scaffoldMessengerKey,
    this.debugShowCheckedModeBanner = false,
    this.builder,
    this.shouldGuardRoute,
  });

  final String title;

  /// Built from the stored palette seed (null = this app's own default).
  final ThemeData Function(Color? seedColor) lightTheme;
  final ThemeData Function(Color? seedColor) darkTheme;

  final List<GetPage> getPages;
  final bool debugShowCheckedModeBanner;

  /// Defaults to [portalDefaultAppBuilder]. Pass one of your own for extra
  /// always-on overlay widgets (a floating panel, a sync banner) — wrap
  /// [portalDefaultAppBuilder]'s result rather than reimplementing it.
  final Widget Function(BuildContext, Widget?)? builder;

  /// Non-null turns on the shared app lock: [PortalDeviceSecurityGate] wraps
  /// [builder]'s (or the default builder's) output and is guarded whenever
  /// this returns true for the current route name. Requires a
  /// `DeviceSecurityController` already registered when the root builds —
  /// the caller sets that up in its own startup step, same as it does today.
  final bool Function(String route)? shouldGuardRoute;

  /// Non-null only via [PortalAppRoot.router].
  final GetDelegate? routerDelegate;
  final GetInformationParser? routeInformationParser;

  /// Defaults to [RootBackButtonDispatcher] — without one, `Router` never
  /// hears the system back button and Android just finishes the activity.
  final BackButtonDispatcher? backButtonDispatcher;
  final GlobalKey<ScaffoldMessengerState>? scaffoldMessengerKey;

  @override
  State<PortalAppRoot> createState() => _PortalAppRootState();
}

class _PortalAppRootState extends State<PortalAppRoot> {
  // Null when shouldGuardRoute is null, so the other callers get the exact
  // widget tree they have today — no Obx, no gate.
  RxBool? _guarding;

  @override
  void initState() {
    super.initState();
    final shouldGuardRoute = widget.shouldGuardRoute;
    if (shouldGuardRoute == null) return;
    _guarding = RxBool(shouldGuardRoute(PortalBootstrap.startRoute));
    widget.routerDelegate?.addListener(_onRouterDelegateChanged);
  }

  @override
  void dispose() {
    widget.routerDelegate?.removeListener(_onRouterDelegateChanged);
    super.dispose();
  }

  void _onRouting(Routing? routing) {
    final guard = widget.shouldGuardRoute!(routing?.current ?? '');
    // The first route's didPush fires from inside the Navigator's own build
    // (the persistentCallbacks phase), and this Rx sits above the Navigator,
    // so a synchronous write there marks an ancestor dirty mid-build. A
    // user-driven navigation arrives idle, and deferring that one leaks a
    // frame of content before the lock, so only the mid-build case waits.
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _guarding!.value = guard;
      });
    } else {
      _guarding!.value = guard;
    }
  }

  // The delegate's ChangeNotifier fires both from a tap (idle) and from
  // setNewRoutePath during the Router's own build (deep link, web URL,
  // back) — unlike routingCallback's one timing, so this always defers
  // rather than picking a phase to trust.
  void _onRouterDelegateChanged() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _guarding!.value =
          widget.shouldGuardRoute!(_nav2CurrentPath(widget.routerDelegate!));
    });
  }

  Widget _build(BuildContext context, Widget? child) {
    final built = (widget.builder ?? portalDefaultAppBuilder)(context, child);
    final guarding = _guarding;
    if (guarding == null) return built;
    // `built` is constructed outside the Obx closure so flipping the guard
    // rebuilds the gate only, never the navigator underneath it.
    return Obx(() => PortalDeviceSecurityGate(shouldGuard: guarding.value, child: built));
  }

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<PortalThemeController>();
    // Obx around the whole app, not a widget inside it: themeMode lives on
    // GetMaterialApp, so nothing below it can react to the setting changing.
    return Obx(() {
      // Read inside the Obx so picking a palette rebuilds the app. Null —
      // nothing stored, or an id from a build with palettes this one does
      // not have — leaves the app on its own default seed.
      final seed = portalSeedForPaletteId(themeController.paletteId.value);
      final routerDelegate = widget.routerDelegate;
      if (routerDelegate != null) {
        return GetMaterialApp.router(
          title: widget.title,
          theme: widget.lightTheme(seed),
          darkTheme: widget.darkTheme(seed),
          themeMode: themeController.themeMode.value,
          debugShowCheckedModeBanner: widget.debugShowCheckedModeBanner,
          getPages: widget.getPages,
          routerDelegate: routerDelegate,
          routeInformationParser: widget.routeInformationParser!,
          backButtonDispatcher:
              widget.backButtonDispatcher ?? RootBackButtonDispatcher(),
          scaffoldMessengerKey: widget.scaffoldMessengerKey,
          builder: _build,
        );
      }
      return GetMaterialApp(
        title: widget.title,
        routingCallback: _guarding == null ? null : _onRouting,
        theme: widget.lightTheme(seed),
        darkTheme: widget.darkTheme(seed),
        themeMode: themeController.themeMode.value,
        debugShowCheckedModeBanner: widget.debugShowCheckedModeBanner,
        initialRoute: PortalBootstrap.startRoute,
        getPages: widget.getPages,
        builder: _build,
      );
    });
  }
}

/// The nav2 route path a [GetDelegate] currently sits on, resolved the same
/// way for any app: the configuration's own URI, else its location string,
/// else the active route tree branch's segment names. Null safe about all
/// three being unavailable mid-transition.
String _nav2CurrentPath(GetDelegate delegate) {
  final config = delegate.currentConfiguration;
  if (config == null) return '';

  final uriPath = config.uri.path;
  if (uriPath.isNotEmpty && uriPath != '/') return uriPath;

  final location = config.locationString;
  if (location.isNotEmpty) {
    final fromLocation = Uri.tryParse(location)?.path;
    if (fromLocation != null && fromLocation.isNotEmpty && fromLocation != '/') {
      return fromLocation;
    }
  }

  final segments = <String>[];
  for (final page in config.currentTreeBranch) {
    final name = page.name;
    if (name.isEmpty || name == '/') continue;
    final segment = name.startsWith('/') ? name.substring(1) : name;
    if (segment.isEmpty) continue;
    segments.add(segment);
  }
  return segments.isEmpty ? '' : '/${segments.join('/')}';
}

/// The fleet's shared app [builder]: clamps text scaling to a readable
/// range, carries the current theme's system overlay (status/navigation bar)
/// down through an [AnnotatedRegion], and mounts [PortalToastHost] via
/// [portalWrapWithToast].
Widget portalDefaultAppBuilder(BuildContext context, Widget? child) {
  if (child == null) return const SizedBox.shrink();
  final mq = MediaQuery.of(context);
  final clampedText = mq.textScaler.clamp(
    minScaleFactor: 0.85,
    maxScaleFactor: 1.35,
  );
  final theme = Theme.of(context);
  final overlay =
      theme.appBarTheme.systemOverlayStyle ??
      portalSystemUiOverlay(theme.colorScheme.brightness);
  return MediaQuery(
    data: mq.copyWith(textScaler: clampedText),
    child: AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlay,
      child: SizedBox.expand(
        child: ColoredBox(
          color: theme.colorScheme.surface,
          child: SafeArea(child: portalWrapWithToast(child)),
        ),
      ),
    ),
  );
}
