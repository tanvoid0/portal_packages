import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../session/session_controller.dart';
import 'portal_avatar.dart';
import 'portal_settings_labels.dart';

/// The signed-in profile: photo, name, email, and a tap to rename.
///
/// Lives outside [PortalSettingsPage] so an app with its own settings chrome
/// can still show the same row -- `portal_task` builds its settings hub by
/// hand and was the only app without a profile anywhere, which meant no photo
/// and no way to rename in the app where Google sign-in landed first.
///
/// Renders nothing when signed out.

class PortalProfileTile extends StatelessWidget {
  const PortalProfileTile({super.key, this.labels = const PortalSettingsLabels()});

  final PortalSettingsLabels labels;

  Future<void> _rename(BuildContext context, String current) async {
    final field = TextEditingController(text: current);
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(labels.nameDialogTitle),
        content: TextField(
          controller: field,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(helperText: labels.nameDialogHelper),
          onSubmitted: (v) => Navigator.of(context).pop(v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(labels.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(field.text),
            child: Text(labels.save),
          ),
        ],
      ),
    );
    field.dispose();

    final trimmed = name?.trim() ?? '';
    if (trimmed.isEmpty || trimmed == current) return;
    try {
      await Get.find<SessionController>().updateName(trimmed);
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(labels.nameSaveFailed)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = Get.find<SessionController>();

    return Obx(() {
      final user = session.user.value;
      if (user == null) return const SizedBox.shrink();
      final name = (user['name'] as String?)?.trim() ?? '';
      final email = (user['email'] as String?)?.trim() ?? '';

      return ListTile(
        contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        leading: PortalAvatar(user: user, radius: 24),
        title: Text(name.isEmpty ? labels.profileFallbackTitle : name),
        subtitle: Text(email, maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: const Icon(Icons.edit_outlined),
        onTap: () => _rename(context, name),
      );
    });
  }
}
