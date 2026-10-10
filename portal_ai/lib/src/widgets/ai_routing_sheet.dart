import 'package:flutter/material.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

import '../models/ai_backend_labels.dart';
import '../models/ai_routing_mode.dart';
import '../prefs/ai_backend_store.dart';

/// Pick how the assistant chooses between the Portal server and a local
/// backend, and apply it once.
///
/// Apply stays off until the pick differs from what is stored, so opening the
/// sheet and tapping through changes nothing.
class AiRoutingSheet extends StatefulWidget {
  const AiRoutingSheet({
    super.key,
    required this.store,
    this.labels = const AiBackendLabels(),
    this.cloudEligible = true,
  });

  final AiBackendStore store;
  final AiBackendLabels labels;

  /// False disables "Server only": the server needs a signed-in account.
  final bool cloudEligible;

  /// Returns the applied mode, or null when the sheet was dismissed -- the
  /// caller's cue to re-fire `onChanged`, since routing alone changes what the
  /// runtime should be running.
  static Future<AiRoutingMode?> show(
    BuildContext context, {
    required AiBackendStore store,
    AiBackendLabels labels = const AiBackendLabels(),
    bool cloudEligible = true,
  }) => PortalSheet.show<AiRoutingMode>(
    context,
    title: labels.routingRow,
    builder: (_) => AiRoutingSheet(
      store: store,
      labels: labels,
      cloudEligible: cloudEligible,
    ),
  );

  @override
  State<AiRoutingSheet> createState() => _AiRoutingSheetState();
}

class _AiRoutingSheetState extends State<AiRoutingSheet> {
  late final AiRoutingMode _stored = widget.store.routingMode;
  late AiRoutingMode _pick = _stored;

  Future<void> _apply() async {
    await widget.store.setRoutingMode(_pick);
    if (!mounted) return;
    Navigator.pop(context, _pick);
  }

  @override
  Widget build(BuildContext context) {
    final labels = widget.labels;
    const modes = AiRoutingMode.values;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PortalListSection.selectable(
          selected: modes.indexOf(_pick),
          children: [
            for (final mode in modes)
              PortalListItem(
                title: labels.routingLabelFor(mode),
                subtitle: labels.routingDescriptionFor(mode),
                disabledReason:
                    mode == AiRoutingMode.serverOnly && !widget.cloudEligible
                    ? labels.cloudNote
                    : null,
                trailing: PortalListAccessory.radio(
                  checked: mode == _pick,
                  onChanged: (_) => setState(() => _pick = mode),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        PortalButtonDock(
          inline: true,
          primary: PortalButton(
            label: labels.apply,
            size: PortalButtonSize.lg,
            expand: true,
            onPressed: _pick == _stored ? null : _apply,
          ),
        ),
      ],
    );
  }
}
