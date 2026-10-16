import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

import 'portal_auth_binding.dart';
import 'portal_auth_view.dart';

/// Branding and feature configuration for the shared auth UI.
///
/// Each app passes its own config so the shared [PortalAuthView] renders
/// the correct icon, title, and subtitle while inheriting the host app's
/// [ThemeData] automatically via `Theme.of(context)`.
class PortalAuthConfig {
  const PortalAuthConfig({
    required this.appIcon,
    required this.appTitle,
    this.appIconImage,
    this.appSubtitle = 'Sign in to continue',
    this.showTestServer = false,
    this.testServerUrl,
    this.onForgotPassword,
    this.allowRegistration = true,
    this.allowLocalOnlyLogin = true,
    this.onLocalOnlySessionStarted,
  });

  /// Whether the sign-up half of the form is reachable. Off for an app whose
  /// server has no registration endpoint — otherwise the toggle offers a
  /// screen that can only ever fail.
  final bool allowRegistration;

  /// Icon displayed in the auth header (e.g. `Icons.restaurant_menu`).
  /// Used as fallback when [appIconImage] is not provided.
  final IconData appIcon;

  /// Optional image asset path for a custom logo (e.g. `'assets/images/app_logo.png'`).
  /// When provided, takes precedence over [appIcon].
  final String? appIconImage;

  /// App name displayed below the icon.
  final String appTitle;

  /// Subtitle / tagline shown beneath the app title.
  final String appSubtitle;

  /// Whether to show the debug "Test server" health-check button.
  /// Typically `true` during development for apps that need it.
  final bool showTestServer;

  /// With [showTestServer], adds a "Use test server" switch that points the
  /// app at this URL (and back at the build's own server when off). Null, no
  /// switch.
  final String? testServerUrl;

  /// Overrides the "Forgot password?" action, which otherwise opens the
  /// shared [PortalPasswordResetView]. Set it when the app has its own reset
  /// route (e.g. Portal Task).
  final VoidCallback? onForgotPassword;

  /// Whether "Continue without an account" is offered. On by default; turn it
  /// off for an app with no on-device data (Finance). Needs a
  /// [DeviceSecurityController], which [PortalBootstrap.init] registers (the phone lock is
  /// this session's only credential). Hidden on web regardless.
  final bool allowLocalOnlyLogin;

  /// Called once, right after a local-only session is started successfully,
  /// with the user's one-time encryption choice — before navigating away.
  /// The seam for an app's own entity-persistence setup to react to the
  /// choice, the same way [onForgotPassword] is for its own reset route.
  final void Function(bool encrypted)? onLocalOnlySessionStarted;

  /// Builds a config from a shared [PortalAppIdentity] so an app doesn't
  /// restate its icon/name/tagline a second time for the auth screen.
  ///
  /// [PortalAppIdentity.logo] is an [ImageProvider], but [appIconImage] here
  /// is an asset path (`Image.asset` in [PortalAuthView]) — the two aren't
  /// the same type, so a logo on the identity is not forwarded; [appIcon]
  /// is used instead. Pass [appIconImage] (an asset path) for an app whose
  /// auth screen shows its logo image; [appSubtitle] overrides the tagline.
  factory PortalAuthConfig.of(
    PortalAppIdentity identity, {
    String? appIconImage,
    String? appSubtitle,
    bool showTestServer = false,
    String? testServerUrl,
    VoidCallback? onForgotPassword,
    bool allowRegistration = true,
    bool allowLocalOnlyLogin = true,
    void Function(bool encrypted)? onLocalOnlySessionStarted,
  }) => PortalAuthConfig(
    appIcon: identity.icon,
    appIconImage: appIconImage,
    appTitle: identity.name,
    appSubtitle: appSubtitle ?? identity.tagline,
    showTestServer: showTestServer,
    testServerUrl: testServerUrl,
    onForgotPassword: onForgotPassword,
    allowRegistration: allowRegistration,
    allowLocalOnlyLogin: allowLocalOnlyLogin,
    onLocalOnlySessionStarted: onLocalOnlySessionStarted,
  );
}

/// The login [GetPage] every app wires up the same way: [PortalAuthView]
/// built from [PortalAuthConfig.of], bound by [PortalAuthBinding]. Covers
/// every app whose auth screen needs nothing beyond [identity] — one that
/// builds its [PortalAuthConfig] some other way (a logo asset, a custom
/// forgot-password route) still constructs its own `GetPage` instead.
GetPage portalLoginPage({
  required String name,
  required PortalAppIdentity identity,
  String? appIconImage,
  String? appSubtitle,
  bool showTestServer = false,
  String? testServerUrl,
  VoidCallback? onForgotPassword,
  bool allowRegistration = true,
  bool allowLocalOnlyLogin = true,
  void Function(bool encrypted)? onLocalOnlySessionStarted,
  List<GetMiddleware>? middlewares,
  bool participatesInRootNavigator = false,
}) => GetPage(
  name: name,
  page: () => PortalAuthView(
    config: PortalAuthConfig.of(
      identity,
      appIconImage: appIconImage,
      appSubtitle: appSubtitle,
      showTestServer: showTestServer,
      testServerUrl: testServerUrl,
      onForgotPassword: onForgotPassword,
      allowRegistration: allowRegistration,
      allowLocalOnlyLogin: allowLocalOnlyLogin,
      onLocalOnlySessionStarted: onLocalOnlySessionStarted,
    ),
  ),
  binding: PortalAuthBinding(),
  middlewares: middlewares,
  participatesInRootNavigator: participatesInRootNavigator,
);
