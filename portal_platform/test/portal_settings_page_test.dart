import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:portal_platform/portal_platform.dart';
import 'package:portal_ui_core/portal_ui_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// An [ApiClient] whose readiness probe the test answers.
class _FakeApi extends ApiClient {
  // Lazy, so it is made in the test's own zone, where its pumps can flush it.
  late final Completer<BackendReadinessResult> readiness = Completer();

  @override
  Future<BackendReadinessResult> checkBackendReadiness({
    Duration timeout = const Duration(seconds: 12),
    String? baseUrl,
  }) => readiness.future;
}

/// A signed-in (or out) session that records what the page asked of it.
class _FakeSession extends SessionController {
  _FakeSession(Map<String, dynamic>? signedInAs) {
    user.value = signedInAs;
  }

  final calls = <String>[];
  bool failName = false;
  bool failDelete = false;

  @override
  Future<void> reloadFromStorage() async {}

  @override
  Future<void> updateName(String name) async {
    calls.add('name:$name');
    if (failName) throw Exception('offline');
  }

  @override
  Future<void> signOut() async => calls.add('signOut');

  @override
  Future<void> deleteAccount() async {
    calls.add('delete');
    if (failDelete) throw Exception('offline');
  }
}

/// The page is a grouped list of rows over already-tested services: which
/// groups it builds, in what order, and what each row hands to the service
/// behind it are the parts worth pinning.
void main() {
  late _FakeApi api;

  setUp(() async {
    Get.reset();
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    PackageInfo.setMockInitialValues(
      appName: 'Portal Gym',
      packageName: 'uk.aipairs.portal.gym',
      version: '1.3.0',
      buildNumber: '412',
      buildSignature: '',
    );
    // PortalAppVersion caches its first read for the whole run. Make that
    // read here, outside any test's fake-async zone, so a test that ends
    // before it resolves cannot leave every later one reading '…'.
    await PortalAppVersion.load();
    api = _FakeApi();
    await api.init(baseUrl: 'https://cloud.example/api');
  });

  // Tall enough that the ListView builds every group, so positions compare.
  Future<void> pump(WidgetTester tester, Widget page) async {
    tester.view.physicalSize = const Size(800, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      GetMaterialApp(
        theme: buildPortalTheme(brightness: Brightness.light),
        home: page,
      ),
    );
    await tester.pump();
  }

  double top(WidgetTester tester, String text) =>
      tester.getTopLeft(find.text(text)).dy;

  _FakeSession signedIn({String name = 'Ada Lovelace'}) {
    Get.put<ApiClient>(api);
    return Get.put<SessionController>(
          _FakeSession({'name': name, 'email': 'ada@example.com'}),
        )
        as _FakeSession;
  }

  group('what it builds', () {
    testWidgets('only the groups it was given, headers as written', (
      tester,
    ) async {
      await pump(
        tester,
        const PortalSettingsPage(
          include: [PortalSettingsGroup.custom],
          sections: [
            PortalSettingsSection(title: 'Only me', children: [Text('row')]),
          ],
        ),
      );

      expect(find.text('ONLY ME'), findsNothing);
      expect(find.text('Only me'), findsOneWidget);
      // Status is in the default order but not in `include`.
      expect(find.text('Status'), findsNothing);
      expect(find.text('Account'), findsNothing);
    });

    testWidgets('custom first, then one coalesced nav card for the rest', (
      tester,
    ) async {
      await pump(
        tester,
        PortalSettingsPage(
          themeController: Get.put(PortalThemeController()),
          assistantSection: const Text('provider list'),
          sections: const [
            PortalSettingsSection(title: 'Mine', children: [Text('row')]),
          ],
        ),
      );

      // The assistant's content is behind the Assistant row now, not inline.
      expect(find.text('provider list'), findsNothing);

      final order = [
        top(tester, 'Mine'),
        top(tester, 'Appearance'),
        top(tester, 'Assistant'),
        top(tester, 'About'),
      ];
      expect(order, [...order]..sort());
    });

    testWidgets(
      'rows are nested: Theme and Mode live behind Appearance and About',
      (tester) async {
        final theme = Get.put(PortalThemeController());
        await pump(
          tester,
          PortalSettingsPage(
            themeController: theme,
            include: const [
              PortalSettingsGroup.appearance,
              PortalSettingsGroup.status,
            ],
          ),
        );

        expect(find.text('Theme'), findsNothing);
        expect(find.text('Mode'), findsNothing);

        await tester.tap(find.text('Appearance'));
        await tester.pumpAndSettle();

        expect(find.text('Theme'), findsOneWidget);
        expect(find.byType(BackButton), findsOneWidget);
      },
    );

    testWidgets('respects order, and skips what include leaves out', (
      tester,
    ) async {
      await pump(
        tester,
        PortalSettingsPage(
          include: const [
            PortalSettingsGroup.custom,
            PortalSettingsGroup.status,
          ],
          order: const [PortalSettingsGroup.status, PortalSettingsGroup.custom],
          sections: const [
            PortalSettingsSection(title: 'Mine', children: [Text('row')]),
          ],
          sectionBuilder: (title, children) =>
              Column(children: [Text('<$title>'), ...children]),
        ),
      );

      expect(top(tester, 'About'), lessThan(top(tester, '<Mine>')));
    });

    testWidgets('sectionBuilder replaces the default chrome', (tester) async {
      await pump(
        tester,
        PortalSettingsPage(
          include: const [PortalSettingsGroup.custom],
          sections: const [
            PortalSettingsSection(title: 'Accounts', children: [Text('row')]),
          ],
          sectionBuilder: (title, children) =>
              Column(children: [Text('~$title~'), ...children]),
        ),
      );

      expect(find.text('~Accounts~'), findsOneWidget);
      expect(find.text('Accounts'), findsNothing);
    });

    testWidgets('labels drive every heading it renders', (tester) async {
      await pump(
        tester,
        PortalSettingsPage(
          labels: const PortalSettingsLabels(
            title: 'Réglages',
            about: 'À propos',
            appearance: 'Apparence',
          ),
          themeController: Get.put(PortalThemeController()),
          include: const [
            PortalSettingsGroup.appearance,
            PortalSettingsGroup.status,
          ],
        ),
      );

      expect(find.text('Réglages'), findsOneWidget);
      expect(find.text('À propos'), findsOneWidget);
      expect(find.text('Apparence'), findsOneWidget);
    });

    testWidgets('appearance is absent without a theme controller', (
      tester,
    ) async {
      await pump(
        tester,
        const PortalSettingsPage(include: [PortalSettingsGroup.appearance]),
      );

      expect(find.text('Appearance'), findsNothing);
    });

    testWidgets('a slotted section renders right after its named group', (
      tester,
    ) async {
      await pump(
        tester,
        PortalSettingsPage(
          themeController: Get.put(PortalThemeController()),
          sections: const [
            PortalSettingsSection(
              title: 'Mine',
              children: [Text('row')],
              slot: PortalSettingsGroup.appearance,
            ),
          ],
        ),
      );

      final order = [
        top(tester, 'Appearance'),
        top(tester, 'Mine'),
        top(tester, 'About'),
      ];
      expect(order, [...order]..sort());
    });

    testWidgets('header given: no Scaffold/app bar, header is first', (
      tester,
    ) async {
      await pump(
        tester,
        const PortalSettingsPage(
          include: [PortalSettingsGroup.custom],
          header: Text('My header'),
          sections: [
            PortalSettingsSection(title: 'Only me', children: [Text('row')]),
          ],
        ),
      );

      expect(find.byType(PortalAppBar), findsNothing);
      expect(find.byType(Scaffold), findsNothing);
      expect(find.text('My header'), findsOneWidget);
      expect(top(tester, 'My header'), lessThan(top(tester, 'Only me')));
    });

    testWidgets('include: [status] hides Appearance and Assistant', (
      tester,
    ) async {
      await pump(
        tester,
        PortalSettingsPage(
          themeController: Get.put(PortalThemeController()),
          assistantSection: const Text('provider list'),
          include: const [PortalSettingsGroup.status],
        ),
      );

      expect(find.text('About'), findsOneWidget);
      expect(find.text('Appearance'), findsNothing);
      expect(find.text('Assistant'), findsNothing);
    });
  });

  group('assistant', () {
    testWidgets('assistantSection is behind an Assistant row, pushed on tap', (
      tester,
    ) async {
      await pump(
        tester,
        const PortalSettingsPage(
          include: [PortalSettingsGroup.assistant],
          assistantSection: Text('provider list'),
        ),
      );

      expect(find.text('provider list'), findsNothing);
      expect(find.text('Assistant'), findsOneWidget);

      await tester.tap(find.text('Assistant'));
      await tester.pumpAndSettle();

      expect(find.text('provider list'), findsOneWidget);
      expect(find.byType(BackButton), findsOneWidget);
    });

    testWidgets('legacy aiSection is one row that opens its own page', (
      tester,
    ) async {
      await pump(
        tester,
        const PortalSettingsPage(
          include: [PortalSettingsGroup.assistant],
          // ignore: deprecated_member_use_from_same_package
          aiSection: Text('provider list'),
        ),
      );

      expect(find.text('provider list'), findsNothing);
      expect(find.text('Assistant'), findsOneWidget);

      await tester.tap(find.text('Assistant'));
      await tester.pumpAndSettle();

      expect(find.text('provider list'), findsOneWidget);
      expect(find.byType(BackButton), findsOneWidget);

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.text('provider list'), findsNothing);
    });
  });

  group('status', () {
    const status = [PortalSettingsGroup.status];

    testWidgets('Mode follows the probe, and the bar says when Cloud is down', (
      tester,
    ) async {
      Get.put<ApiClient>(api);
      await pump(tester, const PortalSettingsPage(include: status));

      expect(find.text('Portal Cloud unreachable'), findsNothing);

      api.readiness.complete(const BackendReadinessResult(isReady: false));
      await tester.pumpAndSettle();

      // The bar's own status line and the About row's subtitle both say so.
      expect(find.text('Portal Cloud unreachable'), findsNWidgets(2));

      await tester.tap(find.text('About'));
      await tester.pumpAndSettle();

      expect(find.text('Mode'), findsOneWidget);
      expect(find.text('On-device'), findsOneWidget);
    });

    testWidgets('Mode says Portal Cloud when it answers', (tester) async {
      Get.put<ApiClient>(api);
      await pump(tester, const PortalSettingsPage(include: status));

      api.readiness.complete(const BackendReadinessResult(isReady: true));
      await tester.pumpAndSettle();
      expect(find.text('Portal Cloud unreachable'), findsNothing);

      await tester.tap(find.text('About'));
      await tester.pumpAndSettle();

      expect(find.text('Portal Cloud'), findsOneWidget);
    });

    testWidgets('no client, no Mode row; the version still reads', (
      tester,
    ) async {
      await pump(tester, const PortalSettingsPage(include: status));
      // The version future was resolved in the real zone (see setUp); let its
      // callback run there before settling.
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pumpAndSettle();

      // The row's own trailing value already reads it before the push.
      expect(find.text('1.3.0 (412)'), findsOneWidget);

      await tester.tap(find.text('About'));
      await tester.pumpAndSettle();

      expect(find.text('Mode'), findsNothing);
      expect(find.text('App version'), findsOneWidget);
      expect(find.text('1.3.0 (412)'), findsOneWidget);
    });

    testWidgets('a tap on App version opens the server page in debug', (
      tester,
    ) async {
      Get.put<ApiClient>(api);
      await pump(tester, const PortalSettingsPage(include: status));

      await tester.tap(find.text('About'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('App version'));
      await tester.pumpAndSettle();

      expect(find.byType(PortalServerPage), findsOneWidget);
    });

    testWidgets('Check for updates only with an update service', (
      tester,
    ) async {
      await pump(tester, const PortalSettingsPage(include: status));
      await tester.tap(find.text('About'));
      await tester.pumpAndSettle();
      expect(find.text('Check for updates'), findsNothing);

      Get.put(
        PortalUpdateService(
          manifestUrl: 'https://example.test/updates.json',
          appName: 'Portal Gym',
        ),
      );
      await pump(tester, const PortalSettingsPage(include: status));
      await tester.tap(find.text('About'));
      await tester.pumpAndSettle();
      expect(find.text('Check for updates'), findsOneWidget);
    });
  });

  group('appearance', () {
    testWidgets('Theme opens a sheet that applies on tap', (tester) async {
      final theme = Get.put(PortalThemeController());
      await pump(
        tester,
        PortalSettingsPage(
          themeController: theme,
          include: const [PortalSettingsGroup.appearance],
        ),
      );

      await tester.tap(find.text('Appearance'));
      await tester.pumpAndSettle();

      // No palettes, no accent row.
      expect(find.text('Accent colour'), findsNothing);
      await tester.tap(find.text('Theme'));
      await tester.pumpAndSettle();
      expect(find.text('Light'), findsOneWidget);

      await tester.tap(find.text('Dark'));
      await tester.pumpAndSettle();

      expect(theme.themeMode.value, ThemeMode.dark);
      expect(find.text('Light'), findsNothing);
    });

    testWidgets('Accent colour picks a palette and checks it', (tester) async {
      final theme = Get.put(PortalThemeController());
      await pump(
        tester,
        PortalSettingsPage(
          themeController: theme,
          include: const [PortalSettingsGroup.appearance],
          palettes: const [
            PortalPaletteOption(
              id: 'ocean',
              label: 'Ocean',
              swatch: Colors.blue,
            ),
            PortalPaletteOption(
              id: 'ember',
              label: 'Ember',
              swatch: Colors.red,
            ),
          ],
        ),
      );

      await tester.tap(find.text('Appearance'));
      await tester.pumpAndSettle();

      // The row draws the swatch, not the name; the name is in the sheet.
      expect(find.text('Ocean'), findsNothing);
      await tester.tap(find.text('Accent colour'));
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('Ocean'), findsOneWidget);
      // Nothing chosen yet: the first palette is the app's own accent, and
      // it is the one carrying the check.
      expect(find.byIcon(PortalIcons.check_rounded), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('Ember'));
      await tester.pumpAndSettle();

      expect(theme.paletteId.value, 'ember');
      expect(find.bySemanticsLabel('Ember'), findsNothing);
    });
  });

  group('profile', () {
    testWidgets('shows the person, and renames through the sheet', (
      tester,
    ) async {
      final session = signedIn();
      await pump(
        tester,
        const PortalSettingsPage(include: [PortalSettingsGroup.profile]),
      );

      expect(find.text('Ada Lovelace'), findsOneWidget);
      expect(find.text('ada@example.com'), findsOneWidget);
      expect(find.text('AL'), findsOneWidget);

      await tester.tap(find.text('Ada Lovelace'));
      await tester.pumpAndSettle();
      expect(find.text('Edit name'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'Ada Byron');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(session.calls, ['name:Ada Byron']);
      expect(find.text('Edit name'), findsNothing);
    });

    testWidgets('a failed rename stays open and offers a retry', (
      tester,
    ) async {
      final session = signedIn()..failName = true;
      await pump(
        tester,
        const PortalSettingsPage(include: [PortalSettingsGroup.profile]),
      );

      await tester.tap(find.text('Ada Lovelace'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Ada Byron');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('Could not save your name.'), findsOneWidget);
      expect(find.text('Edit name'), findsOneWidget);

      session.failName = false;
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(session.calls, ['name:Ada Byron', 'name:Ada Byron']);
      expect(find.text('Edit name'), findsNothing);
    });

    testWidgets('signed out: a Sign in row only when the app gave one', (
      tester,
    ) async {
      Get.put<ApiClient>(api);
      Get.put<SessionController>(_FakeSession(null));
      await pump(
        tester,
        const PortalSettingsPage(include: [PortalSettingsGroup.profile]),
      );
      expect(find.text('Sign in'), findsNothing);

      var signIns = 0;
      await pump(
        tester,
        PortalSettingsPage(
          include: const [PortalSettingsGroup.profile],
          onSignIn: () => signIns++,
        ),
      );
      await tester.tap(find.text('Sign in'));
      expect(signIns, 1);
    });
  });

  group('account', () {
    const about = [PortalSettingsGroup.about];

    testWidgets('absent while signed out', (tester) async {
      Get.put<ApiClient>(api);
      Get.put<SessionController>(_FakeSession(null));
      await pump(tester, const PortalSettingsPage(include: about));

      expect(find.text('Account'), findsNothing);
      expect(find.text('Sign out'), findsNothing);
    });

    testWidgets('sign out asks first', (tester) async {
      final session = signedIn();
      await pump(tester, const PortalSettingsPage(include: about));

      await tester.tap(find.text('Account'));
      await tester.pumpAndSettle();

      expect(find.text('Change password'), findsOneWidget);
      await tester.tap(find.text('Sign out'));
      await tester.pumpAndSettle();
      expect(session.calls, isEmpty);

      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Sign out'),
        ),
      );
      await tester.pumpAndSettle();
      expect(session.calls, ['signOut']);
    });

    testWidgets('a failed delete says so above the rows, and retries', (
      tester,
    ) async {
      final session = signedIn()..failDelete = true;
      await pump(tester, const PortalSettingsPage(include: about));

      await tester.tap(find.text('Account'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Delete account'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Delete account'),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Could not delete your account.'),
        findsOneWidget,
      );
      expect(
        tester
            .getTopLeft(find.textContaining('Could not delete your account.'))
            .dy,
        lessThan(top(tester, 'Change password')),
      );

      session.failDelete = false;
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(session.calls, ['delete', 'delete']);
      expect(find.textContaining('Could not delete'), findsNothing);
    });
  });
}
