import 'package:flutter/material.dart';

import '../discovery/ai_backend_discovery.dart';
import '../models/ai_backend_kind.dart';
import '../models/ai_backend_labels.dart';
import '../models/ai_backend_option.dart';
import '../models/ai_backend_option_models.dart';
import '../prefs/ai_backend_store.dart';

/// Reusable settings panel that lists AI backends available on this device.
class AiBackendSelector extends StatefulWidget {
  const AiBackendSelector({
    super.key,
    required this.store,
    required this.onChanged,
    this.labels = const AiBackendLabels(),
    this.discovery,
    this.cloudEligible = true,
    this.trailingBuilder,
    this.onRescan,
  });

  final AiBackendStore store;
  final ValueChanged<AiBackendOption> onChanged;
  final AiBackendLabels labels;
  final AiBackendDiscovery? discovery;
  final bool cloudEligible;
  final Widget? Function(AiBackendOption option)? trailingBuilder;
  final VoidCallback? onRescan;

  @override
  State<AiBackendSelector> createState() => _AiBackendSelectorState();
}

class _AiBackendSelectorState extends State<AiBackendSelector> {
  late final AiBackendDiscovery _discovery;
  List<AiBackendOption> _options = const [];
  String? _selectedId;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _discovery = widget.discovery ?? AiBackendDiscovery();
    _selectedId = widget.store.selectedBackendId;
    _scan();
  }

  Future<void> _scan() async {
    setState(() => _loading = true);
    final options = await _discovery.discover(
      cloudEligible: widget.cloudEligible,
      ollamaHost: widget.store.ollamaHost,
      onDeviceModelPath: widget.store.onDeviceModelPath,
    );
    final kind = await widget.store.resolveSelectedKind(options);
    if (!mounted) return;
    setState(() {
      _options = options;
      _selectedId = kind.id;
      _loading = false;
    });
  }

  Future<void> _select(AiBackendOption option) async {
    if (!option.available) return;
    await widget.store.setSelectedKind(option.kind);
    if (option.supportsInAppInference) {
      await applyDefaultModelForBackend(
        option: option,
        setOllamaModel: widget.store.setOllamaModel,
        setGeminiModel: widget.store.setGeminiModel,
        currentOllamaModel: widget.store.ollamaModel,
        currentGeminiModel: widget.store.geminiModel,
      );
    }
    if (!mounted) return;
    setState(() => _selectedId = option.kind.id);
    widget.onChanged(option);
  }

  @override
  Widget build(BuildContext context) {
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
            Text(widget.labels.scanning),
          ],
        ),
      );
    }

    final inferenceOptions =
        _options.where((o) => o.supportsInAppInference).toList();
    final delegateOptions =
        _options.where((o) => !o.supportsInAppInference).toList();

    if (inferenceOptions.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Text(widget.labels.noProviders),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          widget.labels.selectProvider,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        ...inferenceOptions.map((option) => _OptionTile(
              option: option,
              labels: widget.labels,
              groupValue: _selectedId,
              onSelect: () => _select(option),
              trailing: widget.trailingBuilder?.call(option),
            )),
        if (delegateOptions.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            'External',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          ...delegateOptions.map(
            (option) => _OptionTile(
              option: option,
              labels: widget.labels,
              groupValue: _selectedId,
              onSelect: () => _select(option),
              trailing: widget.trailingBuilder?.call(option),
            ),
          ),
        ],
        if (widget.onRescan != null) ...[
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () {
                widget.onRescan?.call();
                _scan();
              },
              child: const Text('Rescan providers'),
            ),
          ),
        ],
      ],
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.option,
    required this.labels,
    required this.groupValue,
    required this.onSelect,
    this.trailing,
  });

  final AiBackendOption option;
  final AiBackendLabels labels;
  final String? groupValue;
  final VoidCallback onSelect;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = labels.titleFor(option.kind);
    final description = labels.descriptionFor(option.kind);
    final canSelect = option.available;
    final modelsSummary = option.modelsSummary;
    final subtitle = option.available
        ? [
            description,
            ?modelsSummary,
          ].join('\n')
        : (option.unavailableReason ?? labels.unavailable);

    return Opacity(
      opacity: option.available ? 1 : 0.55,
      child: RadioListTile<String>(
        value: option.id,
        groupValue: groupValue,
        onChanged: canSelect ? (_) => onSelect() : null,
        title: Text(title, style: theme.textTheme.bodyLarge),
        subtitle: Text(
          subtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        secondary: trailing,
        contentPadding: EdgeInsets.zero,
      ),
    );
  }
}
