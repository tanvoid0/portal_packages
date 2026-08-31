import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../services/api_client.dart';
import 'portal_settings_labels.dart';

/// What one dependency looked like the last time it was asked.
enum PortalStatusState { checking, ok, degraded, down }

/// Server reachability and assistant availability, checked on demand.
///
/// Deliberately not a service and not polled. Two requests when the settings
/// page opens, and again only if the user taps refresh — the point is to
/// answer "is it me or is it them", not to keep a heartbeat running behind
/// every screen.
///
/// Safe to drop into an app's own settings screen; `portal_task` does exactly
/// that. Pass [labels] to translate it.
class PortalStatusSection extends StatefulWidget {
  const PortalStatusSection({
    super.key,
    this.contentPadding,
    this.labels = const PortalSettingsLabels(),
  });

  final EdgeInsetsGeometry? contentPadding;
  final PortalSettingsLabels labels;

  @override
  State<PortalStatusSection> createState() => _PortalStatusSectionState();
}

class _PortalStatusSectionState extends State<PortalStatusSection> {
  PortalStatusState _server = PortalStatusState.checking;
  String? _serverDetail;

  PortalStatusState _ai = PortalStatusState.checking;
  String? _aiDetail;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final labels = widget.labels;

    // An app that mounts this without PortalBootstrap has no client to ask.
    // Reporting "down" would blame the server for a wiring mistake.
    if (!Get.isRegistered<ApiClient>()) {
      setState(() {
        _server = PortalStatusState.degraded;
        _serverDetail = labels.assistantUnknown;
        _ai = PortalStatusState.degraded;
        _aiDetail = labels.assistantUnknown;
      });
      return;
    }

    setState(() {
      _server = PortalStatusState.checking;
      _ai = PortalStatusState.checking;
      _serverDetail = null;
      _aiDetail = null;
    });

    final api = Get.find<ApiClient>();
    final readiness = await api.checkBackendReadiness();
    if (!mounted) return;
    setState(() {
      _server =
          readiness.isReady ? PortalStatusState.ok : PortalStatusState.down;
      _serverDetail = readiness.isReady
          ? labels.serverOnline
          : (readiness.errorMessage ?? labels.serverUnreachable);
    });

    // An unreachable server tells us nothing about the assistant, and asking
    // anyway just waits out a second timeout for an answer we already have.
    if (!readiness.isReady) {
      setState(() {
        _ai = PortalStatusState.down;
        _aiDetail = labels.assistantNeedsServer;
      });
      return;
    }

    try {
      final raw = await api.get('/ai/status');
      if (!mounted) return;
      final map = raw is Map ? Map<String, dynamic>.from(raw) : const {};
      final configured = map['configured'] == true;
      final model = (map['model'] as String?)?.trim();
      final provider = (map['provider'] as String?)?.trim();
      setState(() {
        _ai = configured ? PortalStatusState.ok : PortalStatusState.degraded;
        _aiDetail = configured
            ? [provider, model]
                .whereType<String>()
                .where((s) => s.isNotEmpty)
                .join('  ·  ')
            : labels.assistantNotConfigured;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _ai = PortalStatusState.down;
        _aiDetail = labels.assistantUnknown;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final labels = widget.labels;
    final busy = _server == PortalStatusState.checking ||
        _ai == PortalStatusState.checking;

    return Column(
      children: [
        PortalStatusTile(
          icon: Icons.dns_outlined,
          title: labels.serverTitle,
          state: _server,
          detail: _serverDetail,
          checkingLabel: labels.checking,
          contentPadding: widget.contentPadding,
          trailing: IconButton(
            tooltip: labels.checkAgain,
            onPressed: busy ? null : _refresh,
            icon: const Icon(Icons.refresh_rounded),
            visualDensity: VisualDensity.compact,
          ),
        ),
        PortalStatusTile(
          icon: Icons.auto_awesome_outlined,
          title: labels.assistant,
          state: _ai,
          detail: _aiDetail,
          checkingLabel: labels.checking,
          contentPadding: widget.contentPadding,
        ),
      ],
    );
  }
}

/// One "is this thing up" row: icon, name, detail, and a state dot.
///
/// Public so an app can show the same row for something of its own — a bank
/// connection, a sync backend — and have it read identically.
class PortalStatusTile extends StatelessWidget {
  const PortalStatusTile({
    super.key,
    required this.icon,
    required this.title,
    required this.state,
    this.detail,
    this.trailing,
    this.contentPadding,
    this.checkingLabel = 'Checking…',
  });

  final IconData icon;
  final String title;
  final PortalStatusState state;
  final String? detail;
  final Widget? trailing;
  final EdgeInsetsGeometry? contentPadding;
  final String checkingLabel;

  /// Green / amber / red, resolved against the theme where one fits.
  ///
  /// `ok` and `degraded` are literals because no `ColorScheme` role means
  /// "healthy" or "working but not fully": `primary` is whatever the app's
  /// brand is, and on a green-branded app a red error and a green primary
  /// would be indistinguishable in meaning.
  Color _colour(ColorScheme cs) => switch (state) {
        PortalStatusState.checking => cs.onSurfaceVariant,
        PortalStatusState.ok => const Color(0xFF2E7D32),
        PortalStatusState.degraded => const Color(0xFFED6C02),
        PortalStatusState.down => cs.error,
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final checking = state == PortalStatusState.checking;

    return ListTile(
      contentPadding: contentPadding,
      leading: Icon(icon, color: cs.onSurfaceVariant),
      title: Text(title),
      subtitle: Text(
        checking ? checkingLabel : (detail ?? ''),
        style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox.square(
            dimension: 16,
            child: Center(
              child: checking
                  ? const SizedBox.square(
                      dimension: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(Icons.circle, size: 10, color: _colour(cs)),
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 4), trailing!],
        ],
      ),
    );
  }
}
