
import 'portal_bot_platform_interface.dart';

class PortalBot {
  Future<String?> getPlatformVersion() {
    return PortalBotPlatform.instance.getPlatformVersion();
  }
}
