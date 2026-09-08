import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../discovery/ai_backend_discovery.dart';
import '../discovery/ollama_lan_scan.dart';
import '../models/ai_backend_kind.dart';
import '../models/ai_backend_labels.dart';
import '../models/ai_backend_option.dart';
import '../models/ai_backend_option_models.dart';
import '../platform/edge_gallery_launcher.dart';
import '../platform/portal_ai_platform.dart';
import '../prefs/ai_backend_store.dart';

/// The whole AI group for a settings screen: which provider, which of that
/// provider's models, and the one setting a provider needs to be reachable.
///
/// Drop it into `PortalSettingsPage(aiSection: ...)`. Every model name shown
/// comes from the provider itself — Ollama's tags, the platform's own report
/// of the device model, and `.env` for Gemini, which is the only list this
/// codebase writes down.
class AiSettingsSection extends StatefulWidget {
  const AiSettingsSection({
    super.key,
    required this.store,
    this.onChanged,
    this.labels = const AiBackendLabels(),
    this.discovery,
    this.cloudEligible = true,
    this.showModelConfig = true,
    this.trailingBuilder,
    this.onRescan,
  });

  final AiBackendStore store;

  /// Fires whenever the selected provider or its model changes, so the app can
  /// re-point its `PortalAiRuntime` without a restart.
  final ValueChanged<AiBackendOption>? onChanged;

  final AiBackendLabels labels;
  final AiBackendDiscovery? discovery;
  final bool cloudEligible;

  /// False renders the provider list alone, which is what [AiBackendSelector]
  /// asks for.
  final bool showModelConfig;

  final Widget? Function(AiBackendOption option)? trailingBuilder;
  final VoidCallback? onRescan;

  /// Opens shared preferences and builds the store, for an app that has no
  /// [AiBackendStore] of its own to hand in.
  static Future<AiBackendStore> openStore(String keyPrefix) async =>
      AiBackendStore(
        prefs: await SharedPreferences.getInstance(),
        keyPrefix: keyPrefix,
      );

  @override
  State<AiSettingsSection> createState() => _AiSettingsSectionState();
}

class _AiSettingsSectionState extends State<AiSettingsSection> {
  late final AiBackendDiscovery _discovery;
  List<AiBackendOption> _options = const [];
  AiBackendKind? _selected;
  bool _loading = true;
  bool _downloading = false;
  bool _scanningLan = false;
  bool _lanScanFailed = false;

  @override
  void initState() {
    super.initState();
    _discovery = widget.discovery ?? AiBackendDiscovery();
    _scan();
  }

  AiBackendOption? get _selectedOption {
    for (final option in _options) {
      if (option.kind == _selected) return option;
    }
    return null;
  }

  Future<void> _scan() async {
    setState(() => _loading = true);
    final options = await _discovery.discover(
      cloudEligible: widget.cloudEligible,
      ollamaHost: widget.store.ollamaHost,
    );
    final kind = await widget.store.resolveSelectedKind(options);
    if (!mounted) return;
    setState(() {
      _options = options;
      _selected = kind;
      _loading = false;
    });
  }

  /// [RadioGroup] hands back the tile's value; map it to the option it came
  /// from. Unavailable tiles are disabled, so a null or unknown id is a no-op.
  void _selectById(String? id) {
    for (final option in _options) {
      if (option.id == id) {
        _select(option);
        return;
      }
    }
  }

  Future<void> _select(AiBackendOption option) async {
    if (!option.available) return;
    await widget.store.setSelectedKind(option.kind);
    if (option.supportsInAppInference) {
      await widget.store.ensureModelFor(option);
    }
    if (!mounted) return;
    setState(() => _selected = option.kind);
    widget.onChanged?.call(option);
    // Edge Gallery is not an in-app backend: picking it means "take me there".
    if (option.kind == AiBackendKind.edgeGalleryDelegate) {
      await EdgeGalleryLauncher.launch();
    }
  }

  Future<void> _setModel(AiBackendKind kind, String model) async {
    await widget.store.setModelFor(kind, model);
    if (!mounted) return;
    setState(() {});
    final option = _selectedOption;
    if (option != null) widget.onChanged?.call(option);
  }

