// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'app_config.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$AppConfig {
  String get apiBaseUrl => throw _privateConstructorUsedError;
  String get appTitle => throw _privateConstructorUsedError;
  ThemeMode get themeMode => throw _privateConstructorUsedError;
  bool get debugShowCheckedModeBanner => throw _privateConstructorUsedError;
  String get routeLoggedIn => throw _privateConstructorUsedError;
  String get routeLoggedOut => throw _privateConstructorUsedError;
  String get demoEmail => throw _privateConstructorUsedError;
  String get demoPassword => throw _privateConstructorUsedError;

  /// Web OAuth client ID for Google Sign-In on the auth screen.
  String get googleSignInServerClientId => throw _privateConstructorUsedError;

  /// Absolute URL of the sideload `updates.json`. Empty disables update
  /// checks, which is correct for a Play Store build — the store updates it.
  String get updateManifestUrl => throw _privateConstructorUsedError;

  /// Where entity lists are stored (mutually exclusive). Default: server.
  DataStorageMode get dataStorage => throw _privateConstructorUsedError;

  /// When true, entity payloads are encrypted with the vault DEK at rest.
  bool get dataEncrypted => throw _privateConstructorUsedError;

  /// Deprecated: use [dataStorage] == server and [dataEncrypted] == true.
  @Deprecated('Use dataStorage and dataEncrypted')
  bool get disableOfflineSync => throw _privateConstructorUsedError;

  /// Create a copy of AppConfig
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AppConfigCopyWith<AppConfig> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AppConfigCopyWith<$Res> {
  factory $AppConfigCopyWith(AppConfig value, $Res Function(AppConfig) then) =
      _$AppConfigCopyWithImpl<$Res, AppConfig>;
  @useResult
  $Res call({
    String apiBaseUrl,
    String appTitle,
    ThemeMode themeMode,
    bool debugShowCheckedModeBanner,
    String routeLoggedIn,
    String routeLoggedOut,
    String demoEmail,
    String demoPassword,
    String googleSignInServerClientId,
    String updateManifestUrl,
    DataStorageMode dataStorage,
    bool dataEncrypted,
    @Deprecated('Use dataStorage and dataEncrypted') bool disableOfflineSync,
  });
}

