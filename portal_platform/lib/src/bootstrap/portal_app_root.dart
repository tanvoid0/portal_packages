import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

import '../settings/portal_theme_controller.dart';
import 'portal_bootstrap.dart';

/// The themed [GetMaterialApp] root every standalone Portal app builds the
/// same way: an [Obx] that reacts to the stored palette, light/dark themes
/// built from that seed, [PortalBootstrap.startRoute] as the start route, and
/// the fleet's shared [builder] unless the app needs its own.
///
/// Six apps (gym, journey, lifestyle, shopping, recipe, automation)
/// hand-built this identically; this is that shape, once. What stays with
/// the app: [getPages] (every route is app-specific), the theme functions
/// themselves, and anything that does not fit this shape at all — finance's
/// `routingCallback`-driven app-lock gate means its root stays hand-rolled.
class PortalAppRoot extends StatelessWidget {
  const PortalAppRoot({
    super.key,
    required this.title,
    required this.lightTheme,
    required this.darkTheme,
    required this.getPages,
    this.debugShowCheckedModeBanner = false,
    this.builder,
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
        title: title,
        theme: lightTheme(seed),
        darkTheme: darkTheme(seed),
        themeMode: themeController.themeMode.value,
        debugShowCheckedModeBanner: debugShowCheckedModeBanner,
        initialRoute: PortalBootstrap.startRoute,
        getPages: getPages,
        builder: builder ?? portalDefaultAppBuilder,
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
