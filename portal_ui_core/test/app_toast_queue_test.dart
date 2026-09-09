import 'package:flutter_test/flutter_test.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

/// [AppToast.present] used to replace whatever was on screen, so two messages
/// raised in the same moment left only the last one — a sync result could
/// erase the error that explained it.
void main() {
  setUp(AppToast.clear);
  tearDown(AppToast.clear);

  test('a second toast waits instead of replacing the first', () {
    AppToast.error('First');
    AppToast.success('Second');

    expect(AppToast.current.value?.title, 'First');

    AppToast.dismiss();
    expect(AppToast.current.value?.title, 'Second');

    AppToast.dismiss();
    expect(AppToast.current.value, isNull);
  });

  test('order is preserved across a backlog', () {
    AppToast.show('A');
    AppToast.show('B');
    AppToast.show('C');

    final seen = <String>[];
    for (var i = 0; i < 3; i++) {
      seen.add(AppToast.current.value!.title);
      AppToast.dismiss();
    }
    expect(seen, ['A', 'B', 'C']);
  });

  /// Several repositories failing the same way in one sync cycle is the
  /// common case, and it should read as one problem.
  test('an identical message is not queued twice', () {
    AppToast.error('Offline', description: 'No connection to the server.');
    AppToast.error('Offline', description: 'No connection to the server.');
    AppToast.error('Offline', description: 'No connection to the server.');

    AppToast.dismiss();
    expect(AppToast.current.value, isNull);
  });

  test('the same title with a different variant is a different message', () {
    AppToast.show('Sync');
    AppToast.error('Sync');

    AppToast.dismiss();
    expect(AppToast.current.value?.variant, PortalToastVariant.destructive);
  });

  test('a runaway burst is capped, keeping the most recent', () {
    AppToast.show('showing');
    for (var i = 0; i < 10; i++) {
      AppToast.show('queued $i');
    }

    AppToast.dismiss();
    final seen = <String>[];
    while (AppToast.current.value != null) {
      seen.add(AppToast.current.value!.title);
      AppToast.dismiss();
    }
    expect(seen.length, AppToast.maxPending);
    expect(seen.last, 'queued 9');
  });

  test('clear drops the backlog as well as the current toast', () {
    AppToast.show('A');
    AppToast.show('B');

    AppToast.clear();
    expect(AppToast.current.value, isNull);
  });
}
