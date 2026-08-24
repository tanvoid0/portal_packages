import 'package:flutter/material.dart';

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
    this.onForgotPassword,
  });

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

  /// Overrides the "Forgot password?" action, which otherwise opens the
  /// shared [PortalPasswordResetView]. Set it when the app has its own reset
  /// route (e.g. Portal Task).
  final VoidCallback? onForgotPassword;
}
