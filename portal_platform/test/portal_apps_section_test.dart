import 'package:flutter_test/flutter_test.dart';
import 'package:portal_platform/portal_platform.dart';

PortalRelease _release({int versionCode = 10, String versionName = '1.4.0'}) =>
    PortalRelease(
      slug: 'portal-gym',
      versionCode: versionCode,
      versionName: versionName,
      apkUrl: Uri.parse('https://example.test/gym.apk'),
      sha256: 'a' * 64,
      sizeBytes: 0,
    );

void main() {
  group('portalAppActionFor', () {
    test('offers Install when nothing is installed', () {
      expect(portalAppActionFor(_release(), null), PortalAppAction.install);
    });

    test('offers Update when the publish is ahead', () {
      const installed =
          PortalInstalledApp(versionCode: 9, versionName: '1.2.0');
      expect(portalAppActionFor(_release(), installed), PortalAppAction.update);
    });

    test('offers Open when level, and when the device is ahead', () {
      expect(
        portalAppActionFor(
          _release(),
          const PortalInstalledApp(versionCode: 10, versionName: '1.4.0'),
        ),
        PortalAppAction.open,
      );
      // A local build outruns the last publish; offering to "update" it would
      // install an older APK, which Android refuses.
      expect(
        portalAppActionFor(
          _release(),
          const PortalInstalledApp(versionCode: 11, versionName: '1.5.0'),
        ),
        PortalAppAction.open,
      );
    });
  });

  group('portalAppVersionLine', () {
    test('shows both versions only when an update is waiting', () {
      expect(
        portalAppVersionLine(
          _release(),
          const PortalInstalledApp(versionCode: 9, versionName: '1.2.0'),
        ),
        'v1.2.0 → v1.4.0',
      );
      expect(
        portalAppVersionLine(
          _release(),
          const PortalInstalledApp(versionCode: 10, versionName: '1.4.0'),
        ),
        'v1.4.0',
      );
      expect(portalAppVersionLine(_release(), null), 'v1.4.0');
    });

    test('falls back to the published version when a name is missing', () {
      expect(
        portalAppVersionLine(
          _release(),
          const PortalInstalledApp(versionCode: 9, versionName: ''),
        ),
        'v1.4.0',
      );
    });

    test('appends a known size', () {
      final sized = PortalRelease(
        slug: 'portal-gym',
        versionCode: 10,
        versionName: '1.4.0',
        apkUrl: Uri.parse('https://example.test/gym.apk'),
        sha256: 'a' * 64,
        sizeBytes: 12 * 1024 * 1024,
      );
      expect(portalAppVersionLine(sized, null), 'v1.4.0  ·  12.0 MB');
    });
  });

  group('packageNameFor', () {
    test('turns a slug into an applicationId', () {
      expect(
        PortalInstalledApps.packageNameFor('portal-gym'),
        'com.tanvoid0.portal_gym',
      );
    });

    // The launcher's Gradle applicationId has no separator, so the convention
    // derives a package that does not exist: every row reads "not installed",
    // which means Install on an installed app and an uninstall that no-ops.
    test('uses the override for the launcher', () {
      expect(
        PortalInstalledApps.packageNameFor('portal-launcher'),
        'com.tanvoid0.portallauncher',
      );
    });
  });
}
