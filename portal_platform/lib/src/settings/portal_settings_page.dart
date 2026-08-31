import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../auth/device_security/device_security_controller.dart';
import '../auth/device_security/portal_device_security_settings_tile.dart';
import '../session/session_controller.dart';
import '../update/portal_update_service.dart';
import '../update/portal_update_tile.dart';
import '../widgets/portal_app_version.dart';
import 'portal_apps_section.dart';
import 'portal_settings_labels.dart';
import 'portal_status_tile.dart';
import 'portal_theme_controller.dart';

/// One group of rows on [PortalSettingsPage].
class PortalSettingsSection {
  const PortalSettingsSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;
}

/// The groups this page can build for itself, in the order it builds them.
///
/// An app passes a subset to [PortalSettingsPage.include] to drop one, and
/// [PortalSettingsPage.order] to move its own sections somewhere other than
/// the default slot.
enum PortalSettingsGroup { profile, appearance, custom, assistant, status, apps, about }

/// The settings every Portal app has, in one page.
///
/// Everything here is app-independent: the profile is one shared record, the
/// theme mode is a preference, the server and assistant are the same backend,
/// and the app list is the same published manifest. An app supplies only what
/// is genuinely its own — [sections] for its features, [aiSection] for the
/// backend picker (which lives in `portal_ai`, a package above this one).
///
/// Plain Material by default, for the same reason [PortalUpdateTile] is:
/// `portal_platform` sits below the UI kit. An app with its own settings
/// chrome passes [sectionBuilder] rather than forking the page —
/// `portal_finance` does, to keep its bordered cards.
///
/// An app whose settings screen is too different to mount this at all can
/// still use the pieces: [PortalStatusSection], [PortalAppsSection] and
/// [PortalUpdateTile] each stand alone, which is how `portal_task` uses them.
///
/// See `docs/SETTINGS.md`.
class PortalSettingsPage extends StatelessWidget {
  const PortalSettingsPage({
    super.key,
    this.labels = const PortalSettingsLabels(),
    this.themeController,
    this.palettes = const [],
    this.aiSection,
    this.sections = const [],
    this.include = PortalSettingsGroup.values,
    this.order = PortalSettingsGroup.values,
    this.sectionBuilder,
    this.backgroundColor,
  });

  final PortalSettingsLabels labels;

  /// Omit to hide the appearance section entirely — an app that does not let
  /// the user change the theme should not show a control that does nothing.
  final PortalThemeController? themeController;

  /// Selectable palettes. Empty hides the colour picker: an app with a
  /// hand-built theme has nothing to switch between.
  final List<PortalPaletteOption> palettes;

  /// The app's AI backend picker, e.g. `AiBackendSelector` from `portal_ai`.
  final Widget? aiSection;

  /// App-specific groups, rendered where [PortalSettingsGroup.custom] falls.
  final List<PortalSettingsSection> sections;

  /// Groups to build at all. Anything absent is skipped.
  final List<PortalSettingsGroup> include;

  /// Order to build them in. Anything absent from [include] is skipped either
  /// way, so an app that only reorders can leave `include` alone.
  final List<PortalSettingsGroup> order;

  /// Renders one group. Default is an uppercase label above bare rows.
  final Widget Function(String title, List<Widget> children)? sectionBuilder;

  final Color? backgroundColor;

  static const _padding = EdgeInsets.symmetric(horizontal: 16);

  @override
  Widget build(BuildContext context) {
    final updates = Get.isRegistered<PortalUpdateService>()
        ? Get.find<PortalUpdateService>()
        : null;
    final build = sectionBuilder ?? _defaultSection;

    final children = <Widget>[];
    for (final group in order) {
      if (!include.contains(group)) continue;
      switch (group) {
        case PortalSettingsGroup.profile:
          if (Get.isRegistered<SessionController>()) {
            children.add(_ProfileCard(labels: labels));
          }

        case PortalSettingsGroup.appearance:
          final theme = themeController;
          if (theme == null) break;
          children.add(build(labels.appearance, [
            _ThemeModePicker(controller: theme),
            if (palettes.isNotEmpty)
              _PalettePicker(controller: theme, palettes: palettes),
          ]));

        case PortalSettingsGroup.custom:
          for (final section in sections) {
            children.add(build(section.title, section.children));
          }

        case PortalSettingsGroup.assistant:
          final ai = aiSection;
          if (ai == null) break;
          children.add(
            build(labels.assistant, [Padding(padding: _padding, child: ai)]),
          );

        case PortalSettingsGroup.status:
          children.add(build(labels.status, [
            PortalStatusSection(contentPadding: _padding, labels: labels),
          ]));

        case PortalSettingsGroup.apps:
          // Gated on the same predicate the section itself uses, so iOS and a
          // build with no manifest URL get no empty heading.
          if (updates == null || !portalCanInstallApps(updates)) break;
          children.add(build(labels.portalApps, [
            PortalAppsSection(
              service: updates,
              contentPadding: _padding,
              labels: labels,
            ),
          ]));

        case PortalSettingsGroup.about:
          children.add(build(labels.about, [
            if (updates != null)
              PortalUpdateTile(service: updates, title: labels.appVersion)
            else
              PortalAppVersionListTile(title: labels.appVersion),
            if (Get.isRegistered<DeviceSecurityController>())
              const PortalDeviceSecuritySettingsTile(contentPadding: _padding),
            if (Get.isRegistered<SessionController>())
              _SignOutTile(labels: labels),
          ]));
      }
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(title: Text(labels.title)),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: children,
      ),
    );
  }

  static Widget _defaultSection(String title, List<Widget> children) =>
      _Section(title: title, children: children);
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

class _SignOutTile extends StatelessWidget {
  const _SignOutTile({required this.labels});

  final PortalSettingsLabels labels;

  Future<void> _signOut(BuildContext context) async {
    final session = Get.find<SessionController>();
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
    if (confirmed == true) await session.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListTile(
      contentPadding: PortalSettingsPage._padding,
      leading: Icon(Icons.logout_rounded, color: cs.error),
      title: Text(labels.signOut, style: TextStyle(color: cs.error)),
      onTap: () => _signOut(context),
    );
  }
}

/// Name, email and initials for the one profile every Portal app shares.
class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.labels});

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
        title: Text(name.isEmpty ? labels.profileFallbackTitle : name),
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