  /// Sweeps the network for a daemon and adopts the first one found.
  ///
  /// The desktop running Ollama is on the same wifi but on an address the user
  /// has no reason to know, and the default host is the emulator alias, which
  /// is nowhere on a real phone. Without this the provider looks broken until
  /// someone goes and reads their router's DHCP table.
  Future<void> _findOllama() async {
    setState(() {
      _scanningLan = true;
      _lanScanFailed = false;
    });
    final found = await OllamaLanScan.find();
    if (!mounted) return;
    if (found == null) {
      setState(() {
        _scanningLan = false;
        _lanScanFailed = true;
      });
      return;
    }
    await widget.store.setOllamaHost(found);
    if (!mounted) return;
    setState(() => _scanningLan = false);
    await _scan();
  }

  Future<void> _download() async {
    setState(() => _downloading = true);
    await PortalAiPlatform.downloadSystemAi();
    if (!mounted) return;
    setState(() => _downloading = false);
    await _scan();
  }

  /// The app's trailing widget wins; otherwise a device model that is
  /// supported but not yet fetched gets a download button, so that row is one
  /// tap from working instead of a dead "unavailable".
  Widget? _trailingFor(AiBackendOption option) {
    final custom = widget.trailingBuilder?.call(option);
    if (custom != null) return custom;
    if (option.kind != AiBackendKind.systemOnDevice) return null;
    if (option.metadata['downloadable'] != true) return null;
    return _DownloadButton(
      busy: _downloading,
      labels: widget.labels,
      onPressed: _download,
    );
  }

  @override
  Widget build(BuildContext context) {
    final labels = widget.labels;

    if (_loading) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 12),
            Text(labels.scanning),
          ],
        ),
      );
    }

    final inference = _options.where((o) => o.supportsInAppInference).toList();
    final delegates = _options.where((o) => !o.supportsInAppInference).toList();

    if (inference.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Text(labels.noProviders),
      );
    }

    final titleStyle = Theme.of(
      context,
    ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600);

    return RadioGroup<String>(
      groupValue: _selected?.id,
      onChanged: _selectById,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(labels.selectProvider, style: titleStyle),
          const SizedBox(height: 8),
          // Each provider's settings sit directly under its own row. A phone
          // that cannot see Ollama yet still needs its address field, and that
          // row is disabled -- so hiding the field behind "is selected" leaves
          // the one control that would fix it unreachable.
          for (final option in inference) ...[
            _tile(option),
            if (widget.showModelConfig) ..._configFor(option),
          ],
          if (delegates.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(labels.external, style: titleStyle),
            const SizedBox(height: 8),
            ...delegates.map(_tile),
          ],
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () {
                widget.onRescan?.call();
                _scan();
              },
              child: Text(labels.rescan),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tile(AiBackendOption option) => _OptionTile(
    option: option,
    labels: widget.labels,
    selected: option.kind == _selected,
    trailing: _trailingFor(option),
  );

  /// Settings belonging to [option].
  ///
  /// The model dropdown is for the selected provider only — a settings page
  /// listing every provider's models at once is noise. Ollama's address is the
  /// exception: it is what makes the provider selectable in the first place.
  List<Widget> _configFor(AiBackendOption option) {
    final labels = widget.labels;
    final selected = option.kind == _selected;
    final widgets = <Widget>[];

    if (option.kind == AiBackendKind.ollama &&
        (selected || !option.available)) {
      widgets.addAll([
        _OllamaHostField(
          // Keyed on the host so a value found by the scan replaces what is in
          // the field, rather than the old text outliving the state it came
          // from.
          key: ValueKey('ollama-host-${widget.store.ollamaHost}'),
          initial: widget.store.ollamaHost,
          label: labels.ollamaHost,
          onSubmitted: (host) async {
            await widget.store.setOllamaHost(host);
            await _scan();
          },
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: _scanningLan ? null : _findOllama,
            icon: _scanningLan
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.wifi_find_outlined, size: 18),
            label: Text(
              _scanningLan ? labels.searchingOllama : labels.findOllama,
            ),
          ),
        ),
        if (_lanScanFailed)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              labels.ollamaNotFound,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ),
      ]);
    }

    if (!selected || !option.supportsInAppInference) return widgets;

    final stored = widget.store.modelFor(option.kind);
    if (option.models.isNotEmpty) {
      widgets.add(
        _ModelDropdown(
          label: labels.model,
          models: option.models,
          // A stored model the provider no longer lists must not become the
          // dropdown's value, or Flutter asserts on a missing item.
          value: option.models.contains(stored) ? stored! : option.models.first,
          onChanged: (model) => _setModel(option.kind, model),
        ),
      );
    } else if (option.kind == AiBackendKind.systemOnDevice) {
      widgets.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(
            labels.noModels,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      );
    }
    return widgets;
  }
}

