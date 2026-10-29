import '../services/api_client.dart';
import '../session/session_controller.dart';

/// Fake backend seam (HUB.md phase 4): compile with
/// `--dart-define=PORTAL_FAKE=true` and [PortalBootstrap.init] registers
/// [FakeApi]/[FakeSession] in place of the real client and session, so an app
/// boots signed in with no prod server and no tokens — for the hub's Live tab,
/// for CI, and for offline demos.
///
/// ponytail: this fakes only the backend-readiness probe and the session; it
/// does NOT serve canned per-route data, so a screen that loads from the server
/// still shows its empty/error state. That is the known ceiling — add route
/// fixtures by overriding the relevant [ApiClient] methods on [FakeApi] when a
/// screen needs live-looking data.
const bool kPortalFake = bool.fromEnvironment('PORTAL_FAKE');

/// The demo user a PORTAL_FAKE build is signed in as.
const Map<String, dynamic> kPortalFakeUser = {
  'name': 'Portal Demo',
  'email': 'demo@portal.app',
};

/// An [ApiClient] that reports the backend ready without a network probe.
///
/// Also used by `apps/portal_design` to render the real shared screens with
/// fixture data, which is why it lives here rather than in a test.
class FakeApi extends ApiClient {
  FakeApi({this.up = true});
  final bool up;
  @override
  Future<BackendReadinessResult> checkBackendReadiness({
    Duration timeout = const Duration(seconds: 12),
    String? baseUrl,
  }) async => up
      ? const BackendReadinessResult(isReady: true)
      : const BackendReadinessResult(isReady: false, errorMessage: 'down');
}

/// A [SessionController] seeded with [user] (null = signed out) and no storage
/// I/O, so a scenario cannot leak a real stored session in or out.
class FakeSession extends SessionController {
  FakeSession(Map<String, dynamic>? user) {
    this.user.value = user;
  }
  @override
  Future<void> reloadFromStorage() async {}
}
