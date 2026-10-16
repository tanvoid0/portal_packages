import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

import 'device_security_controller.dart';

/// Reusable settings row with a switch for device security — a
/// [PortalListItem], not a bare [SwitchListTile], so it matches the rest of
/// [PortalSettingsPage]'s coalesced row style (lime icon tile, same
/// title/subtitle treatment) instead of standing out as a separate card.
class PortalDeviceSecuritySettingsTile extends StatelessWidget {
  const PortalDeviceSecuritySettingsTile({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<DeviceSecurityController>();

    return Obx(() {
      final supported = controller.isSupported.value;
      final subtitle = supported
          ? controller.strings.settingsSubtitle
          : controller.strings.unavailableSubtitle;

      return PortalListItem(
        leading: PortalListLeading.tile(Icons.lock_outline_rounded),
        title: controller.strings.settingsTitle,
        subtitle: subtitle,
        titleMaxLines: 2,
        enabled: supported && !controller.isBusy.value,
        // PortalListItem already nulls this when `enabled` above is false.
        trailing: PortalListAccessory.switchControl(
          checked: controller.enabled.value,
          onChanged: controller.setEnabled,
        ),
      );
    });
  }
}
