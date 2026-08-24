import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'device_security_controller.dart';
import 'portal_device_security_lock_view.dart';
import 'portal_device_security_privacy_shield.dart';

/// Overlays [PortalDeviceSecurityLockView] when device security is enabled and locked.
///
/// Pass [shouldGuard] to hide the lock on routes such as login. When guard becomes
/// true and security is enabled, the app locks until the user authenticates.
class PortalDeviceSecurityGate extends StatefulWidget {
  const PortalDeviceSecurityGate({
    super.key,
    required this.child,
    required this.shouldGuard,
  });

  final Widget child;
  final bool shouldGuard;

  @override
  State<PortalDeviceSecurityGate> createState() =>
      _PortalDeviceSecurityGateState();
}

class _PortalDeviceSecurityGateState extends State<PortalDeviceSecurityGate> {
  DeviceSecurityController get _controller => Get.find<DeviceSecurityController>();

  @override
  void initState() {
    super.initState();
    _controller.updateShouldGuard(widget.shouldGuard);
    if (widget.shouldGuard) {
      _controller.scheduleAutoUnlock();
    }
  }

  @override
  void didUpdateWidget(covariant PortalDeviceSecurityGate oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.shouldGuard != widget.shouldGuard) {
      _controller.updateShouldGuard(widget.shouldGuard);
      if (widget.shouldGuard) {
        _controller.scheduleAutoUnlock();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        Obx(() {
          // Read observables before any short-circuit; otherwise Obx on login
          // (shouldGuard == false) never subscribes and GetX throws.
          final locked = _controller.isLocked.value;
          final busy = _controller.isBusy.value;
          if (!_controller.shouldShieldApp(widget.shouldGuard)) {
            return const SizedBox.shrink();
          }
          return Positioned.fill(
            child: Stack(
              fit: StackFit.expand,
              children: [
                const PortalDeviceSecurityPrivacyShield(),
                if (busy)
                  const PortalDeviceSecurityCheckingOverlay()
                else if (locked)
                  const PortalDeviceSecurityLockView(),
              ],
            ),
          );
        }),
      ],
    );
  }
}