class _DownloadButton extends StatelessWidget {
  const _DownloadButton({
    required this.busy,
    required this.onPressed,
    required this.labels,
  });

  final bool busy;
  final VoidCallback onPressed;
  final AiBackendLabels labels;

  @override
  Widget build(BuildContext context) {
    if (busy) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Text(
          labels.downloading,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      );
    }
    return TextButton(onPressed: onPressed, child: Text(labels.download));
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.option,
    required this.labels,
    required this.selected,
    this.trailing,
  });

  final AiBackendOption option;
  final AiBackendLabels labels;

  /// Whether this is the account's current provider — draws the card's
  /// highlight and the "Selected" badge, independent of the radio's own dot
  /// so the choice reads at a glance while scanning the list.
  final bool selected;

  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final title = labels.titleFor(option.kind);
    final description = labels.descriptionFor(option.kind);
    final modelsSummary = option.modelsSummary;
    final subtitle = option.available
        ? [description, ?modelsSummary].join('\n')
        : (option.unavailableReason ?? labels.unavailable);

    final highlighted = selected && option.available;
    final borderColor = highlighted
        ? cs.primary
        : option.available
        ? cs.outlineVariant
        : cs.outlineVariant.withValues(alpha: 0.5);
    final fillColor = highlighted
        ? cs.primaryContainer.withValues(alpha: 0.45)
        : cs.surfaceContainerHigh.withValues(alpha: 0.5);

    return Opacity(
      opacity: option.available ? 1 : 0.55,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: RadioListTile<String>(
          value: option.id,
          enabled: option.available,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: borderColor, width: highlighted ? 1.5 : 1),
          ),
          tileColor: fillColor,
          contentPadding: const EdgeInsets.fromLTRB(14, 6, 12, 6),
          title: Row(
            children: [
              Icon(
                labels.iconFor(option.kind),
                size: 18,
                color: cs.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (highlighted) ...[
                const SizedBox(width: 8),
                _StatusBadge(label: labels.selectedBadge, color: cs.primary),
              ] else if (!option.available) ...[
                const SizedBox(width: 8),
                _StatusBadge(label: labels.unavailable, color: cs.error),
              ],
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4, left: 26),
            child: Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          secondary: trailing,
        ),
      ),
    );
  }
}

/// A short, coloured status pill next to a provider's title.
class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ModelDropdown extends StatelessWidget {
  const _ModelDropdown({
    required this.label,
    required this.models,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final List<String> models;
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: DropdownButtonFormField<String>(
        key: ValueKey('ai-model-$value'),
        initialValue: value,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        items: models
            .map(
              (m) => DropdownMenuItem<String>(
                value: m,
                child: Text(m, overflow: TextOverflow.ellipsis),
              ),
            )
            .toList(),
        onChanged: (model) {
          if (model != null) onChanged(model);
        },
      ),
    );
  }
}

class _OllamaHostField extends StatefulWidget {
  const _OllamaHostField({
    super.key,
    required this.initial,
    required this.label,
    required this.onSubmitted,
  });

  final String initial;
  final String label;
  final ValueChanged<String> onSubmitted;

  @override
  State<_OllamaHostField> createState() => _OllamaHostFieldState();
}

class _OllamaHostFieldState extends State<_OllamaHostField> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initial,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: _controller,
        decoration: InputDecoration(
          labelText: widget.label,
          hintText: defaultOllamaBaseUrl,
          border: const OutlineInputBorder(),
        ),
        onSubmitted: widget.onSubmitted,
      ),
    );
  }
}
