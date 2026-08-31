import 'dart:io';

import 'package:flutter/material.dart';

import '../update/portal_release.dart';
import '../update/portal_update_service.dart';
import '../update/portal_update_tile.dart';

/// The other Portal apps, installable from inside this one.
///
/// The published `updates.json` already lists every app with its APK, size and
/// checksum, so this is that manifest rendered as a list — no second index and
/// no new endpoint. Installing reuses the update path exactly: download,
/// verify the SHA-256, hand the file to Android's PackageInstaller.
///
/// ponytail: no installed/not-installed state. Knowing that needs Android
/// package-visibility `<queries>` entries in every app manifest; Android's own
/// installer already says "Install" or "Update" on the confirmation it shows,
/// so the only thing lost is the label on the button here. Add the `<queries>`
/// block if the list ever needs to sort installed apps to the top.
class PortalAppsSection extends StatefulWidget {
  const PortalAppsSection({
    super.key,
    required this.service,
    this.contentPadding,
  });

  final PortalUpdateService service;
  final EdgeInsetsGeometry? contentPadding;

  @override
  State<PortalAppsSection> createState() => _PortalAppsSectionState();
}

class _PortalAppsSectionState extends State<PortalAppsSection> {
  List<PortalRelease>? _apps;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _apps = null;
      _error = null;
    });
    try {
      final manifest = await widget.service.fetchManifest();
      if (!mounted) return;
      setState(() => _apps = manifest.others(widget.service.slug));
    } on PortalUpdateException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Could not load the app list.');
    }
  }

  Future<void> _install(PortalRelease release) async {
    await showPortalUpdateDialog(
      context,
      widget.service,
      release,
      title: 'Install ${release.displayName}',
      // Not this app's build, so a "not now" must not touch this app's
      // dismissed-version key.
      rememberRefusal: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final padding = widget.contentPadding;

    // Sideloading is an Android-only path; the manifest names APKs.
    if (!Platform.isAndroid) return const SizedBox.shrink();

    if (_error != null) {
      return ListTile(
        contentPadding: padding,
        leading: Icon(Icons.apps_outlined, color: cs.onSurfaceVariant),
        title: const Text('Portal apps'),
        subtitle: Text(_error!),
        trailing: IconButton(
          tooltip: 'Try again',
          onPressed: _load,
          icon: const Icon(Icons.refresh_rounded),
        ),
      );
    }

    final apps = _apps;
    if (apps == null) {
      return const ListTile(
        title: Text('Portal apps'),
        subtitle: Text('Loading…'),
        trailing: SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    if (apps.isEmpty) {
      return ListTile(
        contentPadding: padding,
        leading: Icon(Icons.apps_outlined, color: cs.onSurfaceVariant),
        title: const Text('Portal apps'),
        subtitle: const Text('No other apps published yet'),
      );
    }

    return Column(
      children: [
        for (final app in apps)
          ListTile(
            contentPadding: padding,
            leading: CircleAvatar(
              backgroundColor: cs.surfaceContainerHighest,
              child: Icon(_iconFor(app.slug), color: cs.onSurfaceVariant),
            ),
            title: Text(app.displayName),
            subtitle: Text(
              [
                if (app.versionName.isNotEmpty) 'v${app.versionName}',
                if (app.readableSize.isNotEmpty) app.readableSize,
              ].join('  ·  '),
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: cs.onSurfaceVariant),
            ),
            trailing: TextButton(
              onPressed: () => _install(app),
              child: const Text('Install'),
            ),
          ),
      ],
    );
  }

  /// Best-effort icon per app. An unknown slug still lists and still installs.
  static IconData _iconFor(String slug) => switch (slug) {
        'portal-recipe' => Icons.restaurant_menu,
        'portal-gym' => Icons.fitness_center,
        'portal-shopping' => Icons.shopping_bag_outlined,
        'portal-lifestyle' => Icons.spa_outlined,
        'portal-productivity' => Icons.check_circle_outline,
        'portal-finance' => Icons.account_balance_outlined,
        'portal-task' => Icons.task_alt,
        _ => Icons.apps_outlined,
      };
}
