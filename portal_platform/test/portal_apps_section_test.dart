import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portal_platform/portal_platform.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

PortalRelease _release({
  String slug = 'portal-gym',
  int versionCode = 10,
  String versionName = '1.4.0',
  String? notes,
}) =>
    PortalRelease(
      slug: slug,
      versionCode: versionCode,
      versionName: versionName,
      apkUrl: Uri.parse('https://example.test/$slug.apk'),
      sha256: 'a' * 64,
      sizeBytes: 0,
      notes: notes,
    );

/// A service whose manifest the test hands over, and counts the asks.
class _FakeUpdates extends PortalUpdateService {
  _FakeUpdates(this.manifest)
      : super(
          manifestUrl: 'https://example.test/updates.json',
          appName: 'Portal Self',
        );

  Future<PortalUpdateManifest> Function() manifest;
  int loads = 0;

  @override
  Future<PortalUpdateManifest> fetchManifest() {
    loads++;
    return manifest();
  }
}

PortalUpdateManifest _manifestOf(List<PortalRelease> releases) =>
    PortalUpdateManifest({for (final r in releases) r.slug: r});

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

  group('PortalAppsSection.grouped', () {
    // A skeleton shimmers for as long as it is on screen, so a test that wants
    // to look at one cannot settle.
    Future<void> pump(
      WidgetTester tester,
      _FakeUpdates service, {
      bool settle = true,
    }) async {
      await tester.pumpWidget(MaterialApp(
        theme: buildPortalTheme(brightness: Brightness.light),
        home: Scaffold(
          body: SingleChildScrollView(
            child: PortalAppsSection.grouped(service: service),
          ),
        ),
      ));
      if (settle) {
        await tester.pumpAndSettle();
      } else {
        await tester.pump();
      }
    }

    testWidgets('loading is a header over two skeleton rows', (tester) async {
      final pending = Completer<PortalUpdateManifest>();
      await pump(tester, _FakeUpdates(() => pending.future), settle: false);

      expect(find.text('Portal apps'), findsOneWidget);
      expect(find.byType(PortalListItem), findsNWidgets(2));
      expect(find.text('Check again'), findsNothing);
    });

    testWidgets('an error is a prompt whose Retry loads again',
        (tester) async {
      var fail = true;
      final service = _FakeUpdates(() async {
        if (fail) throw const PortalUpdateException('Update server returned 500.');
        return _manifestOf([_release()]);
      });
      await pump(tester, service);

      expect(find.text('Portal apps'), findsOneWidget);
      expect(find.text('Update server returned 500.'), findsOneWidget);
      expect(find.byType(PortalListItem), findsNothing);

      fail = false;
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(service.loads, 2);
      expect(find.text('Update server returned 500.'), findsNothing);
      expect(find.text('Gym'), findsOneWidget);
    });

    testWidgets('nothing published is nothing on the page', (tester) async {
      await pump(tester, _FakeUpdates(() async => _manifestOf([])));

      expect(find.text('Portal apps'), findsNothing);
      expect(find.byType(PortalListItem), findsNothing);
    });

    testWidgets('rows carry their one action, named for the app',
        (tester) async {
      await pump(
        tester,
        _FakeUpdates(() async => _manifestOf([
              _release(),
              _release(slug: 'portal-recipe', versionName: '2.0.0'),
            ])),
      );

      expect(find.text('Gym'), findsOneWidget);
      expect(find.text('Recipe'), findsOneWidget);
      expect(find.text('v1.4.0'), findsOneWidget);
      expect(find.byTooltip('Install Gym'), findsOneWidget);
      expect(find.byTooltip('Install Recipe'), findsOneWidget);
      expect(find.text('Check again'), findsOneWidget);
      // One button per row; Uninstall is a long press, not a second control.
      expect(find.byTooltip('More for Gym'), findsNothing);
    });

    testWidgets('the download meter fills and shows its percentage',
        (tester) async {
      final progress = ValueNotifier<double>(-1);
      final status = ValueNotifier<String>('Downloading 1/2 — Gym');
      late BuildContext context;
      await tester.pumpWidget(MaterialApp(
        theme: buildPortalTheme(brightness: Brightness.light),
        home: Builder(builder: (c) {
          context = c;
          return const Scaffold();
        }),
      ));
      portalShowDownloadSheet(
        context,
        title: 'Install all',
        progress: progress,
        status: status,
      );
      // Indeterminate until the size is known, which never settles.
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Downloading 1/2 — Gym'), findsOneWidget);
      expect(find.textContaining('%'), findsNothing);

      progress.value = .4;
      await tester.pump();

      expect(find.text('40%'), findsOneWidget);
    });

    testWidgets('Install all appears from two waiting apps', (tester) async {
      await pump(
        tester,
        _FakeUpdates(() async => _manifestOf([
              _release(),
              _release(slug: 'portal-recipe'),
            ])),
      );

      expect(find.text('Install all (2)'), findsOneWidget);
    });

    testWidgets('and not for one, which is the row\'s own button',
        (tester) async {
      await pump(tester, _FakeUpdates(() async => _manifestOf([_release()])));

      expect(find.text('Gym'), findsOneWidget);
      expect(find.textContaining('Install all'), findsNothing);
    });

    testWidgets('Install asks in a sheet first, and Later leaves it be',
        (tester) async {
      final service = _FakeUpdates(() async => _manifestOf([
            _release(notes: 'Faster sync\n- Fixed a crash'),
          ]));
      await pump(tester, service);

      await tester.tap(find.byTooltip('Install Gym'));
      await tester.pumpAndSettle();

      expect(find.text("What's new"), findsOneWidget);
      expect(find.text('Faster sync'), findsOneWidget);
      // A list marker the publisher typed is dropped for ours.
      expect(find.text('Fixed a crash'), findsOneWidget);

      await tester.tap(find.text('Later'));
      await tester.pumpAndSettle();

      expect(find.text("What's new"), findsNothing);
    });
  });
}
