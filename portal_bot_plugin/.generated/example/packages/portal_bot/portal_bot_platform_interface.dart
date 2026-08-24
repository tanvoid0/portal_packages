import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'portal_bot_method_channel.dart';

abstract class PortalBotPlatform extends PlatformInterface {
  /// Constructs a PortalBotPlatform.
  PortalBotPlatform() : super(token: _token);

  static final Object _token = Object();

  static PortalBotPlatform _instance = MethodChannelPortalBot();

  /// The default instance of [PortalBotPlatform] to use.
  ///
  /// Defaults to [MethodChannelPortalBot].
  static PortalBotPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [PortalBotPlatform] when
  /// they register themselves.
  static set instance(PortalBotPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
