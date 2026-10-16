import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portal_platform/portal_platform.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    dotenv.loadFromString(envString: 'UNUSED=1');
  });

  group('ApiClient.startLocalOnlySession', () {
    test('isLoggedIn is true with no token saved', () async {
      final api = await ApiClient().init(baseUrl: 'https://cloud.example/api');

      expect(await api.isLoggedIn(), isFalse);
      await api.startLocalOnlySession({'id': 'device-1'});
      expect(await api.isLoggedIn(), isTrue);
    });

    test('getCurrentUser returns the synthesized map', () async {
      final api = await ApiClient().init(baseUrl: 'https://cloud.example/api');

      await api.startLocalOnlySession({'id': 'device-1', 'encrypted': true});

      final user = await api.getCurrentUser();
      expect(user?['id'], 'device-1');
      expect(user?['encrypted'], isTrue);
      expect(user?['local_only'], isTrue);
    });

    test('logout clears a local-only session the same as a real one',
        () async {
      final api = await ApiClient().init(baseUrl: 'https://cloud.example/api');

      await api.startLocalOnlySession({'id': 'device-1'});
      expect(await api.isLoggedIn(), isTrue);

      await api.logout();

      expect(await api.isLoggedIn(), isFalse);
      expect(await api.getCurrentUser(), isNull);
    });

    test('a real token still wins isLoggedIn without a local-only session',
        () async {
      final api = await ApiClient().init(baseUrl: 'https://cloud.example/api');
      await TokenStorage().saveTokens(accessToken: 'jwt', refreshToken: 'r');

      expect(await api.isLoggedIn(), isTrue);
    });

    test('an authenticated request short-circuits instead of signing the '
        'device out', () async {
      final api = await ApiClient().init(baseUrl: 'https://cloud.example/api');
      await api.startLocalOnlySession({'id': 'device-1'});

      await expectLater(
        api.get('/anything'),
        throwsA(
          isA<ApiException>()
              .having((e) => e.code, 'code', 'LOCAL_ONLY_SESSION')
              .having((e) => e.statusCode, 'statusCode', 401),
        ),
      );
      // The guard must not have run _failSessionExpired's side effect of
      // deleting the stored user — that's the bug this test pins.
      expect(await api.getCurrentUser(), isNotNull);
      expect(await api.isLoggedIn(), isTrue);
    });

    test('postStream — a separate request funnel — is guarded too',
        () async {
      final api = await ApiClient().init(baseUrl: 'https://cloud.example/api');
      await api.startLocalOnlySession({'id': 'device-1'});

      await expectLater(
        api.postStream('/anything').toList(),
        throwsA(
          isA<ApiException>().having((e) => e.code, 'code', 'LOCAL_ONLY_SESSION'),
        ),
      );
    });

    test('the guard survives a cold start — seeded from the cached user',
        () async {
      final first = await ApiClient().init(baseUrl: 'https://cloud.example/api');
      await first.startLocalOnlySession({'id': 'device-1'});

      final reloaded = await ApiClient().init(baseUrl: 'https://cloud.example/api');
      await expectLater(
        reloaded.get('/anything'),
        throwsA(isA<ApiException>().having((e) => e.code, 'code', 'LOCAL_ONLY_SESSION')),
      );
    });
  });
}
