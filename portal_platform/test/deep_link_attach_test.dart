import 'package:app_links/app_links.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portal_platform/portal_platform.dart';

/// An app that was not launched from a link: no initial URI, no later ones.
class _NoLinks implements AppLinks {
  @override
  Future<Uri?> getInitialLink() async => null;

  @override
  Stream<Uri> get uriLinkStream => const Stream<Uri>.empty();

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      super.noSuchMethod(invocation);
}

void main() {
  // attach() waits for GetMaterialApp to exist before navigating, and it waits
  // on endOfFrame -- which never completes unless something is driving frames.
  // Waiting unconditionally therefore hangs every caller that has nothing to
  // navigate to, which is the common case: one earlier draft of this took ten
  // minutes to time out instead of returning immediately.
  test('attach returns promptly when there is no launch link', () async {
    final service = DeepLinkService(appLinks: _NoLinks());
    addTearDown(service.onClose);

    await service.attach().timeout(
          const Duration(seconds: 5),
          onTimeout: () => fail('attach() waited for a navigator it never needed'),
        );
  });
}
