/// URL strategy: on web use path-based routes (`/inbox`); elsewhere no-op.
import 'portal_url_strategy_stub.dart'
    if (dart.library.html) 'portal_url_strategy_web.dart' as _impl;

/// Call once, before `runApp`, so a GetX path like `/gym/settings` shows in
/// the browser bar as-is instead of `/#/gym/settings`.
void usePortalUrlStrategy() => _impl.usePortalUrlStrategy();
