import 'package:flutter/foundation.dart';

import '../platform/portal_ai_platform.dart';

/// Asks the platform whether its own built-in model can run here.
///
/// Nothing about the model is decided in Dart: the status, the reason and the
/// model name all come back from the native side, so a device that ships a
/// different base model needs no change here.
class SystemAiProbe {
  Future<SystemAiDescription> probe() async {
    if (kIsWeb) {
      return const SystemAiDescription.unavailable(
        'On-device AI is not available on web',
      );
    }
    if (defaultTargetPlatform != TargetPlatform.android) {
      return const SystemAiDescription.unavailable(
        'No built-in model API on this platform yet',
      );
    }
    return PortalAiPlatform.describeSystemAi();
  }
}
