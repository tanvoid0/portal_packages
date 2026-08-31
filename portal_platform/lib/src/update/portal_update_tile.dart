import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import '../widgets/portal_app_version.dart';
import 'portal_release.dart';
import 'portal_update_service.dart';

/// Settings tile: shows the running version and checks for a sideload update.
///
/// Plain Material on purpose — `portal_platform` sits below the UI kit, the
/// same reason [PortalAppVersionListTile] does not use it either.
class PortalUpdateTile extends StatefulWidget {
  const PortalUpdateTile({
    super.key,
    required this.service,
    this.title = 'App version',
  });

  final PortalUpdateService service;
  final String title;

  @override
  State<PortalUpdateTile> createState() => _PortalUpdateTileState();
}

class _PortalUpdateTileState extends State<PortalUpdateTile> {
  bool _checking = false;
  String? _subtitle;

  Future<void> _check() async {
    setState(() {
      _checking = true;
      _subtitle = null;
    });
    final result = await widget.service.check();
    if (!mounted) return;
    setState(() => _checking = false);

    switch (result.status) {
      case PortalUpdateStatus.updateAvailable:
        await showPortalUpdateDialog(context, widget.service, result.release!);
      case PortalUpdateStatus.upToDate:
        setState(() => _subtitle = 'Up to date');
      case PortalUpdateStatus.unsupported:
        setState(() => _subtitle = 'Updates are not available in this build');
      case PortalUpdateStatus.failed:
        setState(() => _subtitle = result.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.service.isEnabled && !_checking;
    return ListTile(
      title: Text(widget.title),
      subtitle: _subtitle == null ? null : Text(_subtitle!),
      trailing: _checking
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : PortalAppVersionText(
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
      onTap: enabled ? _check : null,
    );
  }
}

/// Offers [release], then downloads and installs it if the user accepts.
///
/// Returns true when the installer was launched. Android then shows its own
/// confirmation — nothing here installs anything silently.
Future<bool> showPortalUpdateDialog(
  BuildContext context,
  PortalUpdateService service,
  PortalRelease release,
) async {
  final accepted = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Update to ${release.versionName}'),
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
    // higher versionCode.
    await service.markDismissed(release.versionCode);
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
