import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portal_platform/portal_platform.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
  });

  group('PortalServerPrefs.localUrlFrom', () {
    test('accepts a private host:port and normalises it', () {
      expect(
        PortalServerPrefs.localUrlFrom('10.0.2.2:3001'),
        'http://10.0.2.2:3001/api',
      );
    });

    test('rejects a public host', () {
      expect(PortalServerPrefs.localUrlFrom('8.8.8.8:80'), isNull);
      expect(PortalServerPrefs.localUrlFrom('example.com'), isNull);
    });

    test('accepts localhost', () {
      expect(
        PortalServerPrefs.localUrlFrom('localhost:3001'),
        'http://localhost:3001/api',
      );
    });
  });

  group('ApiClient server override', () {
    test('init honours a stored override', () async {
      await PortalServerPrefs.write('http://10.0.2.2:3001/api');

      final api = await ApiClient().init(baseUrl: 'https://cloud.example/api');

      expect(api.baseUrl, 'http://10.0.2.2:3001/api');
      expect(api.defaultBaseUrl, 'https://cloud.example/api');
      expect(api.isOverridden, isTrue);
    });

    test('switchServer(null) restores the default and clears the pref',
        () async {
      final api = await ApiClient().init(baseUrl: 'https://cloud.example/api');
      await api.switchServer('http://192.168.1.5:3001/api');
      expect(api.isOverridden, isTrue);

      await api.switchServer(null);

      expect(api.baseUrl, 'https://cloud.example/api');
      expect(api.isOverridden, isFalse);
      expect(await PortalServerPrefs.read(), isNull);
    });
  });
}
