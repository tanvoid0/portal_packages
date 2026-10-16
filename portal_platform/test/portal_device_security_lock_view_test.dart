import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:portal_platform/portal_platform.dart';

class _Prefs implements DeviceSecurityPreferences {
  @override
  bool get enabled => true;
  @override
  String get key => 'k';
  @override
  Future<void> setEnabled(bool value) async {}
}

void main() {
  late DeviceSecurityController c;

  Future<void> pump(WidgetTester t, PortalDeviceSecurityLockView view) async {
    Get.reset();
    c = Get.put(DeviceSecurityController(preferences: _Prefs()));
    await t.pumpWidget(MaterialApp(home: Scaffold(body: view)));
  }

  tearDown(Get.reset);

  testWidgets('shows the failed check under the message', (t) async {
    await pump(t, const PortalDeviceSecurityLockView(pinMode: false));
    expect(find.text("Didn't recognise you. Try again."), findsNothing);
    c.unlockError.value = "Didn't recognise you. Try again.";
    await t.pump();
    expect(find.text("Didn't recognise you. Try again."), findsOneWidget);
  });

  testWidgets('no screen lock leads with the fix and opens settings', (t) async {
    var opened = 0;
    await pump(
      t,
      PortalDeviceSecurityLockView(
        pinMode: false,
        noScreenLock: true,
        onOpenSettings: () => opened++,
      ),
    );
    expect(find.text('Set a screen lock on this phone first.'), findsOneWidget);
    expect(find.text('Unlock'), findsNothing);
    await t.tap(find.text('Open phone settings'));
    expect(opened, 1);
  });

  testWidgets('Forgot PIN? only when the host handles it', (t) async {
    await pump(t, const PortalDeviceSecurityLockView(pinMode: true));
    expect(find.text('Forgot PIN?'), findsNothing);
    var forgot = 0;
    await pump(
      t,
      PortalDeviceSecurityLockView(pinMode: true, onForgotPin: () => forgot++),
    );
    await t.tap(find.text('Forgot PIN?'));
    expect(forgot, 1);
  });
}
