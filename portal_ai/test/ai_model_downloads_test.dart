import 'package:flutter_test/flutter_test.dart';
import 'package:portal_ai/portal_ai.dart';

void main() {
  group('aiDownloadFailurePhase', () {
    test('reads the cause out of the message', () {
      expect(
        aiDownloadFailurePhase('ENOSPC: no space left'),
        AiModelDownloadPhase.noSpace,
      );
      expect(
        aiDownloadFailurePhase('SocketException: Failed host lookup'),
        AiModelDownloadPhase.offline,
      );
      expect(
        aiDownloadFailurePhase('bad response'),
        AiModelDownloadPhase.failed,
      );
    });
  });

  group('aiDownloadEta', () {
    test('is null until there is a rate to read', () {
      expect(
        aiDownloadEta(fraction: 0.01, elapsed: const Duration(seconds: 30)),
        isNull,
      );
      expect(
        aiDownloadEta(fraction: 0.5, elapsed: const Duration(seconds: 2)),
        isNull,
      );
    });

    test('rounds up to 5 seconds, then to whole minutes', () {
      expect(
        aiDownloadEta(fraction: 0.5, elapsed: const Duration(seconds: 12)),
        const Duration(seconds: 15),
      );
      expect(
        aiDownloadEta(fraction: 0.25, elapsed: const Duration(seconds: 100)),
        const Duration(minutes: 5),
      );
      expect(aiDownloadEta(fraction: 1, elapsed: Duration.zero), Duration.zero);
    });
  });

  test('downloadedBytes clamps the fraction', () {
    expect(aiDownloadedBytes(1000, 0.5), 500);
    expect(aiDownloadedBytes(1000, 2), 1000);
  });
}
