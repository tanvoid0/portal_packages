import 'package:flutter/material.dart';

/// Which app is asking: its glyph, its name and its line.
///
/// Carries no colour deliberately -- the app's own theme (`colorScheme.primary`)
/// is already the brand, so [PortalStartupSplash], [PortalStartupGate] and
/// [PortalOnboardingPage] read that instead of a second source of truth.
class PortalAppIdentity {
  const PortalAppIdentity({
    required this.icon,
    required this.name,
    required this.tagline,
    this.logo,
  });

  final IconData icon;
  final String name;
  final String tagline;

  /// Drawn instead of [icon] when given (an app's own mark image).
  final ImageProvider? logo;
}