/// @nodoc
class _$AppConfigCopyWithImpl<$Res, $Val extends AppConfig>
    implements $AppConfigCopyWith<$Res> {
  _$AppConfigCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AppConfig
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? apiBaseUrl = null,
    Object? appTitle = null,
    Object? themeMode = null,
    Object? debugShowCheckedModeBanner = null,
    Object? routeLoggedIn = null,
    Object? routeLoggedOut = null,
    Object? demoEmail = null,
    Object? demoPassword = null,
    Object? googleSignInServerClientId = null,
    Object? updateManifestUrl = null,
    Object? dataStorage = null,
    Object? dataEncrypted = null,
    Object? disableOfflineSync = null,
  }) {
    return _then(
      _value.copyWith(
            apiBaseUrl: null == apiBaseUrl
                ? _value.apiBaseUrl
                : apiBaseUrl // ignore: cast_nullable_to_non_nullable
                      as String,
            appTitle: null == appTitle
                ? _value.appTitle
                : appTitle // ignore: cast_nullable_to_non_nullable
                      as String,
            themeMode: null == themeMode
                ? _value.themeMode
                : themeMode // ignore: cast_nullable_to_non_nullable
                      as ThemeMode,
            debugShowCheckedModeBanner: null == debugShowCheckedModeBanner
                ? _value.debugShowCheckedModeBanner
                : debugShowCheckedModeBanner // ignore: cast_nullable_to_non_nullable
                      as bool,
            routeLoggedIn: null == routeLoggedIn
                ? _value.routeLoggedIn
                : routeLoggedIn // ignore: cast_nullable_to_non_nullable
                      as String,
            routeLoggedOut: null == routeLoggedOut
                ? _value.routeLoggedOut
                : routeLoggedOut // ignore: cast_nullable_to_non_nullable
                      as String,
            demoEmail: null == demoEmail
                ? _value.demoEmail
                : demoEmail // ignore: cast_nullable_to_non_nullable
                      as String,
            demoPassword: null == demoPassword
                ? _value.demoPassword
                : demoPassword // ignore: cast_nullable_to_non_nullable
                      as String,
            googleSignInServerClientId: null == googleSignInServerClientId
                ? _value.googleSignInServerClientId
                : googleSignInServerClientId // ignore: cast_nullable_to_non_nullable
                      as String,
            updateManifestUrl: null == updateManifestUrl
                ? _value.updateManifestUrl
                : updateManifestUrl // ignore: cast_nullable_to_non_nullable
                      as String,
            dataStorage: null == dataStorage
                ? _value.dataStorage
                : dataStorage // ignore: cast_nullable_to_non_nullable
                      as DataStorageMode,
            dataEncrypted: null == dataEncrypted
                ? _value.dataEncrypted
                : dataEncrypted // ignore: cast_nullable_to_non_nullable
                      as bool,
            disableOfflineSync: null == disableOfflineSync
                ? _value.disableOfflineSync
                : disableOfflineSync // ignore: cast_nullable_to_non_nullable
                      as bool,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$AppConfigImplCopyWith<$Res>
    implements $AppConfigCopyWith<$Res> {
  factory _$$AppConfigImplCopyWith(
    _$AppConfigImpl value,
    $Res Function(_$AppConfigImpl) then,
  ) = __$$AppConfigImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String apiBaseUrl,
    String appTitle,
    ThemeMode themeMode,
    bool debugShowCheckedModeBanner,
    String routeLoggedIn,
    String routeLoggedOut,
    String demoEmail,
    String demoPassword,
    String googleSignInServerClientId,
    String updateManifestUrl,
    DataStorageMode dataStorage,
    bool dataEncrypted,
    @Deprecated('Use dataStorage and dataEncrypted') bool disableOfflineSync,
  });
}

/// @nodoc
class __$$AppConfigImplCopyWithImpl<$Res>
    extends _$AppConfigCopyWithImpl<$Res, _$AppConfigImpl>
    implements _$$AppConfigImplCopyWith<$Res> {
  __$$AppConfigImplCopyWithImpl(
    _$AppConfigImpl _value,
    $Res Function(_$AppConfigImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AppConfig
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? apiBaseUrl = null,
    Object? appTitle = null,
    Object? themeMode = null,
    Object? debugShowCheckedModeBanner = null,
    Object? routeLoggedIn = null,
    Object? routeLoggedOut = null,
    Object? demoEmail = null,
    Object? demoPassword = null,
    Object? googleSignInServerClientId = null,
    Object? updateManifestUrl = null,
    Object? dataStorage = null,
    Object? dataEncrypted = null,
    Object? disableOfflineSync = null,
  }) {
    return _then(
      _$AppConfigImpl(
        apiBaseUrl: null == apiBaseUrl
            ? _value.apiBaseUrl
            : apiBaseUrl // ignore: cast_nullable_to_non_nullable
                  as String,
        appTitle: null == appTitle
            ? _value.appTitle
            : appTitle // ignore: cast_nullable_to_non_nullable
                  as String,
        themeMode: null == themeMode
            ? _value.themeMode
            : themeMode // ignore: cast_nullable_to_non_nullable
                  as ThemeMode,
        debugShowCheckedModeBanner: null == debugShowCheckedModeBanner
            ? _value.debugShowCheckedModeBanner
            : debugShowCheckedModeBanner // ignore: cast_nullable_to_non_nullable
                  as bool,
        routeLoggedIn: null == routeLoggedIn
            ? _value.routeLoggedIn
            : routeLoggedIn // ignore: cast_nullable_to_non_nullable
                  as String,
        routeLoggedOut: null == routeLoggedOut
            ? _value.routeLoggedOut
            : routeLoggedOut // ignore: cast_nullable_to_non_nullable
                  as String,
        demoEmail: null == demoEmail
            ? _value.demoEmail
            : demoEmail // ignore: cast_nullable_to_non_nullable
                  as String,
        demoPassword: null == demoPassword
            ? _value.demoPassword
            : demoPassword // ignore: cast_nullable_to_non_nullable
                  as String,
        googleSignInServerClientId: null == googleSignInServerClientId
            ? _value.googleSignInServerClientId
            : googleSignInServerClientId // ignore: cast_nullable_to_non_nullable
                  as String,
        updateManifestUrl: null == updateManifestUrl
            ? _value.updateManifestUrl
            : updateManifestUrl // ignore: cast_nullable_to_non_nullable
                  as String,
        dataStorage: null == dataStorage
            ? _value.dataStorage
            : dataStorage // ignore: cast_nullable_to_non_nullable
                  as DataStorageMode,
        dataEncrypted: null == dataEncrypted
            ? _value.dataEncrypted
            : dataEncrypted // ignore: cast_nullable_to_non_nullable
                  as bool,
        disableOfflineSync: null == disableOfflineSync
            ? _value.disableOfflineSync
            : disableOfflineSync // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc

class _$AppConfigImpl extends _AppConfig {
  const _$AppConfigImpl({
    required this.apiBaseUrl,
    this.appTitle = 'Portal Warp',
    this.themeMode = ThemeMode.system,
    this.debugShowCheckedModeBanner = false,
    this.routeLoggedIn = '/',
    this.routeLoggedOut = '/login',
    this.demoEmail = '',
    this.demoPassword = '',
    this.googleSignInServerClientId = '',
    this.updateManifestUrl = '',
    this.dataStorage = DataStorageMode.server,
    this.dataEncrypted = true,
    @Deprecated('Use dataStorage and dataEncrypted')
    this.disableOfflineSync = false,
  }) : super._();

  @override
  final String apiBaseUrl;
  @override
  @JsonKey()
  final String appTitle;
  @override
  @JsonKey()
  final ThemeMode themeMode;
  @override
  @JsonKey()
  final bool debugShowCheckedModeBanner;
  @override
  @JsonKey()
  final String routeLoggedIn;
  @override
  @JsonKey()
  final String routeLoggedOut;
  @override
  @JsonKey()
  final String demoEmail;
  @override
  @JsonKey()
  final String demoPassword;

  /// Web OAuth client ID for Google Sign-In on the auth screen.
  @override
  @JsonKey()
  final String googleSignInServerClientId;

  /// Absolute URL of the sideload `updates.json`. Empty disables update
  /// checks, which is correct for a Play Store build — the store updates it.
  @override
  @JsonKey()
  final String updateManifestUrl;

  /// Where entity lists are stored (mutually exclusive). Default: server.
  @override
  @JsonKey()
  final DataStorageMode dataStorage;

  /// When true, entity payloads are encrypted with the vault DEK at rest.
  @override
  @JsonKey()
  final bool dataEncrypted;

  /// Deprecated: use [dataStorage] == server and [dataEncrypted] == true.
  @override
  @JsonKey()
  @Deprecated('Use dataStorage and dataEncrypted')
  final bool disableOfflineSync;

  @override
  String toString() {
    return 'AppConfig(apiBaseUrl: $apiBaseUrl, appTitle: $appTitle, themeMode: $themeMode, debugShowCheckedModeBanner: $debugShowCheckedModeBanner, routeLoggedIn: $routeLoggedIn, routeLoggedOut: $routeLoggedOut, demoEmail: $demoEmail, demoPassword: $demoPassword, googleSignInServerClientId: $googleSignInServerClientId, updateManifestUrl: $updateManifestUrl, dataStorage: $dataStorage, dataEncrypted: $dataEncrypted, disableOfflineSync: $disableOfflineSync)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AppConfigImpl &&
            (identical(other.apiBaseUrl, apiBaseUrl) ||
                other.apiBaseUrl == apiBaseUrl) &&
            (identical(other.appTitle, appTitle) ||
                other.appTitle == appTitle) &&
            (identical(other.themeMode, themeMode) ||
                other.themeMode == themeMode) &&
            (identical(
                  other.debugShowCheckedModeBanner,
                  debugShowCheckedModeBanner,
                ) ||
                other.debugShowCheckedModeBanner ==
                    debugShowCheckedModeBanner) &&
            (identical(other.routeLoggedIn, routeLoggedIn) ||
                other.routeLoggedIn == routeLoggedIn) &&
            (identical(other.routeLoggedOut, routeLoggedOut) ||
                other.routeLoggedOut == routeLoggedOut) &&
            (identical(other.demoEmail, demoEmail) ||
                other.demoEmail == demoEmail) &&
            (identical(other.demoPassword, demoPassword) ||
                other.demoPassword == demoPassword) &&
            (identical(
                  other.googleSignInServerClientId,
                  googleSignInServerClientId,
                ) ||
                other.googleSignInServerClientId ==
                    googleSignInServerClientId) &&
            (identical(other.updateManifestUrl, updateManifestUrl) ||
                other.updateManifestUrl == updateManifestUrl) &&
            (identical(other.dataStorage, dataStorage) ||
                other.dataStorage == dataStorage) &&
            (identical(other.dataEncrypted, dataEncrypted) ||
                other.dataEncrypted == dataEncrypted) &&
            (identical(other.disableOfflineSync, disableOfflineSync) ||
                other.disableOfflineSync == disableOfflineSync));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    apiBaseUrl,
    appTitle,
    themeMode,
    debugShowCheckedModeBanner,
    routeLoggedIn,
    routeLoggedOut,
    demoEmail,
    demoPassword,
    googleSignInServerClientId,
    updateManifestUrl,
    dataStorage,
    dataEncrypted,
    disableOfflineSync,
  );

  /// Create a copy of AppConfig
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AppConfigImplCopyWith<_$AppConfigImpl> get copyWith =>
      __$$AppConfigImplCopyWithImpl<_$AppConfigImpl>(this, _$identity);
}

abstract class _AppConfig extends AppConfig {
  const factory _AppConfig({
    required final String apiBaseUrl,
    final String appTitle,
    final ThemeMode themeMode,
    final bool debugShowCheckedModeBanner,
    final String routeLoggedIn,
    final String routeLoggedOut,
    final String demoEmail,
    final String demoPassword,
    final String googleSignInServerClientId,
    final String updateManifestUrl,
    final DataStorageMode dataStorage,
    final bool dataEncrypted,
    @Deprecated('Use dataStorage and dataEncrypted')
    final bool disableOfflineSync,
  }) = _$AppConfigImpl;
  const _AppConfig._() : super._();

  @override
  String get apiBaseUrl;
  @override
  String get appTitle;
  @override
  ThemeMode get themeMode;
  @override
  bool get debugShowCheckedModeBanner;
  @override
  String get routeLoggedIn;
  @override
  String get routeLoggedOut;
  @override
  String get demoEmail;
  @override
  String get demoPassword;

  /// Web OAuth client ID for Google Sign-In on the auth screen.
  @override
  String get googleSignInServerClientId;

  /// Absolute URL of the sideload `updates.json`. Empty disables update
  /// checks, which is correct for a Play Store build — the store updates it.
  @override
  String get updateManifestUrl;

  /// Where entity lists are stored (mutually exclusive). Default: server.
  @override
  DataStorageMode get dataStorage;

  /// When true, entity payloads are encrypted with the vault DEK at rest.
  @override
  bool get dataEncrypted;

  /// Deprecated: use [dataStorage] == server and [dataEncrypted] == true.
  @override
  @Deprecated('Use dataStorage and dataEncrypted')
  bool get disableOfflineSync;

  /// Create a copy of AppConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AppConfigImplCopyWith<_$AppConfigImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
