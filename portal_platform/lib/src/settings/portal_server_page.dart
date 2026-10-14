import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

import '../config/portal_server_prefs.dart';
import '../services/api_client.dart';
import '../session/session_controller.dart';
import 'portal_settings_labels.dart';

enum _Health { healthy, checking, unreachable }

/// The custom URL's check: only a URL that answered can be switched to.
enum _Test { idle, testing, ok, failed }

/// Dev/QA tool: point this app install at a different Portal server.
///
/// Reached only through the Status section's "Server" row once the 7-tap
/// unlock gesture (or a debug build) reveals it — see [PortalStatusSection].
/// A local host must be on a private/loopback range; that check, not the
/// unlock gesture, is what actually stops a real user's credentials from
/// ever reaching an arbitrary server through this screen.
///
/// Mirrors the design kit's ServerPage: the server in use with its health,
/// the cloud preset, and a custom local host to test, then switch to.
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

  _Health _health = _Health.checking;
  String? _latency;
  String? _problem;

  _Test _test = _Test.idle;
  String? _testResult;
  String? _hostError;
  String? _testedUrl;

  @override
  void initState() {
    super.initState();
    _probeCurrent();
  }

  @override
  void dispose() {
    _hostCtrl.dispose();
    super.dispose();
  }

  /// Pings the server's own readiness route (the one [ApiClient] already
  /// uses), timing it. Returns the latency, or null with [error] set.
  Future<({String? ms, String? error})> _ping(String url) async {
    final clock = Stopwatch()..start();
    final result = await _api.checkBackendReadiness(
      baseUrl: url,
      timeout: const Duration(seconds: 6),
    );
    clock.stop();
    return result.isReady
        ? (ms: '${clock.elapsedMilliseconds} ms', error: null)
        : (ms: null, error: result.errorMessage ?? widget.labels.serverUnreachable);
  }

  Future<void> _probeCurrent() async {
    setState(() {
      _health = _Health.checking;
      _latency = null;
      _problem = null;
    });
    final r = await _ping(_api.baseUrl);
    if (!mounted) return;
    setState(() {
      _health = r.ms != null ? _Health.healthy : _Health.unreachable;
      _latency = r.ms;
      _problem = r.error;
    });
  }

  Future<void> _testCustom() async {
    final labels = widget.labels;
    final url = PortalServerPrefs.localUrlFrom(_hostCtrl.text);
    if (url == null) {
      setState(() {
        _test = _Test.idle;
        _hostError = labels.serverInvalidHost;
      });
      return;
    }
    setState(() {
      _test = _Test.testing;
      _hostError = null;
      _testedUrl = url;
    });
    final r = await _ping(url);
    if (!mounted || _testedUrl != url) return;
    setState(() {
      _test = r.ms != null ? _Test.ok : _Test.failed;
      _testResult = r.ms != null ? '${labels.serverOnline} · ${r.ms}' : r.error;
    });
  }

  /// Confirms, switches (null = back to the cloud default), then signs out:
  /// the session belongs to the server it was issued by.
  Future<void> _switchTo(String? url) async {
    final labels = widget.labels;
    final confirmed = await portalConfirm(
      context,
      title: labels.serverSwitchConfirmTitle,
      message: labels.serverSwitchConfirmMessage,
      confirmLabel: labels.serverSwitch,
      cancelLabel: labels.cancel,
    );
    if (!confirmed) return;
    await _api.switchServer(url);
    if (Get.isRegistered<SessionController>()) {
      await Get.find<SessionController>().signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    final labels = widget.labels;
    final t = PortalUiTheme.of(context).tokens;
    final overridden = _api.isOverridden;

    final badge = switch (_health) {
      _Health.healthy => PortalBadge(
        label: labels.serverOnline,
        icon: PortalIcons.check_circle_rounded,
      ),
      _Health.checking => PortalBadge(
        label: labels.checking,
        icon: PortalIcons.sync_rounded,
        tone: PortalBadgeTone.pending,
      ),
      _Health.unreachable => PortalBadge(
        label: labels.serverUnreachable,
        icon: PortalIcons.cloud_off_rounded,
        tone: PortalBadgeTone.danger,
      ),
    };

    return PortalScrollPage(
      title: labels.serverTitle,
      leading: PortalButton.icon(
        icon: PortalIcons.arrow_back_rounded,
        tooltip: labels.back,
        onPressed: () => Navigator.of(context).maybePop(),
      ),
      children: [
        PortalListSection(
          header: labels.serverCurrent,
          style: PortalListStyle.fullBleed,
          children: [
            PortalListItem(
              title: _api.baseUrl,
              subtitle: overridden ? labels.serverLocal : labels.serverCloud,
              leading: PortalListLeading.tile(
                PortalIcons.dns_rounded,
                tone: PortalListTone.tertiary,
              ),
              trailing: _latency == null
                  ? PortalListAccessory.none
                  : PortalListAccessory.value(
                      _latency!,
                      sentiment: PortalValueSentiment.dim,
                    ),
              below: Align(
                alignment: AlignmentDirectional.centerStart,
                child: badge,
              ),
            ),
          ],
        ),
        if (_health == _Health.unreachable && _problem != null)
          Padding(
            padding: EdgeInsets.fromLTRB(t.spacing.lg, t.spacing.sm, t.spacing.lg, 0),
            child: PortalPrompt(
              size: PortalPromptSize.compact,
              sentiment: PortalSentiment.negative,
              message: _problem!,
              action: (label: labels.retry, onPressed: _probeCurrent),
            ),
          ),
        PortalListSection.selectable(
          header: labels.serverPresets,
          selected: overridden ? null : 0,
          children: [
            PortalListItem(
              title: labels.serverCloud,
              subtitle: _api.defaultBaseUrl,
              trailing: PortalListAccessory.radio(
                checked: !overridden,
                onChanged: (_) => overridden ? _switchTo(null) : null,
              ),
            ),
          ],
        ),
        // A bare header has no gutter; the list sections above draw theirs.
        Padding(
          padding: EdgeInsets.only(
            left: PortalUiTheme.of(context).tokens.layout.pageHorizontal,
            right: PortalUiTheme.of(context).tokens.layout.pageHorizontal,
            top: PortalUiTheme.of(context).tokens.spacing.lg,
          ),
          child: PortalSectionHeader(title: labels.serverLocal),
        ),
        PortalFormStack(
          children: [
            PortalTextField(
              label: labels.serverLocalHost,
              controller: _hostCtrl,
              keyboardType: TextInputType.url,
              textInputAction: TextInputAction.go,
              errorText: _hostError,
              helper: labels.serverLocalHint,
              onChanged: (_) => setState(() {
                _test = _Test.idle;
                _hostError = null;
              }),
              onSubmitted: (_) => _testCustom(),
            ),
            if (_test == _Test.ok && _testResult != null)
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: Semantics(
                  liveRegion: true,
                  child: PortalBadge(
                    label: _testResult!,
                    icon: PortalIcons.check_circle_rounded,
                  ),
                ),
              ),
            // Failed: the prompt's retry is the Check button.
            if (_test == _Test.failed)
              PortalPrompt(
                size: PortalPromptSize.compact,
                sentiment: PortalSentiment.negative,
                message: _testResult ?? labels.serverUnreachable,
                action: (label: labels.retry, onPressed: _testCustom),
              )
            else
              Wrap(
                spacing: t.spacing.sm,
                children: [
                  PortalButton(
                    label: labels.serverCheck,
                    size: PortalButtonSize.sm,
                    variant: PortalButtonVariant.secondary,
                    isLoading: _test == _Test.testing,
                    busyLabel: labels.checking,
                    onPressed: _testCustom,
                  ),
                  if (_test == _Test.ok)
                    PortalButton(
                      label: labels.serverSwitch,
                      size: PortalButtonSize.sm,
                      variant: PortalButtonVariant.secondary,
                      onPressed: () => _switchTo(_testedUrl),
                    ),
                ],
              ),
          ],
        ),
      ],
    );
  }
}
