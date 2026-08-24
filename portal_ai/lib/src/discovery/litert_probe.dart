import 'package:flutter/foundation.dart';

/// Checks whether on-device LiteRT-LM inference could run on this device.
class LiteRtProbe {
  Future<LiteRtProbeResult> probe({String? modelPath}) async {
    if (kIsWeb) {
      return const LiteRtProbeResult(
        isCapable: false,
        isConfigured: false,
        reason: 'On-device inference is not available on web',
      );
    }

    if (defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      return LiteRtProbeResult(
        isCapable: true,
        isConfigured: modelPath != null && modelPath.isNotEmpty,
        reason: modelPath == null || modelPath.isEmpty
            ? 'Model download not configured yet'
            : null,
      );
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      return LiteRtProbeResult(
        isCapable: true,
        isConfigured: modelPath != null && modelPath.isNotEmpty,
        reason: modelPath == null || modelPath.isEmpty
            ? 'On-device model not downloaded yet'
            : null,
      );
    }

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return const LiteRtProbeResult(
        isCapable: true,
        isConfigured: false,
        reason: 'On-device model not downloaded yet (CPU only on iOS)',
      );
    }

    return const LiteRtProbeResult(
      isCapable: false,
      isConfigured: false,
      reason: 'Platform not supported',
    );
  }
}

class LiteRtProbeResult {
  const LiteRtProbeResult({
    required this.isCapable,
    required this.isConfigured,
    this.reason,
  });

  final bool isCapable;
  final bool isConfigured;
  final String? reason;

  bool get isAvailable => isCapable && isConfigured;
}
