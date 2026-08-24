/// Shared sync contract documentation for Portal Task batch sync.
///
/// Server TypeScript DTOs in `server/portal_server/src/apps/task/modules/`
/// are the source of truth. Client parsers live in `portal_task/lib/data/remote/`.
library;

/// Standard batch push response shape for task, habit, and board sync.
abstract final class PortalSyncPushContract {
  static const appliedField = 'applied';
  static const rejectedField = 'rejected';
}

/// Standard batch pull response includes an ISO-8601 cursor watermark.
abstract final class PortalSyncPullContract {
  static const cursorField = 'cursor';
}
