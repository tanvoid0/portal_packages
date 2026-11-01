import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portal_platform/portal_platform.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

/// Drives [portalInstallAndReport]'s failure handling. A signature conflict —
/// an installed copy signed with a different key — must offer to uninstall and
/// reinstall rather than dead-end on a snackbar; every other failure is still a
/// plain snackbar.
///
/// The uninstall itself (PortalInstalledApps) is Android-only and no-ops off
/// device, so this pins the branch up to the offer, not the platform call.
class _FailingService extends PortalUpdateService {
  _FailingService(this._error)
      : super(
          manifestUrl: 'https://example.test/updates.json',
          appName: 'Portal Self',
        );

  final PortalUpdateException _error;

  @override
  Future<File> download(
    PortalRelease release, {
    void Function(double progress)? onProgress,
  }) async {
    onProgress?.call(1);
    return File('${Directory.systemTemp.path}/unused-${release.slug}.apk');
  }

  @override
  Future<void> install(File apk) async => throw _error;
}

PortalRelease _release() => PortalRelease(
      slug: 'portal-gym',
      versionCode: 10,
      versionName: '1.4.0',
      apkUrl: Uri.parse('https://example.test/portal-gym.apk'),
      sha256: 'a' * 64,
      sizeBytes: 0,
    );

Future<void> _pumpInstallButton(
  WidgetTester tester,
  PortalUpdateService service,
) async {
  await tester.pumpWidget(MaterialApp(
    theme: buildPortalTheme(brightness: Brightness.light),
    home: Scaffold(
      body: Builder(
        builder: (context) => Center(
          child: ElevatedButton(
            onPressed: () =>
                portalInstallAndReport(context, service, _release()),
            child: const Text('go'),
          ),
        ),
      ),
    ),
  ));
}

void main() {
  testWidgets('a signature conflict offers uninstall, not a snackbar',
      (tester) async {
    final service = _FailingService(
      const PortalUpdateException(
        'A conflicting copy of this app is already installed.',
        isSignatureConflict: true,
      ),
    );
    await _pumpInstallButton(tester, service);

    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();

    expect(find.text("Can't update Gym"), findsOneWidget);
    expect(find.text('Uninstall'), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);

    // Tapping through the offer dismisses cleanly (the uninstall no-ops off
    // Android).
    await tester.tap(find.text('Uninstall'));
    await tester.pumpAndSettle();
    expect(find.text("Can't update Gym"), findsNothing);
  });

  testWidgets('any other failure is still a plain snackbar', (tester) async {
    final service = _FailingService(
      const PortalUpdateException('Not enough storage to install the update.'),
    );
    await _pumpInstallButton(tester, service);

    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();

    expect(find.text('Not enough storage to install the update.'),
        findsOneWidget);
    expect(find.text("Can't update Gym"), findsNothing);
  });
}
