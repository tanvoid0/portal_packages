import 'dart:async';

import 'package:flutter/foundation.dart';

import 'ai_model_downloads.dart';
import 'ai_model_manager.dart';

/// What is on the device and what is on its way, for the models page and the
/// download page.
///
/// One instance per manager, held by the host: a download goes on after its
/// page is left, and the list and the result page both draw from it. It holds
/// the manager's answers and the downloads' progress; the pages only read it
/// and call [load], [download], [cancel] and [remove].
///
/// One download at a time. An engine keeps one active model and two would
/// write the same storage, so [busy] is what the page checks first.
class AiModelsController extends ChangeNotifier {
  AiModelsController(
    this.manager, {
    this.unsupportedReason,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final AiModelManager manager;

  /// Why this device cannot run the backend at all, or null when it can.
  /// Asked on every [load]; a backend that always can leaves it out.
  final Future<String?> Function()? unsupportedReason;
  final DateTime Function() _now;

  /// True until the first look at the device finishes. Later loads are
  /// quiet, so reopening the page does not flash a skeleton over a list it
  /// has.
  bool loading = true;

  /// The first look failed. A later load that fails keeps what is shown.
  bool failed = false;

  String? unsupported;
  List<String> installed = const [];
  List<AiModelDownload> catalog = const [];

  /// Set by any install or remove, cleared by [takeChanged]: the page's cue
  /// to tell its caller to re-run discovery.
  bool changed = false;

  final _downloads = <String, AiModelDownloadState>{};
  final _stops = <String, VoidCallback>{};
  var _loaded = false;

  Map<String, AiModelDownloadState> get downloads =>
      Map.unmodifiable(_downloads);

  AiModelDownloadState? downloadOf(String id) => _downloads[id];

  bool get busy =>
      _downloads.values.any((d) => d.phase == AiModelDownloadPhase.downloading);

  /// The catalogue entry for [id], or a bare one for a model that is
  /// installed but no longer offered.
  AiModelDownload modelFor(String id) => catalog.firstWhere(
    (m) => m.id == id,
    orElse: () => AiModelDownload(id: id, label: id.split('/').last),
  );

  Future<void> load() async {
    if (!_loaded) {
      loading = true;
      failed = false;
      notifyListeners();
    }
    try {
      unsupported = await unsupportedReason?.call();
      if (unsupported == null) {
        installed = await manager.installed();
        catalog = await manager.catalog();
      } else {
        installed = const [];
      }
      _loaded = true;
    } catch (e) {
      debugPrint('ai models: could not list models: $e');
      failed = !_loaded;
    }
    loading = false;
    notifyListeners();
  }

  /// Downloads [id] and tracks it in [downloads]. Meant to be left running:
  /// callers do not wait on it, they watch the controller.
  Future<void> download(String id) async {
    if (busy) return;
    final started = _now();
    _downloads[id] = AiModelDownloadState(id: id);
    notifyListeners();
    final stop = Completer<void>();
    _stops[id] = stop.complete;
    var fraction = 0.0;
    try {
      final sub = manager.install(id).listen((f) {
        fraction = f;
        _downloads[id] = AiModelDownloadState(
          id: id,
          fraction: f,
          left: aiDownloadEta(fraction: f, elapsed: _now().difference(started)),
        );
        notifyListeners();
      });
      try {
        await Future.any([sub.asFuture<void>(), stop.future]);
      } finally {
        unawaited(sub.cancel());
        _stops.remove(id);
      }
      // Cancelled: the manager stops on the subscription's cancel, and the
      // model is simply available again.
      if (stop.isCompleted) {
        _downloads.remove(id);
        notifyListeners();
        return;
      }
      if (!installed.contains(id)) installed = [...installed, id];
      changed = true;
      _downloads[id] = AiModelDownloadState(
        id: id,
        fraction: 1,
        phase: AiModelDownloadPhase.ready,
      );
    } catch (e) {
      debugPrint('ai models: download of $id failed: $e');
      _downloads[id] = AiModelDownloadState(
        id: id,
        fraction: fraction,
        phase: aiDownloadFailurePhase(e),
        error: '$e',
      );
    }
    notifyListeners();
    // What the manager now offers can differ from what it did: an installed
    // model drops out of a catalogue that only lists what is left to fetch.
    unawaited(load());
  }

  /// Stops the download of [id], if one is running. The partial file is the
  /// manager's to keep or drop; the row goes back to Available.
  void cancel(String id) => _stops[id]?.call();

  /// Removes [id] from the device. Throws what the manager throws, with
  /// nothing changed here, so the caller can say it failed.
  Future<void> remove(String id) async {
    await manager.remove(id);
    changed = true;
    installed = [
      for (final i in installed)
        if (i != id) i,
    ];
    _downloads.remove(id);
    notifyListeners();
    unawaited(load());
  }

  /// True once if anything was installed or removed since the last call.
  bool takeChanged() {
    final was = changed;
    changed = false;
    return was;
  }
}
