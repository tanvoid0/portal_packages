import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../services/api_client.dart';

/// What one dependency looked like the last time it was asked.
enum PortalStatusState { checking, ok, degraded, down }

/// Server reachability and assistant availability, checked on demand.
///
/// Deliberately not a service and not polled. Two requests when the settings
/// page opens, and again only if the user taps refresh — the point is to
/// answer "is it me or is it them", not to keep a heartbeat running behind
/// every screen.
class PortalStatusSection extends StatefulWidget {
  const PortalStatusSection({super.key, this.contentPadding});

  final EdgeInsetsGeometry? contentPadding;

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
      _server = readiness.isReady
          ? PortalStatusState.ok
          : PortalStatusState.down;
      _serverDetail =
          readiness.isReady ? 'Online' : (readiness.errorMessage ?? 'Unreachable');
    });

    // An unreachable server tells us nothing about the assistant, and asking
    // anyway just waits out a second timeout for an answer we already have.
    if (!readiness.isReady) {
      setState(() {
        _ai = PortalStatusState.down;
        _aiDetail = 'Needs the server';
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
            ? [provider, model].whereType<String>().where((s) => s.isNotEmpty).join(' · ')
            : 'No model configured on the server';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _ai = PortalStatusState.down;
        _aiDetail = 'Could not read assistant status';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final busy = _server == PortalStatusState.checking ||
        _ai == PortalStatusState.checking;

    return Column(
      children: [
        _StatusTile(
          icon: Icons.dns_outlined,
          title: 'Server',
          state: _server,
          detail: _serverDetail,
          contentPadding: widget.contentPadding,
          trailing: IconButton(
            tooltip: 'Check again',
            onPressed: busy ? null : _refresh,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ),
        _StatusTile(
          icon: Icons.auto_awesome_outlined,
          title: 'Assistant',
          state: _ai,
          detail: _aiDetail,
          contentPadding: widget.contentPadding,
        ),
      ],
    );
  }
}

class _StatusTile extends StatelessWidget {
  const _StatusTile({
    required this.icon,
    required this.title,
    required this.state,
    this.detail,
    this.trailing,
    this.contentPadding,
  });

  final IconData icon;
  final String title;
  final PortalStatusState state;
  final String? detail;
  final Widget? trailing;
  final EdgeInsetsGeometry? contentPadding;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final colour = switch (state) {
      PortalStatusState.checking => cs.onSurfaceVariant,
      PortalStatusState.ok => const Color(0xFF2E7D32),
      PortalStatusState.degraded => const Color(0xFFED6C02),
      PortalStatusState.down => cs.error,
    };

    return ListTile(
      contentPadding: contentPadding,
      leading: Icon(icon, color: cs.onSurfaceVariant),
      title: Text(title),
      subtitle: Text(
        state == PortalStatusState.checking ? 'Checking…' : (detail ?? ''),
        style: Theme.of(context)
            .textTheme
            .bodySmall
            ?.copyWith(color: cs.onSurfaceVariant),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (state == PortalStatusState.checking)
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Icon(Icons.circle, size: 12, color: colour),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
