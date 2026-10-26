import 'dart:async';

import 'package:flutter/material.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

import '../models/ai_backend_labels.dart';
import '../models/ai_model_downloads.dart';
import '../models/ai_model_manager.dart';
import '../models/ai_models_controller.dart';
import 'ai_model_download_page.dart';

/// List, download and delete models for any [AiModelManager], as a page.
///
/// One page for every backend that owns model files: Ollama pulls a tag into
/// its daemon, an on-device engine writes weights into app storage, and the
/// user is asked the same things either way. Models are grouped Installed /
/// Downloading / Available; a download opens [AiModelDownloadPage] but does
/// not need it open to go on, and a row in Downloading opens it again.
///
/// Give it a [manager] and it keeps its own [AiModelsController]; give it a
/// [controller] when the host keeps one for the app's life, so a download
/// outlives this page. Hosts with an "in use" model pass [activeId] and
/// [onUse], which adds the Active badge and a "Use this model" action.
class AiModelsPage extends StatefulWidget {
  const AiModelsPage({
    super.key,
    this.manager,
    this.controller,
    this.labels = const AiBackendLabels(),
    this.activeId,
    this.onUse,
    this.allowCustom = true,
    this.emptyArt,
    this.readyArt,
    this.readyAction,
  }) : assert(
         (manager == null) != (controller == null),
         'give a manager or a controller, not both',
       );

  final AiModelManager? manager;
  final AiModelsController? controller;
  final AiBackendLabels labels;

  /// The installed model the host answers with, read on every draw so a
  /// pick or a removal moves the badge.
  final ValueGetter<String?>? activeId;

  /// Makes [id] the model in use. No "Use this model" action when null.
  final Future<void> Function(String id)? onUse;

  /// The "Or type a model name" field, for a backend that can fetch a name
  /// the catalogue does not list. A fixed catalogue leaves it out, and then
  /// the empty state offers the catalogue instead of a bare field.
  final bool allowCustom;

  /// Art for the empty and unsupported states, and for a finished download.
  final Widget? emptyArt;
  final Widget? readyArt;

  /// What the finished download's button does, in place of Done.
  final AiModelReadyAction? readyAction;

  /// Returns true when anything was installed or removed, which is the
  /// caller's cue to re-run discovery.
  static Future<bool> open(
    BuildContext context, {
    AiModelManager? manager,
    AiModelsController? controller,
    AiBackendLabels labels = const AiBackendLabels(),
    ValueGetter<String?>? activeId,
    Future<void> Function(String id)? onUse,
    bool allowCustom = true,
    Widget? emptyArt,
    Widget? readyArt,
    AiModelReadyAction? readyAction,
  }) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AiModelsPage(
          manager: manager,
          controller: controller,
          labels: labels,
          activeId: activeId,
          onUse: onUse,
          allowCustom: allowCustom,
          emptyArt: emptyArt,
          readyArt: readyArt,
          readyAction: readyAction,
        ),
      ),
    );
    return changed ?? false;
  }

  @override
  State<AiModelsPage> createState() => _AiModelsPageState();
}

class _AiModelsPageState extends State<AiModelsPage> {
  final _customController = TextEditingController();
  late final AiModelsController _models =
      widget.controller ?? AiModelsController(widget.manager!);
  late var _browsing = widget.allowCustom;
  String? _actionError;

  @override
  void initState() {
    super.initState();
    unawaited(_models.load());
  }

  @override
  void dispose() {
    _customController.dispose();
    if (widget.controller == null) _models.dispose();
    super.dispose();
  }

  Future<void> _openDownload(AiModelDownload model) => AiModelDownloadPage.open(
    context,
    controller: _models,
    model: model,
    labels: widget.labels,
    art: widget.readyArt,
    readyAction: widget.readyAction,
  );

