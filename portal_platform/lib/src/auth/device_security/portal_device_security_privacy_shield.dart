import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

/// Blurs app content so nothing readable shows behind device-security UI.
class PortalDeviceSecurityPrivacyShield extends StatelessWidget {
  const PortalDeviceSecurityPrivacyShield({super.key});

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surface;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
        child: ColoredBox(
          color: surface.withValues(alpha: 0.82),
        ),
      ),
    );
  }
}

/// Full-screen spinner shown while the guard is verifying (before / during unlock).
class PortalDeviceSecurityCheckingOverlay extends StatelessWidget {
  const PortalDeviceSecurityCheckingOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SizedBox(
        width: 36,
        height: 36,
        child: CircularProgressIndicator(strokeWidth: 3),
      ),
    );
  }
}
