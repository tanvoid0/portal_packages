import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../session/session_controller.dart';
import 'portal_avatar.dart';
import 'portal_settings_labels.dart';

/// App-bar avatar that opens settings.
///
/// Was a popup menu repeating the signed-in identity and a sign-out entry;
/// the settings page shows both already, so the menu was one tap in the way.
///
/// [settingsRoute] is null for an app with no settings screen, and the avatar
/// is then decorative.
class PortalAccountMenuButton extends StatelessWidget {
  const PortalAccountMenuButton({
    super.key,
    this.settingsRoute,
    this.labels = const PortalSettingsLabels(),
    this.radius = 18,
  });

  final String? settingsRoute;
  final PortalSettingsLabels labels;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final session = Get.find<SessionController>();

    return Obx(() {
      final avatar = PortalAvatar(
        user: session.user.value,
        radius: radius,
        fontSize: 14,
      );
      if (settingsRoute == null) {
        return Padding(padding: const EdgeInsets.only(right: 4), child: avatar);
      }
      return Padding(
        padding: const EdgeInsets.only(right: 4),
        child: IconButton(
          tooltip: labels.title,
          icon: avatar,
          onPressed: () => Get.toNamed(settingsRoute!),
        ),
      );
    });
  }
}
