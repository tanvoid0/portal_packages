import 'package:flutter/foundation.dart';

import '../platform/portal_ai_platform.dart';

/// Detects Google AI Edge Gallery on Android.
class EdgeGalleryProbe {
  Future<EdgeGalleryProbeResult> probe() async {
    if (kIsWeb ||
        (defaultTargetPlatform != TargetPlatform.android &&
            defaultTargetPlatform != TargetPlatform.iOS)) {
      return const EdgeGalleryProbeResult(
        isInstalled: false,
        reason: 'Edge Gallery is only available on mobile',
      );
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      final installed = await PortalAiPlatform.isEdgeGalleryInstalled();
      return EdgeGalleryProbeResult(
        isInstalled: installed,
        reason: installed
            ? null
            : 'Install Google AI Edge Gallery from the Play Store',
      );
    }

    // iOS: assume available via App Store but we cannot detect install without
    // a native check yet.
    return const EdgeGalleryProbeResult(isInstalled: true, reason: null);
  }
}

class EdgeGalleryProbeResult {
  const EdgeGalleryProbeResult({required this.isInstalled, this.reason});

  final bool isInstalled;
  final String? reason;
}
