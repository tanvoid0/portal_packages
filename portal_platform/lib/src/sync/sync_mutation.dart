import 'package:portal_platform/portal_platform.dart';

/// A client-side change queued for [SyncQueue] push.
abstract interface class SyncMutation {
  String get id;

  SyncOperation toSyncOperation();
}
