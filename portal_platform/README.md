# portal_platform

Shared app infrastructure for the Portal fleet: auth, session, API client,
config, deep-link routing, in-app updates, observability (Sentry) and an
**offline-first sync layer** (local cache first, background sync, queued
mutations replayed on reconnect).

```dart
import 'package:portal_platform/portal_platform.dart';

final ok = await PortalBootstrap.init(sourceName: 'portal-gym');
runApp(GetMaterialApp(initialRoute: PortalBootstrap.startRoute, ...));
```

Modules: `auth/`, `session/`, `services/` (`ApiClient`), `config/`, `routing/`,
`sync/` (`SyncableRepository`), `storage/`, `update/`, `observability/`,
`settings/`, `media/`, `widgets/`.

Opinionated: built on GetX, expects a Portal-style REST server. Extracted from
the Portal apps rather than designed as a general framework — useful as a
reference or a starting point, less so as a drop-in.
