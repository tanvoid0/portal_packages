import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../widgets/portal_app_version.dart';
import 'portal_release.dart';
import 'portal_update_service.dart';

/// The app version panel: what is installed, what is published, and when that
/// was last checked. Tapping it checks again and offers the update.
///
/// One widget for both cases on purpose. There used to be two — a plain
/// version row when no update service was registered and a checkable one when
/// there was — so the same fact appeared in two shapes depending on how the
/// host app was wired. Passing no [service] now only drops the rows that need
/// one.
///
/// Plain Material on purpose — `portal_platform` sits below the UI kit, so it
/// cannot reach for ui_core's tokens. An app that wants its own styling
/// composes [PortalAppVersionText] instead.
class PortalUpdateTile extends StatefulWidget {
  const PortalUpdateTile({
    super.key,
    this.service,
    this.title = 'App version',
  });

  /// Null, or disabled, means no update checks: the panel still shows the
  /// running build, and nothing is tappable.
  final PortalUpdateService? service;
  final String title;

  @override
  State<PortalUpdateTile> createState() => _PortalUpdateTileState();
}

class _PortalUpdateTileState extends State<PortalUpdateTile> {
  bool _checking = false;
  PackageInfo? _info;
  PortalUpdateCheck? _result;
  DateTime? _lastChecked;

  bool get _enabled => widget.service?.isEnabled ?? false;

  @override
  void initState() {
    super.initState();
    _loadCached();
  }

  /// Package info and the stored last-check stamp. Deliberately no network:
  /// opening settings should not spend a request, and the launch check has
  /// already written the stamp this reads.
  Future<void> _loadCached() async {
    final info = await PortalAppVersion.load();
    final checked = await widget.service?.lastCheckedAt();
    if (!mounted) return;
    setState(() {
      _info = info;
      _lastChecked = checked;
    });
  }

  Future<void> _check() async {
    final service = widget.service;
    if (service == null) return;
    setState(() {
      _checking = true;
      _result = null;
    });
    final result = await service.check();
    if (!mounted) return;
    setState(() {
      _checking = false;
      _result = result;
      _lastChecked = result.checkedAt ?? _lastChecked;
    });

    if (result.status == PortalUpdateStatus.updateAvailable) {
      await showPortalUpdateDialog(context, service, result.release!);
    }
  }

  /// The verdict, appended to the running version. Kept to two words: it
  /// shares a line with the build number, and the reason a check went wrong
  /// belongs in [_detail] where there is room to read it.
  ///
  /// Null before the first check of the session — naming a status for a check
  /// that has not run would be inventing one.
  String? get _status {
    if (_checking) return 'checking…';
    return switch (_result?.status) {
      PortalUpdateStatus.updateAvailable => 'update available',
      PortalUpdateStatus.upToDate => 'up to date',
      _ => null,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final failed = _result?.status == PortalUpdateStatus.failed;

    return ListTile(
      title: Text(widget.title),
      // Two dense lines rather than a labelled table. Everything here is
      // short and self-describing — "1.3.0 (build 412)" needs no column
      // headed Installed — and the table made a settings row five lines tall
      // for four facts.
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _headline,
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            _detail,
            style: theme.textTheme.bodySmall?.copyWith(
              color: failed
                  ? theme.colorScheme.error
                  : theme.colorScheme.onSurfaceVariant,
            ),
            // A failure names a cause worth reading; everything else on this
            // line is short by construction.
            maxLines: failed ? 3 : 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
      isThreeLine: true,
      trailing: _checking
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : _enabled
              ? IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Check for updates',
                  onPressed: _check,
                )
              : null,
      onTap: _enabled && !_checking ? _check : null,
    );
  }

  /// The running build, and the verdict on it when there is one.
  String get _headline {
    final status = _status;
    return status == null ? _installedLabel : '$_installedLabel · $status';
  }

  /// What is published and when it was last looked for — or, when a check
  /// could not run, why.
  String get _detail {
    if (!_enabled) return 'Updates are not available in this build';
    final result = _result;
    if (result?.status == PortalUpdateStatus.unsupported) {
      return 'Updates are not available in this build';
    }
    if (result?.status == PortalUpdateStatus.failed) {
      return result!.message ?? 'The update check did not complete';
    }

    final parts = <String>[
      if (result?.latest case final latest?) 'Latest ${_releaseLabel(latest)}',
      'checked ${portalFormatSince(_lastChecked).toLowerCase()}',
    ];
    return parts.join(' · ');
  }

