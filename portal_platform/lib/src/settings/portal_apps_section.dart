import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:portal_ui_core/portal_ui_core.dart';
import 'package:url_launcher/url_launcher.dart';

import '../update/portal_installed_apps.dart';
import '../update/portal_release.dart';
import '../update/portal_update_service.dart';
import '../update/portal_update_tile.dart';
import 'portal_settings_labels.dart';

/// Whether this build can show and install sibling apps at all.
///
/// Android only, and only when a manifest URL was configured. A caller uses
/// this to decide whether to render a section *heading* — otherwise iOS gets
/// a "Portal apps" label with nothing under it.
///
/// Reads Flutter's [defaultTargetPlatform] rather than `Platform.isAndroid`:
/// the same answer on a device, and a widget test can say it is on Android.
bool portalCanInstallApps(PortalUpdateService service) =>
    defaultTargetPlatform == TargetPlatform.android && service.isEnabled;

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
/// A row says **Install** when the app is absent, **Update** when the published
/// `versionCode` is higher than the installed one, and **Open** otherwise;
/// installed rows also carry an uninstall button. The installed version comes
/// from the PackageManager through [PortalInstalledApps], scoped to the Portal
/// packages named in this package's own `<queries>` block — an app whose
/// applicationId is not listed there reads as not installed. Opening still
/// goes through the `portal-x://` scheme, which needs the `<queries>` intent
/// block in each app manifest.
///
/// [PortalAppsSection.grouped] is the same list as a kit section for
/// `PortalSettingsPage`: it carries its own header, Check again lives on that
/// header, a long press on an installed row holds Uninstall (the row shows only
/// its one button, as the kit's settings recipe does), and Install / Update ask
/// first in a sheet. Same load, probe and install logic.
class PortalAppsSection extends StatefulWidget {
  const PortalAppsSection({
    super.key,
    required this.service,
    this.contentPadding,
    this.labels = const PortalSettingsLabels(),
    this.tileBuilder,
  }) : _grouped = false;

  const PortalAppsSection.grouped({
    super.key,
    required this.service,
    this.labels = const PortalSettingsLabels(),
  })  : contentPadding = null,
        tileBuilder = null,
        _grouped = true;

  final bool _grouped;

  final PortalUpdateService service;
  final EdgeInsetsGeometry? contentPadding;
  final PortalSettingsLabels labels;

