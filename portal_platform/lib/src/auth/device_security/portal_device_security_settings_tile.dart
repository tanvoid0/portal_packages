import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'device_security_controller.dart';

/// Reusable settings row with a switch for device security.
class PortalDeviceSecuritySettingsTile extends StatelessWidget {
  const PortalDeviceSecuritySettingsTile({
    super.key,
    this.contentPadding = const EdgeInsets.symmetric(horizontal: 16),
  });

  final EdgeInsetsGeometry contentPadding;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<DeviceSecurityController>();
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Obx(() {
      final supported = controller.isSupported.value;
      final subtitle = supported
          ? controller.strings.settingsSubtitle
          : controller.strings.unavailableSubtitle;

      return SwitchListTile(
        contentPadding: contentPadding,
        title: Text(
          controller.strings.settingsTitle,
          style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          subtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: cs.onSurfaceVariant,
            height: 1.35,
          ),
        ),
        value: controller.enabled.value,
        onChanged: supported && !controller.isBusy.value
            ? controller.setEnabled
            : null,
      );
    });
  }
}