  /// Starts [model]'s download, or retries it, and opens its page.
  Future<void> _install(AiModelDownload model) async {
    if (model.id.trim().isEmpty) return;
    final labels = widget.labels;
    if (_models.busy) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(
          content: Text(
            '${labels.oneDownloadAtATime}. ${labels.oneDownloadAtATimeBody}',
          ),
        ),
      );
      return;
    }
    setState(() => _actionError = null);
    unawaited(_models.download(model.id));
    _customController.clear();
    await _openDownload(model);
  }

  Future<void> _remove(AiModelDownload model) async {
    final labels = widget.labels;
    final size = model.sizeBytes;
    final confirmed = await portalConfirm(
      context,
      title: labels.removeModelTitle(model.label),
      message: labels.removeModelMessage(
        model.label,
        freed: size == null || size <= 0
            ? null
            : aiModelSize(PortalFormat.of(context), size),
        active: model.id == widget.activeId?.call(),
      ),
      confirmLabel: labels.removeModel,
      cancelLabel: labels.cancel,
      isDestructive: true,
    );
    if (!confirmed) return;
    try {
      await _models.remove(model.id);
      if (mounted) setState(() => _actionError = null);
    } catch (e) {
      if (mounted) setState(() => _actionError = '$e');
    }
  }

  Future<void> _use(AiModelDownload model) async {
    try {
      await widget.onUse?.call(model.id);
    } catch (e) {
      if (mounted) setState(() => _actionError = '$e');
    }
  }

  void _options(AiModelDownload model) {
    final labels = widget.labels;
    showPortalActionSheet(context, title: model.label, [
      if (widget.onUse != null && model.id != widget.activeId?.call())
        PortalAction(
          icon: PortalIcons.check_circle_rounded,
          label: labels.useModel,
          onPressed: () => _use(model),
        ),
      PortalAction(
        icon: PortalIcons.delete_rounded,
        label: labels.removeModel,
        destructive: true,
        onPressed: () => _remove(model),
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _models,
    builder: (context, _) => PopScope(
      // Hand the result back on a system back too.
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.of(context).pop(_models.takeChanged());
      },
      child: _page(context),
    ),
  );

  Widget _page(BuildContext context) {
    final labels = widget.labels;
    final format = PortalFormat.of(context);
    final m = _models;
    final installed = [for (final id in m.installed) m.modelFor(id)];
    final downloading = <AiModelDownload>[];
    final available = <AiModelDownload>[];
    for (final model in m.catalog) {
      if (m.installed.contains(model.id)) continue;
      final phase = m.downloadOf(model.id)?.phase;
      (phase == AiModelDownloadPhase.downloading ? downloading : available).add(
        model,
      );
    }
    final used = installed.fold<int>(0, (sum, x) => sum + (x.sizeBytes ?? 0));
    final empty =
        !_browsing && installed.isEmpty && downloading.isEmpty && !m.loading;
    final showsData =
        !m.loading && m.unsupported == null && !m.failed && !empty;

    Widget bar(List<Widget> children, {Widget? body}) {
      final title = labels.manageModelsTitle;
      final subtitle = showsData && used > 0
          ? labels.modelsUsing(aiModelSize(format, used))
          : null;
      final leading = PortalButton.icon(
        icon: Icons.arrow_back_rounded,
        tooltip: MaterialLocalizations.of(context).backButtonTooltip,
        variant: PortalButtonVariant.ghost,
        onPressed: () => Navigator.of(context).pop(m.takeChanged()),
      );
      return body == null
          ? PortalScrollPage(
              title: title,
              subtitle: subtitle,
              leading: leading,
              children: children,
            )
          : PortalScrollPage.custom(
              title: title,
              subtitle: subtitle,
              leading: leading,
              body: body,
            );
    }

    if (m.loading) {
      return bar([
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
      ]);
    }
    if (m.unsupported != null) {
      return bar(
        const [],
        body: Center(
          child: PortalEmptyState(
            inCard: false,
            iconWidget: widget.emptyArt,
            icon: widget.emptyArt == null
                ? PortalIcons.cloud_off_rounded
                : null,
            title: labels.modelsUnsupportedTitle,
            message: m.unsupported,
          ),
        ),
      );
    }
    final spacing = PortalUiTheme.of(context).tokens.spacing;
    if (m.failed) {
      return bar([
        Padding(
          padding: EdgeInsets.all(spacing.lg),
          child: PortalPrompt(
            size: PortalPromptSize.compact,
            sentiment: PortalSentiment.negative,
            message: labels.modelsLoadFailed,
            action: (label: labels.retry, onPressed: m.load),
          ),
        ),
      ]);
    }
    if (empty) {
      return bar(
        const [],
        body: Center(
          child: PortalEmptyState(
            inCard: false,
            iconWidget: widget.emptyArt,
            icon: widget.emptyArt == null
                ? PortalIcons.cloud_off_rounded
                : null,
            title: labels.modelsEmptyTitle,
            message: labels.modelsEmptyMessage,
            actionLabel: labels.modelsEmptyAction,
            onAction: () => setState(() => _browsing = true),
          ),
        ),
      );
    }

    final gutter = EdgeInsets.fromLTRB(spacing.lg, 0, spacing.lg, spacing.md);
    final offline = m.downloads.values.any(
      (d) => d.phase == AiModelDownloadPhase.offline,
    );
    return bar([
      if (offline)
        Padding(
          padding: EdgeInsets.fromLTRB(
            spacing.lg,
            spacing.sm,
            spacing.lg,
            spacing.sm,
          ),
          child: PortalPrompt(
            size: PortalPromptSize.compact,
            title: labels.modelsOfflineTitle,
            message: labels.modelsOfflineMessage,
            icon: PortalIcons.cloud_off_rounded,
          ),
        ),
      if (_actionError != null)
        Padding(
          padding: gutter,
          child: PortalPrompt(
            size: PortalPromptSize.inline,
            sentiment: PortalSentiment.negative,
            message: '${labels.installFailed}: $_actionError',
          ),
        ),
      if (installed.isEmpty) ...[
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
          children: [for (final model in installed) _installed(model, format)],
        ),
      if (downloading.isNotEmpty)
        PortalListSection(
          header: labels.downloadingModels,
          style: PortalListStyle.fullBleed,
          children: [
            for (final model in downloading) _downloading(model, format),
          ],
        ),
      if (available.isNotEmpty)
        PortalListSection(
          header: labels.availableModels,
          style: PortalListStyle.fullBleed,
          children: [for (final model in available) _available(model, format)],
        ),
      if (widget.allowCustom) _customField(spacing, labels),
    ]);
  }

  Widget _installed(AiModelDownload model, PortalFormat format) {
    final labels = widget.labels;
    final active = model.id == widget.activeId?.call();
    final size = model.sizeBytes;
    return PortalListItem(
      key: ValueKey(model.id),
      title: model.label,
      subtitle: size == null || size <= 0 ? null : aiModelSize(format, size),
      // `meta` is what the row reads out; the badge is what it shows.
      meta: active ? labels.activeBadge : null,
      metaWidget: active
          ? PortalBadge(
              label: labels.activeBadge,
              tone: PortalBadgeTone.success,
              icon: PortalIcons.check_circle_rounded,
            )
          : null,
      trailing: PortalListAccessory.iconButton(
        icon: PortalIcons.more_vert_rounded,
        tooltip: labels.modelOptions(model.label),
        onPressed: () => _options(model),
      ),
    );
  }

  Widget _downloading(AiModelDownload model, PortalFormat format) {
    final labels = widget.labels;
    final fraction = _models.downloadOf(model.id)?.fraction ?? 0;
    final size = model.sizeBytes ?? 0;
    final percent = '${(fraction * 100).round()}%';
    return PortalListItem(
      key: ValueKey(model.id),
      title: model.label,
      subtitle: size <= 0
          ? percent
          : '$percent · ${labels.downloadProgressOf(aiModelSize(format, aiDownloadedBytes(size, fraction)), aiModelSize(format, size))}',
      progress: fraction,
      trailing: const PortalListAccessory.navigate(),
      onTap: () => _openDownload(model),
    );
  }

  Widget _available(AiModelDownload model, PortalFormat format) {
    final labels = widget.labels;
    final failed = _models.downloadOf(model.id)?.stopped ?? false;
    final size = model.sizeBytes;
    final sizeText = size == null || size <= 0
        ? null
        : aiModelSize(format, size);
    return PortalListItem(
      key: ValueKey(model.id),
      title: model.label,
      subtitle: failed
          ? labels.modelDownloadFailed(sizeText ?? '')
          : [?sizeText, ?model.note].join(' · '),
      trailing: PortalListAccessory.button(
        label: failed ? labels.retry : labels.install,
        tooltip: failed
            ? labels.modelRetryAction(model.label)
            : labels.modelDownloadAction(model.label, sizeText ?? ''),
        onPressed: () => _install(model),
      ),
    );
  }

  Widget _customField(PortalSpacing spacing, AiBackendLabels labels) {
    void install(String id) =>
        _install(AiModelDownload(id: id.trim(), label: id.trim()));
    return Padding(
      padding: EdgeInsets.fromLTRB(
        spacing.lg,
        spacing.md,
        spacing.lg,
        spacing.lg,
      ),
      child: Row(
        // The field's label sits above its box: end-align so the button
        // meets the box, at the row buttons' size (md, not sm).
        crossAxisAlignment: CrossAxisAlignment.end,
        spacing: spacing.sm,
        children: [
          Expanded(
            child: PortalTextField(
              controller: _customController,
              label: labels.customModelHint,
              textInputAction: TextInputAction.done,
              onSubmitted: install,
            ),
          ),
          PortalButton(
            label: labels.install,
            variant: PortalButtonVariant.secondary,
            onPressed: () => install(_customController.text),
          ),
        ],
      ),
    );
  }
}