  String get _installedLabel {
    final info = _info;
    if (info == null) return '…';
    final version = info.version.isEmpty ? '—' : info.version;
    return info.buildNumber.isEmpty
        ? version
        : '$version (build ${info.buildNumber})';
  }

  String _releaseLabel(PortalRelease release) {
    final name = release.versionName.isEmpty
        ? 'build ${release.versionCode}'
        : release.versionName;
    final at = release.publishedAt;
    return at == null ? name : '$name, ${portalFormatDate(at)}';
  }
}

/// `8 Sep 2026` in the device locale.
///
/// Date only: the hour a build was published, or a check last ran, is not
/// something anyone acts on, and it doubles the width of every line it
/// appears in.
String portalFormatDate(DateTime at) =>
    DateFormat.yMMMd().format(at.toLocal());

/// `2 hours ago`, falling back to the absolute date once the gap stops being
/// the useful way to read it.
///
/// Null reads as never checked rather than as an empty cell — a blank value
/// there looks like a rendering bug, not a fact.
String portalFormatSince(DateTime? at, {DateTime? now}) {
  if (at == null) return 'Never';
  final gap = (now ?? DateTime.now()).difference(at);
  if (gap.isNegative || gap.inMinutes < 1) return 'Just now';
  if (gap.inHours < 1) return _plural(gap.inMinutes, 'minute');
  if (gap.inDays < 1) return _plural(gap.inHours, 'hour');
  if (gap.inDays < 7) return _plural(gap.inDays, 'day');
  return portalFormatDate(at);
}

String _plural(int n, String unit) => '$n ${n == 1 ? unit : '${unit}s'} ago';

/// Offers [release], then downloads and installs it if the user accepts.
///
/// Returns true when the installer was launched. Android then shows its own
/// confirmation — nothing here installs anything silently.
Future<bool> showPortalUpdateDialog(
  BuildContext context,
  PortalUpdateService service,
  PortalRelease release, {
  String? title,
  bool rememberRefusal = true,
}) async {
  final accepted = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title ?? 'Update to ${release.versionName}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (release.notes != null) ...[
            Text(release.notes!),
            const SizedBox(height: 12),
          ],
          Text(
            release.readableSize.isEmpty
                ? 'Downloads the new version, then opens the installer.'
                : 'Downloads ${release.readableSize}, then opens the '
                    'installer.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Not now'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Download'),
        ),
      ],
    ),
  );

  if (accepted != true) {
    // Remember the refusal so the launch check does not re-ask every start.
    // The manual tile ignores this, and a newer publish clears it by having a
    // higher versionCode. Off when the release is a *different* app: the key
    // is per-package, so recording someone else's versionCode there would
    // silence this app's own update prompt.
    if (rememberRefusal) await service.markDismissed(release.versionCode);
    return false;
  }
  if (!context.mounted) return false;

  final progress = ValueNotifier<double>(-1);
  // Not awaited: this dialog stays up until the download finishes and the
  // `finally` below pops it. barrierDismissible is false, so it cannot close
  // on its own and leave that pop to dismiss the wrong route.
  unawaited(
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Downloading'),
        content: ValueListenableBuilder<double>(
          valueListenable: progress,
          builder: (context, value, _) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              LinearProgressIndicator(value: value < 0 ? null : value),
              const SizedBox(height: 12),
              Text(value < 0 ? '' : '${(value * 100).round()}%'),
            ],
          ),
        ),
      ),
    ),
  );

  String? error;
  File? apk;
  try {
    apk = await service.download(release, onProgress: (p) => progress.value = p);
    await service.install(apk);
  } on PortalUpdateException catch (e) {
    error = e.message;
  } catch (e) {
    error = 'Update failed: $e';
  } finally {
    progress.dispose();
    if (context.mounted) Navigator.of(context).pop();
  }

  if (error != null && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    return false;
  }
  return error == null;
}

/// One-shot launch check: prompts only when there is a newer build the user
/// has not already refused.
///
/// Silent on every failure — no network, bad manifest, no update. A launch
/// must not surface an error about an update the user never asked for.
Future<void> portalPromptForUpdateOnLaunch(
  BuildContext context,
  PortalUpdateService service,
) async {
  if (!service.isEnabled) return;
  final result = await service.check();
  final release = result.release;
  if (release == null) return;
  if (await service.wasDismissed(release.versionCode)) return;
  if (!context.mounted) return;
  await showPortalUpdateDialog(context, service, release);
}
