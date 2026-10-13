import 'dart:async';

import 'package:flutter/material.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

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
    final changed = await PortalSheet.show<bool>(
      context,
      builder: (_) => AiModelManagerSheet(manager: manager, labels: labels),
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
    final confirmed = await portalConfirm(
      context,
      title: widget.labels.removeModel,
      message: widget.labels.removeModelConfirm,
      confirmLabel: widget.labels.removeModel,
      cancelLabel: widget.labels.cancel,
      isDestructive: true,
    );
    if (!confirmed) return;
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

    return PopScope(
      canPop: _installingId == null,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
      },
      child: PortalSheetScaffold(
        title: labels.manageModelsTitle,
        gutter: false,
        onClose: _installingId != null
            ? null
            : () => Navigator.of(context).pop(_changed),
        body: _body(labels),
      ),
    );
  }

  /// A fraction once the backend reports one, else the indeterminate word.
  String _progressLabel(AiBackendLabels labels) =>
      _progress == null ? labels.installing : '${(_progress! * 100).round()}%';

  Widget _body(AiBackendLabels labels) {
    final spacing = PortalUiTheme.of(context).tokens.spacing;
    if (_loading) {
      return PortalListSection.skeleton(
        hasHeader: true,
        rows: 3,
        leading: PortalSkeletonLeading.none,
      );
    }

    if (_loadError != null) {
      return Padding(
        padding: EdgeInsets.all(spacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: spacing.md,
          children: [
            PortalPrompt(
              size: PortalPromptSize.inline,
              sentiment: PortalSentiment.negative,
              message: _loadError!,
            ),
            PortalButton(
              label: labels.rescan,
              variant: PortalButtonVariant.secondary,
              onPressed: _load,
            ),
          ],
        ),
      );
    }

    final busy = _installingId != null;
    final gutter = EdgeInsets.fromLTRB(spacing.lg, 0, spacing.lg, spacing.md);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_installError != null)
          Padding(
            padding: gutter,
            child: PortalPrompt(
              size: PortalPromptSize.inline,
              sentiment: PortalSentiment.negative,
              message: '${labels.installFailed}: $_installError',
            ),
          ),
        if (_installed.isEmpty) ...[
          PortalSectionHeader(title: labels.installedModels),
          Padding(
            padding: gutter,
            child: PortalPrompt(
              size: PortalPromptSize.inline,
              message: labels.noInstalledModels,
            ),
          ),
        ] else
          PortalListSection(
            header: labels.installedModels,
            style: PortalListStyle.fullBleed,
            children: [
              for (final id in _installed)
                PortalListItem(
                  title: id,
                  leading: PortalListLeading.icon(
                    Icons.check_circle_outline_rounded,
                  ),
                  trailing: PortalListAccessory.iconButton(
                    icon: Icons.delete_outline_rounded,
                    tooltip: labels.removeModel,
                    onPressed: busy ? null : () => _remove(id),
                  ),
                ),
            ],
          ),
        if (_catalog.isNotEmpty)
          PortalListSection(
            header: labels.availableModels,
            style: PortalListStyle.fullBleed,
            children: [
              for (final model in _catalog)
                PortalListItem(
                  title: model.label,
                  subtitle: [
                    if (model.sizeBytes != null) _formatSize(model.sizeBytes!),
                    if (model.note != null) model.note!,
                  ].join(' · '),
                  trailing: _installingId == model.id
                      ? PortalListAccessory.button(
                          label: labels.install,
                          busy: true,
                          busyLabel: _progressLabel(labels),
                          onPressed: null,
                        )
                      : PortalListAccessory.button(
                          label: labels.install,
                          onPressed: busy ? null : () => _install(model.id),
                        ),
                ),
            ],
          ),
        Padding(
          padding: EdgeInsets.fromLTRB(
            spacing.lg,
            spacing.md,
            spacing.lg,
            spacing.lg,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: spacing.sm,
            children: [
              Expanded(
                child: PortalTextField(
                  controller: _customController,
                  enabled: !busy,
                  label: labels.customModelHint,
                  textInputAction: TextInputAction.done,
                  onSubmitted: _install,
                ),
              ),
              PortalButton(
                label: labels.install,
                busyLabel: _progressLabel(labels),
                isLoading:
                    busy && _installingId == _customController.text.trim(),
                size: PortalButtonSize.sm,
                variant: PortalButtonVariant.secondary,
                onPressed: busy ? null : () => _install(_customController.text),
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
