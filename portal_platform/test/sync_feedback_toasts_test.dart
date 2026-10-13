import 'package:flutter_test/flutter_test.dart';
import 'package:portal_platform/portal_platform.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

void main() {
  test('queued toast is neutral and says the change is safe on this device', () {
    final t = syncQueuedToast();
    expect(t.variant, PortalToastVariant.neutral);
    expect(t.title, 'Saved on this device');
  });

  test('pushed toast is success and pluralises', () {
    expect(syncPushedToast(1).title, 'Synced 1 change');
    expect(syncPushedToast(3).title, 'Synced 3 changes');
    expect(syncPushedToast(3).variant, PortalToastVariant.success);
  });

  test('rejected toast is loud, names the entity and reads longer', () {
    final one = syncRejectedToast(1, 'recipe');
    expect(one.title, "1 recipe change couldn't be saved");
    expect(syncRejectedToast(2, 'recipes').title, "2 recipes changes couldn't be saved");
    expect(one.variant, PortalToastVariant.destructive);
    expect(one.duration, const Duration(seconds: 6));
  });

  test('evicted toast is loud, pluralises and carries the reason', () {
    final one = syncEvictedToast(1, 'the queue was full');
    expect(one.title, '1 unsynced change was discarded');
    expect(one.description, 'They were dropped because the queue was full.');
    expect(syncEvictedToast(4, 'x').title, '4 unsynced changes were discarded');
    expect(one.variant, PortalToastVariant.destructive);
    expect(one.duration, const Duration(seconds: 6));
  });
}
