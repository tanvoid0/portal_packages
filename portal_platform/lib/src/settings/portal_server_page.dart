import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../config/portal_server_prefs.dart';
import '../services/api_client.dart';
import '../session/session_controller.dart';
import 'portal_settings_labels.dart';

enum _ServerChoice { cloud, local }

/// Dev/QA tool: point this app install at a different Portal server.
///
/// Reached only through the Status section's "Server" row once the 7-tap
/// unlock gesture (or a debug build) reveals it — see [PortalStatusSection].
/// A local host must be on a private/loopback range; that check, not the
/// unlock gesture, is what actually stops a real user's credentials from
/// ever reaching an arbitrary server through this screen.
class PortalServerPage extends StatefulWidget {
  const PortalServerPage({super.key, this.labels = const PortalSettingsLabels()});

  final PortalSettingsLabels labels;

  @override
  State<PortalServerPage> createState() => _PortalServerPageState();
}

class _PortalServerPageState extends State<PortalServerPage> {
  final _api = Get.find<ApiClient>();
  late final _hostCtrl = TextEditingController(
    text: _api.isOverridden ? _api.baseUrl : '10.0.2.2:3001',
  );
  late _ServerChoice _choice =
      _api.isOverridden ? _ServerChoice.local : _ServerChoice.cloud;

  bool _checking = false;
  bool _switching = false;
  String? _checkResult;
  bool? _checkOk;

  @override
  void dispose() {
    _hostCtrl.dispose();
    super.dispose();
  }

  String? get _candidateUrl => _choice == _ServerChoice.cloud
      ? _api.defaultBaseUrl
      : PortalServerPrefs.localUrlFrom(_hostCtrl.text);

  Future<void> _check() async {
    final labels = widget.labels;
    final url = _candidateUrl;
    if (url == null) {
      setState(() {
        _checkOk = false;
        _checkResult = labels.serverInvalidHost;
      });
      return;
    }
    setState(() {
      _checking = true;
      _checkResult = null;
      _checkOk = null;
    });
    final result = await _api.checkBackendReadiness(
      baseUrl: url,
      timeout: const Duration(seconds: 6),
    );
    if (!mounted) return;
    setState(() {
      _checking = false;
      _checkOk = result.isReady;
      _checkResult = result.isReady
          ? labels.serverOnline
          : (result.errorMessage ?? labels.serverUnreachable);
    });
  }

  Future<void> _switch() async {
    final labels = widget.labels;
    final url = _candidateUrl;
    if (url == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(labels.serverSwitchConfirmTitle),
        content: Text(labels.serverSwitchConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(labels.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(labels.serverSwitch),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _switching = true);
    await _api.switchServer(_choice == _ServerChoice.cloud ? null : url);
    if (Get.isRegistered<SessionController>()) {
      await Get.find<SessionController>().signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    final labels = widget.labels;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(labels.serverTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
          children: [
            SegmentedButton<_ServerChoice>(
              segments: [
                ButtonSegment(
                  value: _ServerChoice.cloud,
                  label: Text(labels.serverCloud),
                ),
                ButtonSegment(
                  value: _ServerChoice.local,
                  label: Text(labels.serverLocal),
                ),
              ],
              selected: {_choice},
              onSelectionChanged: (v) => setState(() {
                _choice = v.first;
                _checkResult = null;
                _checkOk = null;
              }),
            ),
            const SizedBox(height: 20),
            if (_choice == _ServerChoice.cloud)
              Text(_api.defaultBaseUrl, style: Theme.of(context).textTheme.bodyMedium)
            else ...[
              TextField(
                controller: _hostCtrl,
                decoration: InputDecoration(labelText: labels.serverLocalHost),
                keyboardType: TextInputType.url,
                onChanged: (_) => setState(() {
                  _checkResult = null;
                  _checkOk = null;
                }),
              ),
              const SizedBox(height: 8),
              Text(
                labels.serverLocalHint,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: cs.onSurfaceVariant),
              ),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                OutlinedButton(
                  onPressed: _checking ? null : _check,
                  child: _checking
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(labels.serverCheck),
                ),
                const SizedBox(width: 12),
                if (_checkResult != null)
                  Expanded(
                    child: Text(
                      _checkResult!,
                      style: TextStyle(
                        color: _checkOk == true ? const Color(0xFF2E7D32) : cs.error,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _checkOk == true && !_switching ? _switch : null,
              child: _switching
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(labels.serverSwitch),
            ),
          ],
        ),
      ),
    );
  }
}
