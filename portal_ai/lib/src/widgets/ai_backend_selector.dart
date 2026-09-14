import 'package:flutter/material.dart';

import '../discovery/ai_backend_discovery.dart';
import '../models/ai_backend_labels.dart';
import '../models/ai_backend_option.dart';
import '../prefs/ai_backend_store.dart';
import 'ai_settings_section.dart';

/// The provider list on its own, for a screen that lays out the model and host
/// settings itself. [AiSettingsSection] is the whole group and the one to
/// reach for in a new screen.
class AiBackendSelector extends StatelessWidget {
  const AiBackendSelector({
    super.key,
    required this.store,
    required this.onChanged,
    this.labels = const AiBackendLabels(),
    this.discovery,
    this.cloudEligible = true,
    this.trailingBuilder,
    this.onRescan,
    this.hasServer = false,
  });

  final AiBackendStore store;
  final ValueChanged<AiBackendOption> onChanged;
  final AiBackendLabels labels;
  final AiBackendDiscovery? discovery;
  final bool cloudEligible;
  final Widget? Function(AiBackendOption option)? trailingBuilder;
  final VoidCallback? onRescan;
  final bool hasServer;

  @override
  Widget build(BuildContext context) {
    return AiSettingsSection(
      store: store,
      onChanged: onChanged,
      labels: labels,
      discovery: discovery,
      cloudEligible: cloudEligible,
      showModelConfig: false,
      trailingBuilder: trailingBuilder,
      onRescan: onRescan,
      hasServer: hasServer,
    );
  }
}
