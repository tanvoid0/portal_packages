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
/// Every standalone app (gym, journey, lifestyle, shopping, recipe,
/// automation, finance, task) builds this identically; this is that shape,
/// once. What stays with the app: [getPages] (every route is app-specific)
/// and the theme functions themselves.
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
