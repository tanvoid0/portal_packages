import 'dart:async';

import 'package:flutter/material.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

import '../models/ai_backend_labels.dart';
import '../models/ai_model_manager.dart';

/// One model download as a whole page: the manager's [AiModelManager.install]
/// stream drawn as a [PortalResultScreen] -- meter and Cancel while it runs,
/// Done when it lands, the failure and Try again when it does not.
///
/// The page owns the stream, so it cannot be left mid-download (no close, back
/// is held); Cancel is the way out. Pops `true` once the model is installed,
/// `false` otherwise.
class AiModelDownloadPage extends StatefulWidget {
  const AiModelDownloadPage({
    super.key,
    required this.manager,
    required this.model,
    this.labels = const AiBackendLabels(),
  });

  final AiModelManager manager;
  final AiModelDownload model;
  final AiBackendLabels labels;

  /// Resolves true when [model] was installed.
  static Future<bool> open(
    BuildContext context, {
    required AiModelManager manager,
    required AiModelDownload model,
    AiBackendLabels labels = const AiBackendLabels(),
  }) async {
    final installed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AiModelDownloadPage(
          manager: manager,
          model: model,
          labels: labels,
        ),
      ),
    );
    return installed ?? false;
  }

  @override
  State<AiModelDownloadPage> createState() => _AiModelDownloadPageState();
}

enum _Phase { downloading, ready, failed }

class _AiModelDownloadPageState extends State<AiModelDownloadPage> {
  final _clock = Stopwatch();
  StreamSubscription<double>? _sub;
  _Phase _phase = _Phase.downloading;
  double? _progress;
  String? _error;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _start() {
    _clock
      ..reset()
      ..start();
    setState(() {
      _phase = _Phase.downloading;
      _progress = null;
      _error = null;
    });
    _sub = widget.manager
        .install(widget.model.id)
        .listen(
          (p) {
            if (mounted) setState(() => _progress = p);
          },
          onError: (Object e) {
            if (mounted) {
              setState(() {
                _phase = _Phase.failed;
                _error = '$e';
              });
            }
          },
          onDone: () {
            if (mounted && _error == null) {
              setState(() => _phase = _Phase.ready);
            }
          },
          cancelOnError: true,
        );
  }

  void _cancel() {
    _sub?.cancel();
    Navigator.of(context).pop(false);
  }

  @override
  Widget build(BuildContext context) {
    final labels = widget.labels;
    final name = widget.model.label;
    final f = PortalFormat.of(context);
    final size = widget.model.sizeBytes;

    PortalButtonDock dock(String label, VoidCallback onPressed, {
      bool quiet = false,
      Widget? secondary,
    }) => PortalButtonDock(
      primary: PortalButton(
        label: label,
        size: PortalButtonSize.lg,
        expand: true,
        variant: quiet
            ? PortalButtonVariant.secondary
            : PortalButtonVariant.primary,
        onPressed: onPressed,
      ),
      secondary: secondary,
    );

    final Widget screen = switch (_phase) {
      _Phase.ready => PortalResultScreen(
        state: PortalResultState.success,
        art: const Icon(Icons.check_circle_outline_rounded, size: 72),
        title: labels.downloadReadyTitle(name),
        body: size == null
            ? labels.downloadReadyBody
            : '${labels.downloadReadyBody} ${f.bytes(size)}',
        dock: dock(labels.done, () => Navigator.of(context).pop(true)),
      ),
      _Phase.failed => PortalResultScreen(
        state: PortalResultState.error,
        art: const Icon(Icons.error_outline_rounded, size: 72),
        title: labels.installFailed,
        body: _error ?? '',
        onClose: () => Navigator.of(context).pop(false),
        dock: dock(labels.tryAgain, _start),
      ),
      _Phase.downloading => _pending(labels, name, f, size),
    };
    return PopScope(canPop: _phase != _Phase.downloading, child: screen);
  }

  Widget _pending(
    AiBackendLabels labels,
    String name,
    PortalFormat f,
    int? size,
  ) {
    final p = _progress;
    // ponytail: straight-line estimate from elapsed time; smooth it if a
    // backend's speed varies enough to make the figure jump.
    // Held back for 3s (too little signal) and when under a second remains
    // ("About 0s left" on the last tick).
    final eta =
        p == null || p < 0.05 || _clock.elapsed < const Duration(seconds: 3)
        ? null
        : _clock.elapsed * ((1 - p) / p);
    final left = eta != null && eta >= const Duration(seconds: 1) ? eta : null;
    return PortalResultScreen(
      state: PortalResultState.pending,
      art: const Icon(Icons.download_rounded, size: 72),
      title: labels.downloadingTitle(name),
      body: labels.downloadKeepOpen,
      progress: p ?? 0,
      progressStartLabel: p == null
          ? labels.startingDownload
          : size == null
          ? '${(p * 100).round()}%'
          : '${f.bytes((size * p).round())} of ${f.bytes(size)}',
      progressEndLabel: left == null
          ? null
          : labels.timeLeft(
              f.duration(left, style: PortalDurationStyle.compact),
            ),
      dock: PortalButtonDock(
        primary: PortalButton(
          label: labels.cancelDownload,
          size: PortalButtonSize.lg,
          expand: true,
          variant: PortalButtonVariant.secondary,
          onPressed: _cancel,
        ),
      ),
    );
  }
}
