import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../update/portal_release.dart';
import '../update/portal_update_service.dart';
import '../update/portal_update_tile.dart';
import 'portal_settings_labels.dart';

/// Whether this build can show and install sibling apps at all.
///
/// Android only, and only when a manifest URL was configured. A caller uses
/// this to decide whether to render a section *heading* — otherwise iOS gets
/// a "Portal apps" label with nothing under it.
bool portalCanInstallApps(PortalUpdateService service) =>
    Platform.isAndroid && service.isEnabled;

/// The other Portal apps, installable from inside this one.
///
/// The published `updates.json` already lists every app with its APK, size and
/// checksum, so this is that manifest rendered as a list — no second index and
/// no new endpoint. Installing reuses the update path exactly: download,
/// verify the SHA-256, hand the file to Android's PackageInstaller.
///
/// Safe to drop into an app's own settings screen; `portal_task` does exactly
/// that. Pass [labels] to translate it, [tileBuilder] to restyle it.
///
/// Installed apps say **Open** and launch; the rest say **Install**. That works
/// off each app's `portal-x://` scheme rather than a package query, so the only
/// thing this app learns about the device is whether a Portal app answers a
/// Portal scheme. Both halves need the `<queries>` block in the manifest —
/// without it `canLaunchUrl` is false on Android 11+ and everything looks
/// uninstalled, which is why [portalAppUri] and the manifests must agree.
class PortalAppsSection extends StatefulWidget {
  const PortalAppsSection({
    super.key,
    required this.service,
    this.contentPadding,
    this.labels = const PortalSettingsLabels(),
    this.tileBuilder,
  });

  final PortalUpdateService service;
  final EdgeInsetsGeometry? contentPadding;
  final PortalSettingsLabels labels;

  /// Renders one app row. Given the release, whether tapping it opens or
  /// installs, and the callback that does it — so an app with its own row
  /// widget can use it instead of the [ListTile] here.
  final Widget Function(
    PortalRelease release,
    PortalAppAction action,
    VoidCallback onTap,
  )? tileBuilder;

  @override
  State<PortalAppsSection> createState() => _PortalAppsSectionState();
}

