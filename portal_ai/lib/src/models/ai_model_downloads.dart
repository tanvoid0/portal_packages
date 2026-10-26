import 'package:portal_ui_core/portal_ui_core.dart';

/// How far one download has got. A manager reports a fraction only, so
/// everything else on the page is worked out from that.
///
/// [noSpace] and [offline] are [failed] with a cause the controller could
/// tell; see [aiDownloadFailurePhase].
enum AiModelDownloadPhase { downloading, ready, failed, noSpace, offline }

/// Which failure phase an install error reads as.
// ponytail: engines wrap every cause in one exception, so this sniffs the
// message text. A platform error code from the manager would replace it.
AiModelDownloadPhase aiDownloadFailurePhase(Object error) {
  final text = '$error'.toLowerCase();
  if (text.contains('enospc') ||
      text.contains('no space') ||
      text.contains('not enough space') ||
      text.contains('insufficient storage')) {
    return AiModelDownloadPhase.noSpace;
  }
  if (text.contains('socketexception') ||
      text.contains('failed host lookup') ||
      text.contains('network is unreachable') ||
      text.contains('no internet') ||
      text.contains('connection')) {
    return AiModelDownloadPhase.offline;
  }
  return AiModelDownloadPhase.failed;
}

/// One download as the list and the result page read it.
class AiModelDownloadState {
  const AiModelDownloadState({
    required this.id,
    this.fraction = 0,
    this.left,
    this.phase = AiModelDownloadPhase.downloading,
    this.error,
  });

  final String id;

  /// 0..1, as the manager reports it.
  final double fraction;

  /// Null until there is enough to estimate from.
  final Duration? left;
  final AiModelDownloadPhase phase;

  /// What the manager threw, for a failed page that has nothing better to
  /// say.
  final String? error;

  /// Stopped short of ready: failed, out of space or offline.
  bool get stopped =>
      phase != AiModelDownloadPhase.downloading &&
      phase != AiModelDownloadPhase.ready;
}

/// Bytes fetched so far: the model's size times the manager's fraction.
int aiDownloadedBytes(int sizeBytes, double fraction) =>
    (sizeBytes * fraction.clamp(0.0, 1.0)).round();

/// Time left, from how long [fraction] of the download has taken so far.
///
/// Null until there is something to extrapolate from: under 2% done or under
/// three seconds in, the rate is noise. Rounded up -- to 5 seconds under a
/// minute, to whole minutes after -- so the label settles instead of ticking
/// down second by second.
// ponytail: the average over the whole download, so a link that speeds up or
// slows down corrects slowly. A rolling window over the last few fractions
// would follow it; nothing here needs that yet.
Duration? aiDownloadEta({required double fraction, required Duration elapsed}) {
  if (fraction >= 1) return Duration.zero;
  if (fraction < 0.02 || elapsed < const Duration(seconds: 3)) return null;
  final left = elapsed * ((1 - fraction) / fraction);
  if (left < const Duration(minutes: 1)) {
    return Duration(seconds: (left.inSeconds / 5).ceil() * 5);
  }
  return Duration(minutes: (left.inSeconds / 60).ceil());
}

/// "586 MB". A manager writes a size as megabytes x 1024 x 1024 -- the figure
/// on the model's card -- while [PortalFormat.bytes] counts in thousands, so
/// the figure is scaled back first or 586 MB would read 614 MB.
String aiModelSize(PortalFormat format, num managerBytes) =>
    format.bytes(managerBytes / (1024 * 1024) * 1000000);
