/// Shared auth, API client, session management, config, deep-link
/// routing, and **offline-first sync** for Portal apps.
///
/// ## Offline-first sync (Firebase-style)
///
/// The `sync` module provides a drop-in offline-first data layer.
/// Reads and writes always hit a local cache first, then sync with
/// the server in the background.  Failed mutations are queued and
/// replayed automatically when the device reconnects.
///
/// ### Quick start
///
/// **1. Define a repository** by extending [SyncableRepository]:
///
/// ```dart
/// class RecipeRepository extends SyncableRepository<Recipe> {
///   @override String get entityType  => 'recipe';
///   @override String get cacheKey    => 'portal_recipe_recipes';
///   @override String get apiBasePath => '$_baseUrl/recipes';
///   @override Recipe fromJson(Map<String, dynamic> j) => Recipe.fromJson(j);
///   @override Map<String, dynamic> toJson(Recipe r) => r.toJson();
///   @override String getId(Recipe r) => r.id;
/// }
/// ```
///
/// **2. Wire up services** in `main()` (order matters):
///
/// ```dart
/// // 1. Connectivity monitor
/// await Get.putAsync(() => ConnectivityService().init());
///
/// // 2. Persistent operation queue
/// await Get.putAsync(() => SyncQueue().init());
///
/// // 3. Sync manager — register repos, then init
/// final syncManager = SyncManager();
/// syncManager.register(RecipeRepository());
/// syncManager.register(CookbookRepository());
/// await Get.putAsync(() => syncManager.init());
/// ```
///
/// **3. Use the repository** — same CRUD interface, now offline-aware:
///
/// ```dart
/// final repo = RecipeRepository();
/// final recipes = await repo.getAll();   // cache or server
/// await repo.save(myRecipe);             // instant local + queued push
/// await repo.delete(id);                 // instant local + queued push
/// ```
///
/// ### Architecture overview
///
/// ```
/// ┌──────────────────────────────────────────────────────┐
/// │  ConnectivityService                                 │
/// │  Monitors network state, fires reconnect callbacks   │
/// └────────────────┬─────────────────────────────────────┘
///                  │ offline → online
///                  ▼
/// ┌──────────────────────────────────────────────────────┐
/// │  SyncManager                                         │
/// │  Iterates registered repos and calls sync()          │
/// └────────────────┬─────────────────────────────────────┘
///                  │ for each repo
///                  ▼
/// ┌──────────────────────────────────────────────────────┐
/// │  SyncableRepository<T>                               │
/// │  1. _pushPending()  →  replay queued ops to server   │
/// │  2. _pullFromServer() → GET all, merge into cache    │
/// └─────┬────────────────────────────┬───────────────────┘
///       │                            │
///       ▼                            ▼
/// ┌────────────┐            ┌───────────────┐
/// │ SyncQueue  │            │ SharedPrefs   │
/// │ (pending   │            │ (local cache) │
/// │  ops)      │            │               │
/// └────────────┘            └───────────────┘
/// ```
///
/// ### Key classes
///
/// | Class                  | Role                                          |
/// |------------------------|-----------------------------------------------|
/// | [ConnectivityService]  | Reactive `isOnline` flag + reconnect events   |
/// | [SyncQueue]            | Persistent, deduplicated mutation queue        |
/// | [SyncOperation]        | Data class for a single queued mutation        |
/// | [EntitySyncOutbox]     | Typed outbox wrapper over [SyncQueue]          |
/// | [SyncMutation]         | Interface for queued client mutations          |
/// | [SyncAfterWrite]       | Enqueue + optional online push helper          |
/// | [BaseEntitySyncService]| Shared sync observables for batch sync         |
/// | [SyncableRepository]   | **Experimental** — simple SharedPrefs CRUD only |
/// | [Syncable]             | Non-generic interface used by [SyncManager]   |
/// | [SyncManager]          | Orchestrates startup & reconnect sync          |
///
/// For rich local stores with batch `/sync` endpoints (Portal Task tasks,
/// habits, boards), use [EntitySyncOutbox] + [BaseEntitySyncService] instead
/// of [SyncableRepository].
library portal_platform;