class _PortalAppsSectionState extends State<PortalAppsSection>
    with WidgetsBindingObserver {
  List<PortalRelease>? _apps;
  String? _error;

  /// Slugs that answered their scheme. Absent means "not installed, or we
  /// could not tell" — both lead to Install, which is the safe offer either
  /// way: Android turns an install of something already present into an
  /// update rather than a failure.
  final _installed = <String>{};

  bool _refreshing = false;
  bool _batching = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (portalCanInstallApps(widget.service)) _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Installing leaves for Android's installer and comes back, so resuming is
  /// the one moment this list is reliably wrong: the row that was just
  /// installed still says Install. Re-probing here is what makes the state
  /// look after itself; nothing else notices the install happened.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _apps != null) _probeInstalled();
  }

  /// Asks each listed app whether it is there. Cheap enough to repeat, but not
  /// per-rebuild: it is a platform round-trip per app and the list rebuilds on
  /// every scroll frame.
  Future<void> _probeInstalled() async {
    final apps = _apps;
    if (apps == null) return;
    if (mounted) setState(() => _refreshing = true);
    final found = <String>{};
    for (final app in apps) {
      if (await _isInstalled(app.slug)) found.add(app.slug);
    }
    if (!mounted) return;
    setState(() {
      _refreshing = false;
      _installed
        ..clear()
        ..addAll(found);
    });
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
      await _probeInstalled();
    } on PortalUpdateException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = widget.labels.appListFailed);
    }
  }

  /// Never throws: a platform that has no answer is simply not installed.
  static Future<bool> _isInstalled(String slug) async {
    try {
      return await canLaunchUrl(portalAppUri(slug));
    } catch (_) {
      return false;
    }
  }

  Future<void> _open(PortalRelease release) async {
    try {
      await launchUrl(portalAppUri(release.slug));
    } catch (_) {
      // The app answered the query and then would not open. Nothing useful to
      // say about that beyond leaving the row alone.
    }
  }

  Future<void> _install(PortalRelease release) async {
    await showPortalUpdateDialog(
      context,
      widget.service,
      release,
      title: '${widget.labels.install} ${release.displayName}',
      // Not this app's build, so a "not now" must not touch this app's
      // dismissed-version key.
      rememberRefusal: false,
    );
    // Belt to the lifecycle braces: the dialog can finish without the app ever
    // having been backgrounded (a refusal, a failed download), and then no
    // resume fires to correct the row.
    await _probeInstalled();
  }

  /// Downloads every app that is not installed, then hands them to Android's
  /// installer one after another.
  ///
  /// Two phases on purpose. Downloading is the slow, unattended part and the
  /// part that can fail on its own terms — a bad checksum, a dead network — so
  /// it finishes before the user is asked to do anything. They then sit through
  /// the confirmations back to back instead of waiting out a download between
  /// each one.
  ///
  /// Serial in both phases. Android's PackageInstaller reports its verdict
  /// through the host activity's onNewIntent, so two sessions in flight would
  /// have no way to tell which answer belonged to which app.
  Future<void> _runInstallAll(List<PortalRelease> pending) async {
    setState(() => _batching = true);
    try {
      await _installAll(pending);
    } finally {
      if (mounted) setState(() => _batching = false);
    }
  }

  Future<void> _installAll(List<PortalRelease> pending) async {
    final labels = widget.labels;
    final status = ValueNotifier<String>('');
    final progress = ValueNotifier<double>(-1);

    unawaited(
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Text(labels.installAll),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ValueListenableBuilder<String>(
                valueListenable: status,
                builder: (context, value, _) => Text(value),
              ),
              const SizedBox(height: 12),
              ValueListenableBuilder<double>(
                valueListenable: progress,
                builder: (context, value, _) =>
                    LinearProgressIndicator(value: value < 0 ? null : value),
              ),
            ],
          ),
        ),
      ),
    );

    // Kept in order so the install prompts arrive in the order the list showed.
    final downloaded = <PortalRelease, File>{};
    final failed = <String>[];

    for (var i = 0; i < pending.length; i++) {
      final release = pending[i];
      status.value =
          '${labels.downloading} ${i + 1}/${pending.length} — ${release.displayName}';
      progress.value = -1;
      try {
        downloaded[release] = await widget.service.download(
          release,
          onProgress: (p) => progress.value = p,
        );
      } catch (e) {
        // One bad download must not cost the user the other four. Its name is
        // carried to the summary rather than thrown away.
        failed.add(release.displayName);
      }
    }

    if (mounted) Navigator.of(context).pop();
    status.dispose();
    progress.dispose();

    var installed = 0;
    for (final entry in downloaded.entries) {
      try {
        await widget.service.install(entry.value);
        installed++;
      } catch (e) {
        // Includes the user declining a prompt, which is a normal answer and
        // not worth interrupting the remaining ones over.
        failed.add(entry.key.displayName);
      } finally {
        // ~65 MB each. Leaving five of them in the cache directory because the
        // install already read the bytes would be a rude way to save a line.
        try {
          if (await entry.value.exists()) await entry.value.delete();
        } catch (_) {}
      }
    }

    await _probeInstalled();
    if (!mounted) return;

    final summary = failed.isEmpty
        ? '${labels.installAllDone} ($installed)'
        : '${labels.installAllDone} ($installed) — '
            '${labels.installAllFailed}: ${failed.join(', ')}';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(summary)));
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final padding = widget.contentPadding;
    final labels = widget.labels;

    // Sideloading is an Android-only path and needs a manifest; a caller that
    // renders a heading should gate it on portalCanInstallApps too.
    if (!portalCanInstallApps(widget.service)) return const SizedBox.shrink();

    if (_error != null) {
      return ListTile(
        contentPadding: padding,
        leading: Icon(Icons.apps_outlined, color: cs.onSurfaceVariant),
        title: Text(labels.portalApps),
        subtitle: Text(_error!),
        trailing: IconButton(
          tooltip: labels.tryAgain,
          onPressed: _load,
          icon: const Icon(Icons.refresh_rounded),
        ),
      );
    }

    final apps = _apps;
    if (apps == null) {
      return ListTile(
        contentPadding: padding,
        title: Text(labels.portalApps),
        subtitle: Text(labels.loading),
        trailing: const SizedBox.square(
          dimension: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    if (apps.isEmpty) {
      return ListTile(
        contentPadding: padding,
        leading: Icon(Icons.apps_outlined, color: cs.onSurfaceVariant),
        title: Text(labels.portalApps),
        subtitle: Text(labels.noOtherApps),
      );
    }

    final pending =
        apps.where((a) => !_installed.contains(a.slug)).toList(growable: false);

    return Column(
      children: [
        for (final app in apps)
          widget.tileBuilder?.call(
                app,
                _installed.contains(app.slug)
                    ? PortalAppAction.open
                    : PortalAppAction.install,
                () => _installed.contains(app.slug)
                    ? _open(app)
                    : _install(app),
              ) ??
              ListTile(
                contentPadding: padding,
                leading: CircleAvatar(
                  backgroundColor: cs.surfaceContainerHighest,
                  child: Icon(portalAppIconFor(app.slug), color: cs.onSurfaceVariant),
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
                trailing: _installed.contains(app.slug)
                    ? TextButton(
                        onPressed: () => _open(app),
                        child: Text(labels.open),
                      )
                    : TextButton(
                        onPressed: () => _install(app),
                        child: Text(labels.install),
                      ),
              ),
        // Only worth offering for more than one: for a single app it is the
        // row's own button with an extra confirmation in front of it.
        if (pending.length > 1)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _batching ? null : () => _runInstallAll(pending),
                icon: const Icon(Icons.download_rounded, size: 18),
                label: Text('${labels.installAll} (${pending.length})'),
              ),
            ),
          ),
        // A force-check. Resuming re-probes on its own, but an app installed
        // through some other route while this screen was already open leaves
        // no signal at all, and "why does it still say Install" is not
        // something a user should have to guess their way out of.
        TextButton.icon(
          onPressed: _refreshing ? null : _probeInstalled,
          icon: _refreshing
              ? const SizedBox.square(
                  dimension: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.refresh_rounded, size: 18),
          label: Text(labels.checkAgain),
        ),
      ],
    );
  }

}

/// Best-effort icon per app. An unknown slug still lists and still installs.
///
/// Top-level so a [PortalAppsSection.tileBuilder] can reuse it rather than
/// repeating the map.
IconData portalAppIconFor(String slug) => switch (slug) {
      'portal-recipe' => Icons.restaurant_menu,
      'portal-gym' => Icons.fitness_center,
      'portal-shopping' => Icons.shopping_bag_outlined,
      'portal-lifestyle' => Icons.spa_outlined,
      'portal-productivity' => Icons.check_circle_outline,
      'portal-finance' => Icons.account_balance_outlined,
      'portal-task' => Icons.task_alt,
      _ => Icons.apps_outlined,
    };

/// What tapping an app row does.
enum PortalAppAction { open, install }

/// The scheme a Portal app answers on: `portal-gym` -> `portal-gym://open`.
///
/// Must match the `<data android:scheme>` in that app's manifest and the
/// `<queries>` entries in every other app's. The manifest slug and the update
/// manifest's key are the same string, so there is one name to keep in step,
/// not two.
Uri portalAppUri(String slug) => Uri(scheme: slug, host: 'open');