  /// Renders one app row. Given the release, the installed build if there is
  /// one, what tapping it does, and the callback that does it — so an app with
  /// its own row widget can use it instead of the [ListTile] here.
  final Widget Function(
    PortalRelease release,
    PortalInstalledApp? installed,
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

  /// Installed builds by slug. Absent means "not installed, or we could not
  /// tell" — both lead to Install, which is the safe offer either way: Android
  /// turns an install of something already present into an update rather than
  /// a failure.
  final _installed = <String, PortalInstalledApp>{};

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

  /// Asks each listed app what version is installed. Cheap enough to repeat,
  /// but not per-rebuild: it is a platform round-trip per app and the list
  /// rebuilds on every scroll frame.
  Future<void> _probeInstalled() async {
    final apps = _apps;
    if (apps == null) return;
    if (mounted) setState(() => _refreshing = true);
    final found = <String, PortalInstalledApp>{};
    for (final app in apps) {
      final info = await PortalInstalledApps.version(app.slug);
      if (info != null) found[app.slug] = info;
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

  /// Scheme first, launch activity second.
  ///
  /// The scheme is the app's own front door and lands on whatever it routes
  /// `open` to. But it only exists if that app declared the intent filter —
  /// `portal_launcher` declares none — and `launchUrl` throws rather than
  /// returning false when nothing handles it. The PackageManager fallback
  /// needs no cooperation from the other side.
  Future<void> _open(PortalRelease release) async {
    try {
      if (await launchUrl(portalAppUri(release.slug))) return;
    } catch (_) {
      // Nothing registered for the scheme; the fallback below is the answer.
    }
    await PortalInstalledApps.launch(release.slug);
  }

  PortalAppAction _actionFor(PortalRelease release) =>
      portalAppActionFor(release, _installed[release.slug]);

  void _tap(PortalRelease release) => switch (_actionFor(release)) {
        PortalAppAction.open => _open(release),
        PortalAppAction.install || PortalAppAction.update =>
          widget._grouped ? _installSheet(release) : _install(release),
      };

  /// Hands the app to Android's uninstall confirmation.
  ///
  /// Confirmed here first: Android's own prompt is easy to wave through, and
  /// this row is one tap away from Open. Whether it actually went through is
  /// only knowable by asking again, which the resume re-probe does — the
  /// system UI reports nothing back.
  Future<void> _uninstall(PortalRelease release) async {
    final labels = widget.labels;
    final confirmed = await portalConfirm(
      context,
      title: '${labels.uninstall} ${release.displayName}?',
      message: labels.uninstallConfirmMessage,
      confirmLabel: labels.uninstall,
      cancelLabel: labels.cancel,
      isDestructive: true,
    );
    if (!confirmed) return;
    await PortalInstalledApps.uninstall(release.slug);
    // The system prompt may never have opened (an app that vanished between
    // the probe and the tap), in which case nothing backgrounds this app and
    // no resume fires.
    await _probeInstalled();
  }

  Future<void> _install(PortalRelease release) async {
    await showPortalUpdateDialog(
      context,
      widget.service,
      release,
      title: '${_actionFor(release) == PortalAppAction.update ? widget.labels.update : widget.labels.install} '
          '${release.displayName}',
      // Not this app's build, so a "not now" must not touch this app's
      // dismissed-version key.
      rememberRefusal: false,
    );
    // Belt to the lifecycle braces: the dialog can finish without the app ever
    // having been backgrounded (a refusal, a failed download), and then no
    // resume fires to correct the row.
    await _probeInstalled();
  }

  /// [_install] for the grouped list: a sheet with what is new instead of the
  /// dialog, and the same install and snackbar behind Update.
  Future<void> _installSheet(PortalRelease release) async {
    final go = await PortalSheet.show<bool>(
      context,
      builder: (_) => _UpdateSheet(
        release: release,
        installed: _installed[release.slug],
        action: _actionFor(release),
        labels: widget.labels,
      ),
    );
    if (go == true && mounted) {
      await portalInstallAndReport(context, widget.service, release);
    }
    await _probeInstalled();
  }

  /// A long press on an installed row: its own action again, then Uninstall. Nothing to uninstall until it is installed.
  Future<void> _showActions(PortalRelease release) {
    final labels = widget.labels;
    final action = _actionFor(release);
    return showPortalActionSheet(
      context,
      [
        PortalAction(
          icon: action == PortalAppAction.update
              ? PortalIcons.system_update_rounded
              : PortalIcons.open_in_new_rounded,
          label: _actionLabel(action),
          onPressed: () => _tap(release),
        ),
        PortalAction(
          icon: PortalIcons.delete_rounded,
          label: labels.uninstall,
          destructive: true,
          onPressed: () => _uninstall(release),
        ),
      ],
      title: release.displayName,
    );
  }

  String _actionLabel(PortalAppAction action) => switch (action) {
        PortalAppAction.open => widget.labels.open,
        PortalAppAction.install => widget.labels.install,
        PortalAppAction.update => widget.labels.update,
      };

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

    portalShowDownloadSheet(
      context,
      title: labels.installAll,
      progress: progress,
      status: status,
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
  Widget build(BuildContext context) =>
      widget._grouped ? _buildGrouped(context) : _buildList(context);

  /// The four states as a kit section: skeleton rows while loading, a header
  /// and a retry prompt on failure, nothing when there is nothing to list.
  Widget _buildGrouped(BuildContext context) {
    if (!portalCanInstallApps(widget.service)) return const SizedBox.shrink();
    final labels = widget.labels;
    final sp = PortalUiTheme.of(context).tokens.spacing;

    if (_error != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(sp.lg, sp.lg, sp.lg, sp.sm),
            child: PortalSectionHeader(title: labels.portalApps),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: sp.lg),
            child: PortalPrompt(
              size: PortalPromptSize.compact,
              sentiment: PortalSentiment.negative,
              message: _error!,
              action: (label: labels.retry, onPressed: _load),
            ),
          ),
        ],
      );
    }

    final apps = _apps;
    if (apps == null) {
      return PortalListSection(
        header: labels.portalApps,
        children: const [
          PortalListItem.skeleton(leading: PortalSkeletonLeading.tile),
          PortalListItem.skeleton(leading: PortalSkeletonLeading.tile),
        ],
      );
    }
    if (apps.isEmpty) return const SizedBox.shrink();

    // Missing and out-of-date both count, as in [_buildList].
    final pending = apps
        .where((a) => _actionFor(a) != PortalAppAction.open)
        .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PortalListSection(
          header: labels.portalApps,
          // The force-check of [_buildList], on the header where a section's
          // one action goes.
          headerAction: TextButton(
            onPressed: _refreshing ? null : _probeInstalled,
            child: Text(labels.checkAgain),
          ),
          children: [for (final app in apps) _groupedRow(context, app)],
        ),
        // Only for more than one: for a single app it is the row's button.
        if (pending.length > 1)
          Padding(
            padding: EdgeInsets.fromLTRB(sp.lg, sp.md, sp.lg, 0),
            child: PortalButton(
              label: '${labels.installAll} (${pending.length})',
              variant: PortalButtonVariant.secondary,
              leading: const Icon(PortalIcons.download_rounded),
              expand: true,
              isLoading: _batching,
              onPressed: () => _runInstallAll(pending),
            ),
          ),
      ],
    );
  }

  PortalListItem _groupedRow(BuildContext context, PortalRelease app) {
    final action = _actionFor(app);
    final installed = _installed.containsKey(app.slug);
    final name = app.displayName;
    final label = _actionLabel(action);
    // What the update changes, only where it is a decision (see [_buildList]).
    final notes = action == PortalAppAction.update ? app.notes : null;

    return PortalListItem(
      title: name,
      subtitle: [
        portalAppVersionLine(app, _installed[app.slug]),
        if (notes != null && notes.isNotEmpty) notes,
      ].join('\n'),
      leading: _appThumbnail(context, app),
      onLongPress: installed ? () => _showActions(app) : null,
      trailing: PortalListAccessory.widget(
        Tooltip(
          message: '$label $name',
          child: PortalButton(
            label: label,
            variant: PortalButtonVariant.secondary,
            onPressed: () => _tap(app),
          ),
        ),
        interactive: true,
      ),
    );
  }

  Widget _buildList(BuildContext context) {
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

    // Missing and out-of-date both count: to Android an install of a newer
    // build of something present is an update, so one batch covers both.
    final pending = apps
        .where((a) => _actionFor(a) != PortalAppAction.open)
        .toList(growable: false);

    return Column(
      children: [
        for (final app in apps)
          widget.tileBuilder?.call(
                app,
                _installed[app.slug],
                _actionFor(app),
                () => _tap(app),
              ) ??
              ListTile(
                contentPadding: padding,
                leading: CircleAvatar(
                  backgroundColor: cs.surfaceContainerHighest,
                  child: portalAppAvatar(app, cs.onSurfaceVariant),
                ),
                title: Text(app.displayName),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      portalAppVersionLine(app, _installed[app.slug]),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: _actionFor(app) == PortalAppAction.update
                                ? cs.primary
                                : cs.onSurfaceVariant,
                          ),
                    ),
                    // What the update actually changes. Only on the rows where
                    // it is a decision — on an up-to-date row it would be the
                    // notes for the build already installed, which is history.
                    if (_actionFor(app) == PortalAppAction.update &&
                        (app.notes?.isNotEmpty ?? false))
                      Text(
                        app.notes!,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                      ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_installed.containsKey(app.slug))
                      IconButton(
                        tooltip: labels.uninstall,
                        onPressed: () => _uninstall(app),
                        icon: const Icon(Icons.delete_outline_rounded),
                      ),
                    TextButton(
                      onPressed: () => _tap(app),
                      child: Text(switch (_actionFor(app)) {
                        PortalAppAction.open => labels.open,
                        PortalAppAction.install => labels.install,
                        PortalAppAction.update => labels.update,
                      }),
                    ),
                  ],
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

/// The app's own published launcher icon, falling back to the glyph.
///
/// Three ways to end up on [portalAppIconFor], all of them the same picture:
/// a manifest written before icons were published, a URL that failed the
/// https/same-host check in [PortalRelease], or a fetch that failed on the
/// device. A row therefore never renders an empty circle.
Widget portalAppAvatar(PortalRelease release, Color color) {
  return PortalNetworkImage(
    url: release.iconUrl?.toString(),
    size: 40,
    shape: BoxShape.circle,
    fallbackIcon: portalAppIconFor(release.slug),
    fallbackIconColor: color,
  );
}

/// [portalAppAvatar] for a list row's 40 dp thumbnail: the same published icon
/// and the same fallback glyph, square-cropped instead of a circle.
PortalListLeading _appThumbnail(BuildContext context, PortalRelease release) {
  return PortalListLeading.thumbnail(
    PortalNetworkImage(
      url: release.iconUrl?.toString(),
      fallbackIcon: portalAppIconFor(release.slug),
    ),
  );
}

/// The question behind a Portal apps row's Install or Update: which app, what
/// it changes, and a dock to go ahead or not. Pops true on go.
class _UpdateSheet extends StatelessWidget {
  const _UpdateSheet({
    required this.release,
    required this.installed,
    required this.action,
    required this.labels,
  });

  final PortalRelease release;
  final PortalInstalledApp? installed;
  final PortalAppAction action;
  final PortalSettingsLabels labels;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = PortalUiTheme.of(context).tokens;
    final name = release.displayName;
    final label =
        action == PortalAppAction.update ? labels.update : labels.install;
    // The manifest's notes are one string; a line each, with any list marker
    // the publisher typed dropped in favour of ours.
    final notes = (release.notes ?? '')
        .split('\n')
        .map((l) => l.replaceFirst(RegExp(r'^\s*[-*•]\s*'), '').trim())
        .where((l) => l.isNotEmpty);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: PortalSheetScaffold(
            title: '$label $name',
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PortalListSection(
                  style: PortalListStyle.fullBleed,
                  children: [
                    PortalListItem(
                      title: name,
                      subtitle: portalAppVersionLine(release, installed),
                      leading: _appThumbnail(context, release),
                    ),
                  ],
                ),
                if (notes.isNotEmpty) ...[
                  Padding(
                    padding: EdgeInsets.only(top: t.spacing.lg, bottom: t.spacing.sm),
                    child: PortalSectionHeader(title: labels.whatsNew),
                  ),
                  for (final note in notes)
                    Padding(
                      padding: EdgeInsets.only(bottom: t.spacing.sm),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ExcludeSemantics(
                            child: Text(
                              '•  ',
                              style: t.textStyles.body
                                  .copyWith(color: cs.onSurfaceVariant),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              note,
                              style: t.textStyles.body
                                  .copyWith(color: cs.onSurface),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
        PortalButtonDock(
          primary: PortalButton(
            label: label,
            size: PortalButtonSize.lg,
            expand: true,
            onPressed: () => Navigator.pop(context, true),
          ),
          secondary: PortalButton(
            label: labels.later,
            variant: PortalButtonVariant.ghost,
            expand: true,
            onPressed: () => Navigator.pop(context, false),
          ),
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
      'portal-finance' => Icons.account_balance_outlined,
      'portal-task' => Icons.task_alt,
      'portal-launcher' => Icons.home_outlined,
      'portal-journey' => Icons.auto_stories_outlined,
      'portal-assistant' => Icons.smart_toy_outlined,
      'portal-travel' => Icons.luggage_outlined,
      _ => Icons.apps_outlined,
    };

/// What tapping an app row does.
enum PortalAppAction { open, install, update }

/// What a row offers for [release] given the [installed] build, if any.
///
/// A published build *behind* what is installed is Open, not a downgrade
/// offer: local builds carry a higher commit count than the last publish, and
/// Android refuses to install an older versionCode anyway.
PortalAppAction portalAppActionFor(
  PortalRelease release,
  PortalInstalledApp? installed,
) {
  if (installed == null) return PortalAppAction.install;
  return release.versionCode > installed.versionCode
      ? PortalAppAction.update
      : PortalAppAction.open;
}

/// `v1.2.0` when it matches, `v1.2.0 → v1.4.0` when the publish is ahead
/// of what is installed. Size trails both; an app that is not installed shows
/// the published version alone.
String portalAppVersionLine(
  PortalRelease release,
  PortalInstalledApp? installed,
) {
  final latest = release.versionName.isEmpty ? '' : 'v${release.versionName}';
  final current = (installed == null || installed.versionName.isEmpty)
      ? ''
      : 'v${installed.versionName}';
  final version = switch (portalAppActionFor(release, installed)) {
    PortalAppAction.update when current.isNotEmpty && latest.isNotEmpty =>
      '$current → $latest',
    PortalAppAction.open when current.isNotEmpty => current,
    _ => latest,
  };
  return [
    if (version.isNotEmpty) version,
    if (release.readableSize.isNotEmpty) release.readableSize,
  ].join('  ·  ');
}

/// The scheme a Portal app answers on: `portal-gym` -> `portal-gym://open`.
///
/// Must match the `<data android:scheme>` in that app's manifest and the
/// `<queries>` entries in every other app's. The manifest slug and the update
/// manifest's key are the same string, so there is one name to keep in step,
/// not two.
Uri portalAppUri(String slug) => Uri(scheme: slug, host: 'open');
