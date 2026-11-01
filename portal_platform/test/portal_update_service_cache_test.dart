import 'dart:io';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:portal_platform/portal_platform.dart';

/// Counts how often the APK bytes are actually fetched, and serves the same
/// body every time, so a test can tell a cache hit from a re-download.
class _CountingClient extends http.BaseClient {
  _CountingClient(this.body);

  final List<int> body;
  int sends = 0;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    sends++;
    return http.StreamedResponse(
      Stream.value(body),
      200,
      contentLength: body.length,
    );
  }
}

/// [PortalUpdateService.download] reuses a prior download of the same version
/// rather than re-pulling the APK — a failed install or a second tap installs
/// straight away. A cached file is only trusted when its size and SHA-256 still
/// match, so a truncated or tampered one is discarded and fetched again.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('portal_update_cache_test');
    // download() writes into getTemporaryDirectory(); point it at a real dir.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (call) async => tempDir.path,
        );
  });

  tearDown(() => tempDir.deleteSync(recursive: true));

  Future<PortalRelease> releaseFor(List<int> bytes) async {
    final digest = await Sha256().hash(bytes);
    final hex =
        digest.bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return PortalRelease(
      slug: 'portal-gym',
      versionCode: 895,
      versionName: '1.27.0',
      apkUrl: Uri.parse('https://example.test/portal_gym.apk'),
      sha256: hex,
      sizeBytes: bytes.length,
    );
  }

  PortalUpdateService serviceWith(http.Client client) => PortalUpdateService(
        manifestUrl: 'https://example.test/updates.json',
        appName: 'Portal Gym',
        client: client,
      );

  test('reuses a verified cached APK instead of downloading again', () async {
    final bytes = List<int>.generate(4096, (i) => i % 256);
    final release = await releaseFor(bytes);
    final client = _CountingClient(bytes);
    final service = serviceWith(client);

    final first = await service.download(release);
    final second = await service.download(release);

    expect(client.sends, 1, reason: 'second download should hit the cache');
    expect(second.path, first.path);
    expect(await second.length(), bytes.length);
  });

  test('re-downloads when the cached file no longer verifies', () async {
    final bytes = List<int>.generate(4096, (i) => i % 256);
    final release = await releaseFor(bytes);
    final client = _CountingClient(bytes);
    final service = serviceWith(client);

    final file = await service.download(release);
    expect(client.sends, 1);

    // A half-finished or tampered file fails size + hash and must not be served.
    await file.writeAsBytes(const [0, 1, 2]);
    final refetched = await service.download(release);

    expect(client.sends, 2, reason: 'a bad cached file must be re-fetched');
    expect(await refetched.length(), bytes.length);
  });
}
