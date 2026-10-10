import 'dart:async';

import 'package:flutter/material.dart';

import '../models/ai_backend_labels.dart';
import '../models/ai_model_manager.dart';

/// Download, list and delete models for any [AiModelManager].
///
/// One sheet for every backend that owns model files: Ollama pulls a tag into
/// its daemon, an on-device engine writes weights into app storage, and the
/// user is asked the same three things either way.
class AiModelManagerSheet extends StatefulWidget {
  const AiModelManagerSheet({
    super.key,
    required this.manager,
    this.labels = const AiBackendLabels(),
  });

  final AiModelManager manager;
  final AiBackendLabels labels;

  /// Returns true when anything was installed or removed, which is the
  /// caller's cue to re-run discovery.
  static Future<bool> show(
    BuildContext context, {
    required AiModelManager manager,
    AiBackendLabels labels = const AiBackendLabels(),
  }) async {
    final changed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: AiModelManagerSheet(manager: manager, labels: labels),
      ),
    );
    return changed ?? false;
  }

  @override
  State<AiModelManagerSheet> createState() => _AiModelManagerSheetState();
}

class _AiModelManagerSheetState extends State<AiModelManagerSheet> {
  final _customController = TextEditingController();

  List<String> _installed = const [];
  List<AiModelDownload> _catalog = const [];
  bool _loading = true;
  String? _loadError;

  /// The one model being fetched. Two concurrent pulls would race the same
  /// storage and neither backend reports which of them a progress line
  /// belongs to, so the sheet allows one at a time.
  String? _installingId;
  double? _progress;
  String? _installError;
  bool _changed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final installed = await widget.manager.installed();
      final catalog = await widget.manager.catalog();
      if (!mounted) return;
      setState(() {
        _installed = installed;
        _catalog = catalog;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = '$e';
        _loading = false;
      });
    }
  }

  Future<void> _install(String id) async {
    if (id.trim().isEmpty || _installingId != null) return;
    setState(() {
      _installingId = id.trim();
      _progress = null;
      _installError = null;
    });
    try {
      await for (final progress in widget.manager.install(id.trim())) {
        if (!mounted) return;
        setState(() => _progress = progress);
      }
      _changed = true;
      _customController.clear();
    } catch (e) {
      if (!mounted) return;
      setState(() => _installError = '$e');
    }
    if (!mounted) return;
    setState(() {
      _installingId = null;
      _progress = null;
    });
    await _load();
  }

  Future<void> _remove(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(widget.labels.removeModelConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(widget.labels.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(widget.labels.removeModel),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await widget.manager.remove(id);
      _changed = true;
    } catch (e) {
      if (!mounted) return;
      setState(() => _installError = '$e');
    }
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final labels = widget.labels;
    final theme = Theme.of(context);

    return PopScope(
      canPop: _installingId == null,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
      },
      child: SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        labels.manageModelsTitle,
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                    IconButton(
                      tooltip: labels.cancel,
                      icon: const Icon(Icons.close_rounded),
                      onPressed: _installingId != null
                          ? null
                          : () => Navigator.of(context).pop(_changed),
                    ),
                  ],
                ),
              ),
              Flexible(child: _body(theme, labels)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body(ThemeData theme, AiBackendLabels labels) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_loadError != null) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_loadError!, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 12),
            FilledButton.tonal(
              onPressed: _load,
              child: Text(labels.rescan),
            ),
          ],
        ),
      );
    }

    return ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 24),
      children: [
        if (_installError != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Text(
              '${labels.installFailed}: $_installError',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ),
        _SectionHeader(labels.installedModels),
        if (_installed.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Text(
              labels.noInstalledModels,
              style: theme.textTheme.bodySmall,
            ),
          )
        else
          for (final id in _installed)
            ListTile(
              leading: const Icon(Icons.check_circle_outline_rounded),
              title: Text(id),
              trailing: IconButton(
                tooltip: labels.removeModel,
                icon: const Icon(Icons.delete_outline_rounded),
                onPressed: _installingId != null ? null : () => _remove(id),
              ),
            ),
        if (_catalog.isNotEmpty) ...[
          const SizedBox(height: 8),
          _SectionHeader(labels.availableModels),
          for (final model in _catalog)
            ListTile(
              title: Text(model.label),
              subtitle: Text(
                [
                  if (model.sizeBytes != null) _formatSize(model.sizeBytes!),
                  if (model.note != null) model.note!,
                ].join(' · '),
              ),
              trailing: _installingId == model.id
                  ? _ProgressBadge(progress: _progress, labels: labels)
                  : TextButton(
                      onPressed: _installingId != null
                          ? null
                          : () => _install(model.id),
                      child: Text(labels.install),
                    ),
            ),
        ],
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: _customController,
                  enabled: _installingId == null,
                  decoration: InputDecoration(
                    labelText: labels.customModelHint,
                    isDense: true,
                  ),
                  onSubmitted: _install,
                ),
              ),
              const SizedBox(width: 8),
              _installingId != null &&
                      _installingId == _customController.text.trim()
                  ? _ProgressBadge(progress: _progress, labels: labels)
                  : TextButton(
                      onPressed: _installingId != null
                          ? null
                          : () => _install(_customController.text),
                      child: Text(labels.install),
                    ),
            ],
          ),
        ),
      ],
    );
  }

  static String _formatSize(int bytes) {
    const gb = 1024 * 1024 * 1024;
    if (bytes >= gb) return '${(bytes / gb).toStringAsFixed(1)} GB';
    return '${(bytes / (1024 * 1024)).round()} MB';
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Text(
        text.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          letterSpacing: 0.8,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _ProgressBadge extends StatelessWidget {
  const _ProgressBadge({required this.progress, required this.labels});

  /// Null while the backend has not reported a fraction yet, which is an
  /// indeterminate spinner rather than a bar stuck at zero.
  final double? progress;
  final AiBackendLabels labels;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2, value: progress),
          ),
          const SizedBox(width: 8),
          Text(
            progress == null
                ? labels.installing
                : '${(progress! * 100).round()}%',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
