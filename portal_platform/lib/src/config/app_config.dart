import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'data_storage_mode.dart';
import 'env_parsing.dart';

part 'app_config.freezed.dart';

/// Immutable app configuration. Single source of truth for bootstrap and env-derived settings.
/// Use [AppConfig.fromEnv] after [dotenv.load()] to build from .env; use [copyWith] for overrides (e.g. tests).
@freezed
class AppConfig with _$AppConfig {
  const factory AppConfig({
    required String apiBaseUrl,
    @Default('Portal Warp') String appTitle,
    @Default(ThemeMode.system) ThemeMode themeMode,
    @Default(false) bool debugShowCheckedModeBanner,
    @Default('/') String routeLoggedIn,
    @Default('/login') String routeLoggedOut,
    @Default('') String demoEmail,
    @Default('') String demoPassword,
    /// Web OAuth client ID for Google Sign-In on the auth screen.
    @Default('') String googleSignInServerClientId,

    /// Where entity lists are stored (mutually exclusive). Default: server.
    @Default(DataStorageMode.server) DataStorageMode dataStorage,

    /// When true, entity payloads are encrypted with the vault DEK at rest.
    @Default(true) bool dataEncrypted,

    /// Deprecated: use [dataStorage] == server and [dataEncrypted] == true.
    @Deprecated('Use dataStorage and dataEncrypted')
    @Default(false)
    bool disableOfflineSync,
  }) = _AppConfig;

  const AppConfig._();

  /// Auto-register a device-local user when no cloud session exists.
  bool get autoLocalAuth => dataStorage == DataStorageMode.local;

  /// True when entity data is not kept in local GetStorage (server or Drive).
  bool get usesRemoteEntityStorage =>
      dataStorage == DataStorageMode.server ||
      dataStorage == DataStorageMode.googleDrive;

  /// Build config from current dotenv. Call after [dotenv.load()].
  /// Throws if [API_BASE_URL] is missing or empty.
  factory AppConfig.fromEnv() {
    final apiBaseUrl = dotenv.env['API_BASE_URL']?.trim();
    if (apiBaseUrl == null || apiBaseUrl.isEmpty) {
      throw StateError(
        'API_BASE_URL is not set. Set it in .env (see .env.example).',
      );
    }
    final disableOfflineSyncEnv =
        envFlag(dotenv.env['DISABLE_OFFLINE_SYNC']);
    final dataStorage = disableOfflineSyncEnv
        ? DataStorageMode.server
        : parseDataStorageMode(dotenv.env['DATA_STORAGE']);
    final dataEncrypted = disableOfflineSyncEnv
        ? true
        : envFlag(dotenv.env['DATA_ENCRYPTED'], defaultValue: true);

    return AppConfig(
      apiBaseUrl: apiBaseUrl,
      demoEmail: dotenv.env['DEMO_EMAIL']?.trim() ?? '',
      demoPassword: dotenv.env['DEMO_PASSWORD'] ?? '',
      googleSignInServerClientId:
          dotenv.env['GOOGLE_SIGN_IN_SERVER_CLIENT_ID']?.trim() ?? '',
      dataStorage: dataStorage,
      dataEncrypted: dataEncrypted,
      disableOfflineSync: disableOfflineSyncEnv,
    );
  }
}
