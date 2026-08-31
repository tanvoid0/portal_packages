import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../auth/device_security/device_security_controller.dart';
import '../auth/device_security/portal_device_security_settings_tile.dart';
import '../session/session_controller.dart';
import '../update/portal_update_service.dart';
import '../update/portal_update_tile.dart';
import '../widgets/portal_app_version.dart';
import 'portal_apps_section.dart';
import 'portal_status_tile.dart';
import 'portal_theme_controller.dart';

/// The settings every Portal app has, in one page.
///
/// Everything here is app-independent: the profile is one shared record, the
/// theme mode is a preference, the server and assistant are the same backend,
/// and the app list is the same published manifest. An app supplies only what
/// is genuinely its own — [sections] for its features, [aiSection] for the
/// backend picker (which lives in `portal_ai`, a package above this one).
///
/// Plain Material on purpose, for the same reason [PortalUpdateTile] is:
/// `portal_platform` sits below the UI kit. Host apps restyle through the
/// theme, not by forking this page.
class PortalSettingsPage extends StatelessWidget {
  const PortalSettingsPage({
    super.key,
    this.title = 'Settings',
    this.themeController,
    this.palettes = const [],
    this.aiSection,
    this.sections = const [],
    this.showApps = true,
    this.showProfile = true,
  });

  final String title;

  /// Omit to hide the appearance section entirely — an app that does not let
  /// the user change the theme should not show a control that does nothing.
  final PortalThemeController? themeController;

  /// Selectable palettes. Empty hides the colour picker: an app with a
  /// hand-built theme has nothing to switch between.
  final List<PortalPaletteOption> palettes;

  /// The app's AI backend picker, e.g. `AiBackendSelector` from `portal_ai`.
  final Widget? aiSection;

  /// App-specific groups, inserted after appearance and before status.
  final List<PortalSettingsSection> sections;

  final bool showApps;
  final bool showProfile;

  static const _padding = EdgeInsets.symmetric(horizontal: 16);

  @override
  Widget build(BuildContext context) {
    final updates = Get.isRegistered<PortalUpdateService>()
        ? Get.find<PortalUpdateService>()
        : null;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          if (showProfile && Get.isRegistered<SessionController>())
            const _ProfileCard(),
          if (themeController != null)
            _Section(
              title: 'Appearance',
              children: [
                _ThemeModePicker(controller: themeController!),
                if (palettes.isNotEmpty)
                  _PalettePicker(
                    controller: themeController!,
                    palettes: palettes,
                  ),
              ],
            ),
          for (final section in sections)
            _Section(title: section.title, children: section.children),
          if (aiSection != null)
            _Section(
              title: 'Assistant',
              children: [Padding(padding: _padding, child: aiSection!)],
            ),
          const _Section(
            title: 'Status',
            children: [PortalStatusSection(contentPadding: _padding)],
          ),
          if (showApps && updates != null && updates.isEnabled)
            _Section(
              title: 'Portal apps',
              children: [
                PortalAppsSection(service: updates, contentPadding: _padding),
              ],
            ),
          _Section(
            title: 'About',
            children: [
              if (updates != null)
                PortalUpdateTile(service: updates)
              else
                const PortalAppVersionListTile(title: 'App version'),
              if (Get.isRegistered<DeviceSecurityController>())
                const PortalDeviceSecuritySettingsTile(
                  contentPadding: _padding,
                ),
              if (Get.isRegistered<SessionController>())
                ListTile(
                  contentPadding: _padding,
                  leading: Icon(Icons.logout_rounded, color: cs.error),
                  title: Text('Sign out', style: TextStyle(color: cs.error)),
                  onTap: () => Get.find<SessionController>().signOut(),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// An app-specific group on [PortalSettingsPage].
class PortalSettingsSection {
  const PortalSettingsSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Text(
            title.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.primary,
              letterSpacing: 1.1,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        ...children,
      ],
    );
  }
}

/// Name, email and initials for the one profile every Portal app shares.
class _ProfileCard extends StatelessWidget {
  const _ProfileCard();

  Future<void> _rename(BuildContext context, String current) async {
    final field = TextEditingController(text: current);
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Your name'),
        content: TextField(
          controller: field,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            helperText: 'Shared by every Portal app',
          ),
          onSubmitted: (v) => Navigator.of(context).pop(v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(field.text),
            child: const Text('Save'),
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
        const SnackBar(content: Text('Could not save your name.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = Get.find<SessionController>();
    final cs = Theme.of(context).colorScheme;

    return Obx(() {
      final user = session.user.value;
      if (user == null) return const SizedBox.shrink();
      final name = (user['name'] as String?)?.trim() ?? '';
      final email = (user['email'] as String?)?.trim() ?? '';

      return ListTile(
        contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: cs.primaryContainer,
          child: Text(
            SessionController.initialsFor(user),
            style: TextStyle(
              color: cs.onPrimaryContainer,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        title: Text(name.isEmpty ? 'Your profile' : name),
        subtitle: Text(email, maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: const Icon(Icons.edit_outlined),
        onTap: () => _rename(context, name),
      );
    });
  }
}

class _ThemeModePicker extends StatelessWidget {
  const _ThemeModePicker({required this.controller});

  final PortalThemeController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: PortalSettingsPage._padding,
      child: Obx(
        () => SegmentedButton<ThemeMode>(
          showSelectedIcon: false,
          segments: [
            for (final mode in ThemeMode.values)
              ButtonSegment(
                value: mode,
                label: Text(PortalThemeController.labelFor(mode)),
                icon: Icon(PortalThemeController.iconFor(mode), size: 18),
              ),
          ],
          selected: {controller.themeMode.value},
          onSelectionChanged: (s) => controller.setThemeMode(s.first),
        ),
      ),
    );
  }
}

class _PalettePicker extends StatelessWidget {
  const _PalettePicker({required this.controller, required this.palettes});

  final PortalThemeController controller;
  final List<PortalPaletteOption> palettes;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Obx(
        () => Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final p in palettes)
              InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: () => controller.setPaletteId(p.id),
                child: Tooltip(
                  message: p.label,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: p.swatch,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: controller.paletteId.value == p.id
                            ? Theme.of(context).colorScheme.onSurface
                            : Colors.transparent,
                        width: 3,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
