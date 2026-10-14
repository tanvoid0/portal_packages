import 'package:flutter/material.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

import '../models/ai_backend_labels.dart';
import '../models/ai_model_manager.dart';
import 'ai_model_download_page.dart';

/// List, download and delete models for any [AiModelManager], as a page.
///
/// One page for every backend that owns model files: Ollama pulls a tag into
/// its daemon, an on-device engine writes weights into app storage, and the
/// user is asked the same three things either way. A download opens
/// [AiModelDownloadPage]; one model is fetched at a time because that page owns
/// the stream and cannot be left.
class AiModelsPage extends StatefulWidget {
  const AiModelsPage({
    super.key,
    required this.manager,
    this.labels = const AiBackendLabels(),
  });

  final AiModelManager manager;
  final AiBackendLabels labels;

  /// Returns true when anything was installed or removed, which is the
  /// caller's cue to re-run discovery.
  static Future<bool> open(
    BuildContext context, {
    required AiModelManager manager,
    AiBackendLabels labels = const AiBackendLabels(),
  }) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AiModelsPage(manager: manager, labels: labels),
      ),
    );
    return changed ?? false;
  }

  @override
  State<AiModelsPage> createState() => _AiModelsPageState();
}

class _AiModelsPageState extends State<AiModelsPage> {
  final _customController = TextEditingController();

  List<String> _installed = const [];
  List<AiModelDownload> _catalog = const [];
  bool _loading = true;
  String? _loadError;
  String? _actionError;
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

  Future<void> _install(AiModelDownload model) async {
    if (model.id.trim().isEmpty) return;
    setState(() => _actionError = null);
    final installed = await AiModelDownloadPage.open(
      context,
      manager: widget.manager,
      model: model,
      labels: widget.labels,
    );
    if (!mounted) return;
    if (installed) {
      _changed = true;
      _customController.clear();
    }
    await _load();
  }

  Future<void> _remove(String id) async {
    final labels = widget.labels;
    final confirmed = await portalConfirm(
      context,
      title: labels.removeModel,
      message: labels.removeModelConfirm,
      confirmLabel: labels.removeModel,
      cancelLabel: labels.cancel,
      isDestructive: true,
    );
    if (!confirmed) return;
    try {
      await widget.manager.remove(id);
      _changed = true;
    } catch (e) {
      if (!mounted) return;
      setState(() => _actionError = '$e');
    }
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final labels = widget.labels;
    return PopScope(
      // Hand the result back on a system back too.
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.of(context).pop(_changed);
      },
      child: PortalScrollPage(
        title: labels.manageModelsTitle,
        leading: PortalButton.icon(
          icon: Icons.arrow_back_rounded,
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          variant: PortalButtonVariant.ghost,
          onPressed: () => Navigator.of(context).pop(_changed),
        ),
        children: _children(labels),
      ),
    );
  }

  List<Widget> _children(AiBackendLabels labels) {
    final spacing = PortalUiTheme.of(context).tokens.spacing;
    final gutter = EdgeInsets.fromLTRB(spacing.lg, 0, spacing.lg, spacing.md);

    if (_loading) {
      return [
        PortalListSection.skeleton(
          hasHeader: true,
          rows: 2,
          leading: PortalSkeletonLeading.none,
        ),
        PortalListSection.skeleton(
          hasHeader: true,
          rows: 3,
          leading: PortalSkeletonLeading.none,
        ),
      ];
    }

    if (_loadError != null) {
      return [
        Padding(
          padding: EdgeInsets.all(spacing.lg),
          child: Column(
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
        ),
      ];
    }

    return [
      if (_actionError != null)
        Padding(
          padding: gutter,
          child: PortalPrompt(
            size: PortalPromptSize.inline,
            sentiment: PortalSentiment.negative,
            message: '${labels.installFailed}: $_actionError',
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
                  onPressed: () => _remove(id),
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
                trailing: PortalListAccessory.button(
                  label: labels.install,
                  onPressed: () => _install(model),
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
                label: labels.customModelHint,
                textInputAction: TextInputAction.done,
                onSubmitted: _installCustom,
              ),
            ),
            PortalButton(
              label: labels.install,
              size: PortalButtonSize.sm,
              variant: PortalButtonVariant.secondary,
              onPressed: () => _installCustom(_customController.text),
            ),
          ],
        ),
      ),
    ];
  }

  void _installCustom(String id) =>
      _install(AiModelDownload(id: id.trim(), label: id.trim()));

  static String _formatSize(int bytes) {
    const gb = 1024 * 1024 * 1024;
    if (bytes >= gb) return '${(bytes / gb).toStringAsFixed(1)} GB';
    return '${(bytes / (1024 * 1024)).round()} MB';
  }
}
