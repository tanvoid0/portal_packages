import 'dart:async';

import 'package:flutter/material.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

import '../models/ai_backend_labels.dart';
import '../models/ai_model_downloads.dart';
import '../models/ai_model_manager.dart';
import '../models/ai_models_controller.dart';

/// What a finished download's button does, in place of Done: "Start a chat"
/// for a host that can open one on the model it just fetched.
typedef AiModelReadyAction = ({
  String label,
  Future<void> Function(BuildContext context, String id) onPressed,
});

/// One model download as a whole page: the controller's progress drawn as a
/// [PortalResultScreen] -- meter and Cancel while it runs, the ready page when
/// it lands, the failure and Try again when it does not.
///
/// It reads the shared [AiModelsController], so leaving it does not stop the
/// download and coming back finds it where it has got to. Starts the download
/// itself when the controller has no record of [model], so a deep link never
/// shows a failure that did not happen.
class AiModelDownloadPage extends StatefulWidget {
  const AiModelDownloadPage({
    super.key,
    required this.controller,
    required this.model,
    this.labels = const AiBackendLabels(),
    this.art,
    this.readyAction,
  });

  final AiModelsController controller;
  final AiModelDownload model;
  final AiBackendLabels labels;

  /// Art for the finished download.
  final Widget? art;
  final AiModelReadyAction? readyAction;

  static Future<void> open(
    BuildContext context, {
    required AiModelsController controller,
    required AiModelDownload model,
    AiBackendLabels labels = const AiBackendLabels(),
    Widget? art,
    AiModelReadyAction? readyAction,
  }) => Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (_) => AiModelDownloadPage(
        controller: controller,
        model: model,
        labels: labels,
        art: art,
        readyAction: readyAction,
      ),
    ),
  );

  @override
  State<AiModelDownloadPage> createState() => _AiModelDownloadPageState();
}

class _AiModelDownloadPageState extends State<AiModelDownloadPage> {
  AiModelsController get _models => widget.controller;
  String get _id => widget.model.id;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _models.downloadOf(_id) == null && !_models.busy) {
        unawaited(_models.download(_id));
      }
    });
  }

  void _retry() {
    if (!_models.busy) unawaited(_models.download(_id));
  }

  void _close() => Navigator.of(context).pop();

  void _cancel() {
    _models.cancel(_id);
    _close();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _models,
    builder: (context, _) => _screen(
      context,
      // No record yet means initState is about to start the download; show it
      // as starting, not failed, so there is no error flash.
      _models.downloadOf(_id) ?? AiModelDownloadState(id: _id),
    ),
  );

  Widget _screen(BuildContext context, AiModelDownloadState download) {
    final labels = widget.labels;
    final model = widget.model;
    final format = PortalFormat.of(context);
    final size = model.sizeBytes ?? 0;
    final total = size > 0 ? aiModelSize(format, size) : '';
    final done = aiModelSize(
      format,
      aiDownloadedBytes(size, download.fraction),
    );
    final percent = (download.fraction * 100).round();
    final action = widget.readyAction;

    PortalButtonDock dock(String label, VoidCallback? onPressed) =>
        PortalButtonDock(
          primary: PortalButton(
            label: label,
            size: PortalButtonSize.lg,
            expand: true,
            onPressed: onPressed,
          ),
        );

    PortalResultScreen failure(String title, String body) => PortalResultScreen(
      state: PortalResultState.error,
      title: title,
      body: body,
      onClose: _close,
      dock: dock(labels.tryAgain, _retry),
    );

    return switch (download.phase) {
      AiModelDownloadPhase.ready => PortalResultScreen(
        state: PortalResultState.success,
        art:
            widget.art ??
            const Icon(Icons.check_circle_outline_rounded, size: 72),
        title: labels.downloadReadyTitle(model.label),
        body: total.isEmpty
            ? labels.downloadReadyBody
            : labels.downloadReadyBodyFor(total),
        onClose: _close,
        dock: action == null
            ? dock(labels.done, _close)
            : dock(action.label, () => action.onPressed(context, _id)),
      ),
      AiModelDownloadPhase.failed => failure(
        labels.downloadFailedTitle(model.label),
        download.error ?? labels.downloadFailedBody(total),
      ),
      AiModelDownloadPhase.noSpace => failure(
        labels.downloadStoppedTitle(percent),
        labels.downloadNoSpaceBody(total),
      ),
      AiModelDownloadPhase.offline => failure(
        labels.downloadStoppedTitle(percent),
        labels.downloadOfflineBody,
      ),
      AiModelDownloadPhase.downloading => PortalResultScreen(
        state: PortalResultState.pending,
        title: labels.downloadingTitle(model.label),
        body: labels.downloadLeaveBody,
        onClose: _close,
        dock: PortalButtonDock(
          primary: PortalButton(
            label: labels.cancelDownload,
            size: PortalButtonSize.lg,
            expand: true,
            variant: PortalButtonVariant.secondary,
            onPressed: _cancel,
          ),
        ),
        progress: download.fraction,
        progressSemanticLabel: labels.downloading,
        progressStartLabel: download.fraction == 0
            ? labels.startingDownload
            : size > 0
            ? labels.downloadProgressOf(done, total)
            : '$percent%',
        progressEndLabel: switch (download.left) {
          Duration.zero => labels.finishingUp,
          final left? => labels.timeLeft(format.duration(left)),
          null => null,
        },
      ),
    };
  }
}
