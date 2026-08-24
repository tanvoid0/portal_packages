import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'portal_bot_platform_interface.dart';

/// An implementation of [PortalBotPlatform] that uses method channels.
class MethodChannelPortalBot extends PortalBotPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('portal_bot');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
