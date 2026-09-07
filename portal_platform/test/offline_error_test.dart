import 'package:flutter_test/flutter_test.dart';
import 'package:portal_platform/portal_platform.dart';

/// Guards the "no network" path. Before this, a transport failure escaped
/// [ApiClient] as a raw `SocketException` and every caller either printed its
/// `toString()` or swallowed it — which is why an offline session looked like
/// an app that did nothing.
void main() {
  group('offline classification', () {
    test('a network failure is offline and never a real HTTP status', () {
      final e = ApiException.networkFailure();
      expect(e.isOffline, isTrue);
      expect(e.statusCode, 0);
      expect(e.code, ApiException.offlineCode);
    });

    test('real HTTP failures are not offline', () {
      expect(ApiException('bad', 400).isOffline, isFalse);
      expect(ApiException('boom', 500).isOffline, isFalse);
    });

    /// portal_shopping's `isPermanentFailure` treats 4xx as "the server said
    /// no, do not queue this". Offline must fall outside that window or every
    /// write made with no network would be dropped instead of replayed.
    test('offline sits outside the 4xx permanent-failure window', () {
      final code = ApiException.networkFailure().statusCode;
      expect(code >= 400 && code < 500, isFalse);
    });
  });

  group('isPermanentSyncFailure', () {
    test('a refused mutation is permanent, so it gets dropped not replayed',
        () {
      expect(isPermanentSyncFailure(ApiException('bad field', 400)), isTrue);
      expect(isPermanentSyncFailure(ApiException('gone', 404)), isTrue);
      expect(isPermanentSyncFailure(ApiException('unprocessable', 422)),
          isTrue);
    });

    /// Dropping one of these would throw away a good local change: they all
    /// clear on their own or after a re-auth.
    test('transient failures stay queued', () {
      expect(isPermanentSyncFailure(ApiException.networkFailure()), isFalse);
      expect(isPermanentSyncFailure(ApiException('expired', 401)), isFalse);
      expect(isPermanentSyncFailure(ApiException('forbidden', 403)), isFalse);
      expect(isPermanentSyncFailure(ApiException('timeout', 408)), isFalse);
      expect(isPermanentSyncFailure(ApiException('slow down', 429)), isFalse);
      expect(isPermanentSyncFailure(ApiException('boom', 500)), isFalse);
      expect(isPermanentSyncFailure(ApiException('gateway', 503)), isFalse);
    });

    test('a non-API error is never treated as a server refusal', () {
      expect(isPermanentSyncFailure(StateError('boom')), isFalse);
    });
  });

  group('portalErrorMessage', () {
    test('offline copy says what happened, and takes a caller hint', () {
      final offline = ApiException.networkFailure();
      expect(portalErrorMessage(offline), "You're offline.");
      expect(
        portalErrorMessage(offline, offlineHint: 'Sharing needs a connection.'),
        "You're offline. Sharing needs a connection.",
      );
    });

    test('maps the statuses a user can act on', () {
      expect(portalErrorMessage(ApiException('x', 401)), contains('session'));
      expect(portalErrorMessage(ApiException('x', 404)), contains('no longer'));
      expect(portalErrorMessage(ApiException('x', 429)), contains('Too many'));
      expect(portalErrorMessage(ApiException('x', 503)), contains('server'));
    });

    test('never leaks an exception toString to the user', () {
      for (final e in <Object>[
        ApiException.networkFailure(),
        ApiException('x', 500),
        const FormatException('unexpected token'),
        StateError('boom'),
      ]) {
        expect(portalErrorMessage(e), isNot(contains('Exception')));
        expect(portalErrorMessage(e), isNot(contains('Error')));
      }
    });

    test('a 4xx the map has no copy for still shows the server message', () {
      expect(portalErrorMessage(ApiException('Name is required', 400)),
          'Name is required');
    });
  });
}
