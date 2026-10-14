import 'package:flutter/material.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

import '../clients/ollama_model_manager.dart';
import '../discovery/ai_backend_discovery.dart';
import '../local/local_llm_engine.dart';
import '../models/ai_backend_kind.dart';
import '../models/ai_backend_labels.dart';
import '../models/ai_backend_option.dart';
import '../models/ai_model_manager.dart';
import '../prefs/ai_backend_store.dart';
import 'ai_models_page.dart';
import 'ai_routing_sheet.dart';
import 'ai_settings_section.dart';

/// The assistant's settings as a grouped list of rows -- provider, routing,
/// on-device models -- each showing its current value and opening its own
/// sheet. The row-based sibling of [AiSettingsSection], which it reuses inside
/// the provider sheet rather than rewriting the radios and fields.
///
/// Same arguments as [AiSettingsSection], plus [onModels] for a host that has
/// a models screen of its own.
class AiSettingsGroup extends StatefulWidget {
  const AiSettingsGroup({
    super.key,
    required this.store,
    this.onChanged,
    this.labels = const AiBackendLabels(),
    this.discovery,
    this.cloudEligible = true,
    this.trailingBuilder,
    this.onRescan,
    this.hasServer = false,
    this.localLlm,
    this.onModels,
  });

  final AiBackendStore store;

  /// Fires whenever the selected provider, its model or the routing mode
  /// changes, so the app can re-point its `PortalAiRuntime`.
  final ValueChanged<AiBackendOption>? onChanged;

  final AiBackendLabels labels;
  final AiBackendDiscovery? discovery;
  final bool cloudEligible;

  /// Routing is meaningless without a server to route to, so its row is
  /// hidden until the host says one exists.
  final bool hasServer;

  final Widget? Function(AiBackendOption option)? trailingBuilder;
  final VoidCallback? onRescan;

  /// The in-process engine, in an app that bundles one; its models are the
  /// ones the models row manages.
  final LocalLlmEngine? localLlm;

  /// Replaces the built-in models page, for a host with a screen of its own.
  final VoidCallback? onModels;

  @override
  State<AiSettingsGroup> createState() => _AiSettingsGroupState();
}

class _AiSettingsGroupState extends State<AiSettingsGroup> {
  late final AiBackendDiscovery _discovery =
      widget.discovery ?? AiBackendDiscovery(localLlm: widget.localLlm);
  List<AiBackendOption> _options = const [];
  AiBackendKind? _selected;
  bool _scanning = true;
  String? _modelsValue;

  @override
  void initState() {
    super.initState();
    _scan();
  }

  AiBackendOption? get _selectedOption {
    for (final option in _options) {
      if (option.kind == _selected) return option;
    }
    return null;
  }

  /// The localLlm engine when the app bundles one, else Ollama when the scan
  /// found it. Ollama's host can change, so its manager is built per call.
  AiModelManager? get _manager {
    final engine = widget.localLlm;
    if (engine != null) return engine;
    for (final option in _options) {
      if (option.kind == AiBackendKind.ollama && option.available) {
        return OllamaModelManager(baseUrl: widget.store.ollamaHost);
      }
    }
    return null;
  }

  Future<void> _scan() async {
    setState(() => _scanning = true);
    final options = await _discovery.discover(
      cloudEligible: widget.cloudEligible,
      ollamaHost: widget.store.ollamaHost,
      openAiBaseUrl: widget.store.openAiBaseUrl,
      openAiModel: widget.store.modelFor(AiBackendKind.openAiCompatible) ?? '',
    );
    final kind = await widget.store.resolveSelectedKind(options);
    if (!mounted) return;
    setState(() {
      _options = options;
      _selected = kind;
      _scanning = false;
    });
    await _loadModelsValue();
  }

  Future<void> _loadModelsValue() async {
    final manager = _manager;
    String? value;
    if (manager != null) {
      try {
        value = await aiInstalledModelsLabel(manager, widget.labels);
      } catch (_) {
        // A best-effort read: the row still opens the sheet, which says why.
      }
    }
    if (!mounted) return;
    setState(() => _modelsValue = value);
  }

  Future<void> _openProvider() async {
    await PortalSheet.show<void>(
      context,
      title: widget.labels.providerRow,
      builder: (_) => AiSettingsSection(
        store: widget.store,
        onChanged: widget.onChanged,
        labels: widget.labels,
        discovery: widget.discovery,
        cloudEligible: widget.cloudEligible,
        hasServer: widget.hasServer,
        localLlm: widget.localLlm,
        trailingBuilder: widget.trailingBuilder,
        onRescan: widget.onRescan,
        showRouting: false,
      ),
    );
    if (mounted) await _scan();
  }

  Future<void> _openRouting() async {
    final applied = await AiRoutingSheet.show(
      context,
      store: widget.store,
      labels: widget.labels,
      cloudEligible: widget.cloudEligible,
    );
    if (applied == null || !mounted) return;
    setState(() {});
    // Nothing about the selected backend moved, but routing alone changes
    // what the runtime should be running -- same re-fire the section makes.
    final option = _selectedOption;
    if (option != null) widget.onChanged?.call(option);
  }

  Future<void> _openModels(AiModelManager manager) async {
    final onModels = widget.onModels;
    if (onModels != null) return onModels();
    final changed = await AiModelsPage.open(
      context,
      manager: manager,
      labels: widget.labels,
    );
    if (changed && mounted) await _scan();
  }

  @override
  Widget build(BuildContext context) {
    final labels = widget.labels;
    final manager = _manager;
    return PortalListSection(
      header: labels.assistantTitle,
      children: [
        PortalListItem(
          title: labels.providerRow,
          subtitle: widget.cloudEligible ? null : labels.cloudNote,
          trailing: PortalListAccessory.navigate(
            value: _scanning || _selected == null
                ? labels.scanning
                : labels.titleFor(_selected!),
          ),
          onTap: _openProvider,
        ),
        if (widget.hasServer)
          PortalListItem(
            title: labels.routingRow,
            trailing: PortalListAccessory.navigate(
              value: labels.routingLabelFor(widget.store.routingMode),
            ),
            onTap: _openRouting,
          ),
        if (manager != null)
          PortalListItem(
            title: labels.modelsRow,
            trailing: PortalListAccessory.navigate(value: _modelsValue),
            onTap: () => _openModels(manager),
          ),
      ],
    );
  }
}

/// What the models row shows: the installed models' total size when the
/// manager's catalog knows every one of them ("586 MB"), otherwise how many
/// there are, or [AiBackendLabels.noInstalledModels] for none.
///
/// ponytail: a manager's [AiModelManager.catalog] is "what could be fetched",
/// and Ollama's leaves out what is already installed -- so against it this
/// falls back to the count. The size path is for a catalog that lists
/// installed builds too (the on-device engines); a per-model size on
/// installed() would replace the catalog lookup.
Future<String> aiInstalledModelsLabel(
  AiModelManager manager,
  AiBackendLabels labels,
) async {
  final installed = await manager.installed();
  if (installed.isEmpty) return labels.noInstalledModels;
  final sizes = {
    for (final model in await manager.catalog()) model.id: model.sizeBytes,
  };
  var total = 0;
  for (final id in installed) {
    final size = sizes[id];
    if (size == null) return labels.modelsInstalled(installed.length);
    total += size;
  }
  const gb = 1024 * 1024 * 1024;
  return total >= gb
      ? '${(total / gb).toStringAsFixed(1)} GB'
      : '${(total / (1024 * 1024)).round()} MB';
}
