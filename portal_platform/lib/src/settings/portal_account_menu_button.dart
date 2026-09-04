import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../session/session_controller.dart';
import 'portal_avatar.dart';
import 'portal_settings_labels.dart';

/// App-bar avatar with a menu: who is signed in, settings, sign out.
///
/// Lifted from `portal_lifestyle` and `portal_productivity`, which had
/// byte-identical copies of it. Their versions pulled in each app's
/// `DesignTokens` and `ConfirmationDialog`; neither was doing anything the
/// theme's own text styles and a plain [AlertDialog] do not.
///
/// [settingsRoute] is null for an app with no settings screen, and the entry
/// is simply not shown.
class PortalAccountMenuButton extends StatelessWidget {
  const PortalAccountMenuButton({
    super.key,
    this.settingsRoute,
    this.labels = const PortalSettingsLabels(),
    this.radius = 18,
    this.onSignOut,
  });

  final String? settingsRoute;
  final PortalSettingsLabels labels;
  final double radius;

  /// Overrides the default [SessionController.signOut] when an app keeps a
  /// second, app-local auth stack alongside the shared session (portal_finance:
  /// its dashboard is otherwise the only sign-out entry point, and the shared
  /// sign-out alone would clear this menu's session while leaving the rest of
  /// the app's screens still showing the signed-in user's data).
  final Future<void> Function()? onSignOut;

  Future<void> _confirmSignOut(
    BuildContext context,
    SessionController session,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(labels.signOutConfirmTitle),
        content: Text(labels.signOutConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(labels.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(labels.signOut),
          ),
        ],
      ),
    );
    if (confirmed == true) await (onSignOut?.call() ?? session.signOut());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final session = Get.find<SessionController>();

    return Obx(() {
      final user = session.user.value;
      final signedIn = user != null;
      final name = (user?['name'] as String?)?.trim() ?? '';
      final email = (user?['email'] as String?)?.trim() ?? '';

      return Padding(
        padding: const EdgeInsets.only(right: 4),
        child: PopupMenuButton<String>(
          tooltip: labels.profileFallbackTitle,
          offset: const Offset(0, kToolbarHeight - 8),
          onSelected: (value) async {
            switch (value) {
              case 'settings':
                if (settingsRoute != null) Get.toNamed(settingsRoute!);
              case 'logout':
                await _confirmSignOut(context, session);
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem<String>(
              enabled: false,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    signedIn && name.isNotEmpty
                        ? name
                        : signedIn
                            ? labels.profileFallbackTitle
                            : labels.notSignedIn,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  if (email.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      email,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: cs.onSurfaceVariant),
                    ),
                  ],
                ],
              ),
            ),
            const PopupMenuDivider(),
            if (settingsRoute != null)
              PopupMenuItem<String>(
                value: 'settings',
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.settings_outlined),
                  title: Text(labels.title),
                ),
              ),
            PopupMenuItem<String>(
              value: 'logout',
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.logout_rounded),
                title: Text(labels.signOut),
              ),
            ),
          ],
          child: PortalAvatar(user: user, radius: radius, fontSize: 14),
        ),
      );
    });
  }
}