// ─── Auth ──────────────────────────────────────────────────────────
export 'src/auth/local_user_auth.dart';
export 'src/auth/local_user_identity.dart';
export 'src/auth/portal_google_sign_in.dart';
export 'src/auth/portal_google_sign_in_registry.dart';
export 'src/auth/portal_auth_binding.dart';
export 'src/auth/portal_auth_config.dart';
export 'src/auth/portal_auth_controller.dart';
export 'src/auth/portal_auth_view.dart';
export 'src/auth/portal_password_reset_view.dart';
export 'src/auth/device_security/device_security_binding.dart';
export 'src/auth/device_security/device_security_controller.dart';
export 'src/auth/device_security/device_security_preferences.dart';
export 'src/auth/device_security/device_security_return_path.dart';
export 'src/auth/device_security/device_security_service.dart';
export 'src/auth/device_security/portal_device_security_gate.dart';
export 'src/auth/device_security/portal_device_security_lock_view.dart';
export 'src/auth/device_security/portal_device_security_settings_tile.dart';
export 'src/auth/device_security/portal_device_security_strings.dart';

// ─── Bootstrap & Config ────────────────────────────────────────────
export 'src/bootstrap/portal_bootstrap.dart';
export 'src/config/app_config.dart';
export 'src/config/data_storage_mode.dart';
export 'src/config/portal_server_prefs.dart';
export 'src/observability/portal_sentry.dart';
export 'src/observability/portal_logger.dart';
export 'src/observability/portal_log_severity.dart';
export 'src/observability/portal_error_handlers.dart';

// ─── Utilities ─────────────────────────────────────────────────────
export 'src/extensions/uri_extensions.dart';
export 'src/format/currency_format.dart';
export 'src/widgets/portal_app_version.dart';

// Sideload updates. Portal ships outside the Play Store while the apps are
// finished, so nothing tells an installed build that a newer one exists.
export 'src/update/portal_release.dart';
export 'src/update/portal_installed_apps.dart';
export 'src/update/portal_update_service.dart';
export 'src/update/portal_update_tile.dart';

// The settings page every app shares: profile, theme, backend status, the
// other Portal apps, and this app's own version.
export 'src/settings/portal_server_page.dart';
export 'src/settings/portal_change_password_page.dart';
export 'src/settings/portal_settings_page.dart';
export 'src/settings/portal_settings_labels.dart';
export 'src/settings/portal_status_tile.dart';
export 'src/settings/portal_apps_section.dart';
export 'src/settings/portal_account_menu_button.dart';
export 'src/settings/portal_avatar.dart';
export 'src/settings/portal_profile_tile.dart';
export 'src/settings/portal_theme_controller.dart';

// ─── Media ─────────────────────────────────────────────────────────
// The shared image picker: search the photo library or paste a link, in one
// sheet, behind one form field.
export 'src/media/portal_image_field.dart';
export 'src/media/portal_image_picker_sheet.dart';
export 'src/media/portal_image_search_service.dart';
export 'src/media/portal_media_service.dart';

// ─── Routing ───────────────────────────────────────────────────────
export 'portal_deep_link.dart';
export 'src/routing/deep_link_service.dart';
export 'src/routing/portal_navigation.dart';
export 'src/routing/portal_get_navigation.dart';
export 'src/routing/portal_auth_middleware.dart';

// ─── Services ──────────────────────────────────────────────────────
export 'portal_api_paths.dart';
export 'src/services/api_client.dart';
export 'src/services/portal_xp.dart';
export 'src/services/token_storage.dart';
export 'src/session/session_controller.dart';
export 'src/storage/portal_database.dart';
export 'src/storage/user_storage_scope.dart';

// ─── Sync (offline-first) ──────────────────────────────────────────
export 'src/sync/base_entity_sync_service.dart';
export 'src/sync/connectivity_service.dart';
export 'src/sync/entity_sync_outbox.dart';
export 'src/sync/sync_after_write.dart';
export 'src/sync/sync_feedback_install.dart';
export 'src/sync/sync_manager.dart';
export 'src/sync/sync_mutation.dart';
export 'src/sync/sync_operation.dart';
export 'src/sync/sync_queue.dart';
export 'src/sync/sync_status_banner.dart';
export 'src/sync/syncable_repository.dart';