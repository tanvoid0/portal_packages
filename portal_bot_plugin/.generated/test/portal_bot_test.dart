import 'package:flutter_test/flutter_test.dart';
import 'package:portal_bot/portal_bot.dart';
import 'package:portal_bot/portal_bot_platform_interface.dart';
import 'package:portal_bot/portal_bot_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockPortalBotPlatform
    with MockPlatformInterfaceMixin
    implements PortalBotPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final PortalBotPlatform initialPlatform = PortalBotPlatform.instance;

  test('$MethodChannelPortalBot is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelPortalBot>());
  });

  test('getPlatformVersion', () async {
    PortalBot portalBotPlugin = PortalBot();
    MockPortalBotPlatform fakePlatform = MockPortalBotPlatform();
    PortalBotPlatform.instance = fakePlatform;

    expect(await portalBotPlugin.getPlatformVersion(), '42');
  });
}
