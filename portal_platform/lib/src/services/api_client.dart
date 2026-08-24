import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';

import '../config/app_config.dart';
import '../extensions/uri_extensions.dart';
import '../observability/portal_logger.dart';
import '../routing/deep_link_service.dart';
import '../routing/portal_navigation.dart';
import '../session/session_controller.dart';
import 'token_storage.dart';

/// Per-request tracing (start/success). Errors still log in [kDebugMode] without this.
/// Enable via either:
/// - `flutter run --dart-define=API_VERBOSE_REQUESTS=true`
/// - `.env`: `API_VERBOSE_REQUESTS=true`
const bool _kApiVerboseRequests = bool.fromEnvironment(
  'API_VERBOSE_REQUESTS',
  defaultValue: false,
);

bool get _runtimeApiVerboseRequests {
  final v = dotenv.env['API_VERBOSE_REQUESTS']?.trim().toLowerCase();
  return v == 'true' || v == '1' || v == 'yes';
}

bool get _apiVerboseRequests =>
    _kApiVerboseRequests || _runtimeApiVerboseRequests;

/// API Client for backend communication.
/// Base URL is provided at init from [AppConfig.apiBaseUrl].
class ApiClient extends GetxService {
  /// Base URL set in [init].
  String get baseUrl => _baseUrl;
  late String _baseUrl;

  final TokenStorage _tokenStorage = TokenStorage();
  final Uuid _uuid = const Uuid();

  /// Reset by [_storeSession] and a successful refresh so a later expiry on a
  /// new session still clears tokens and redirects.
  bool _handlingSessionExpiry = false;

  /// Set while a refresh is running so concurrent 401s await the same call.
  Future<bool>? _refreshInFlight;

  /// Refresh must not hang: with single-flight, one stuck call blocks every
  /// waiter.
  static const Duration _refreshTimeout = Duration(seconds: 15);

  /// Applied in the two request funnels rather than at each call site, so a
  /// black-holed connection surfaces as a TimeoutException instead of hanging
  /// the caller forever. Health checks pass their own shorter budget.
  static const Duration _requestTimeout = Duration(seconds: 30);

  /// Initialize the API client with [baseUrl] from [AppConfig.fromEnv].
  Future<ApiClient> init({required String baseUrl}) async {
    _baseUrl = baseUrl.trim();
    if (_baseUrl.isEmpty) {
      throw StateError(
        'API base URL must not be empty. Set API_BASE_URL in .env (see .env.example).',
      );
    }
    await _tokenStorage.init();
    return this;
  }

  String _newTraceId() {
    if (PortalLogger.isInitialized) {
      return PortalLogger.I.newTraceId();
    }
    return _uuid.v4();
  }

  void _logApi(
    String severity,
    String message, {
    required String traceId,
    Map<String, Object?>? context,
  }) {
    if (!PortalLogger.isInitialized) return;
    final logger = PortalLogger.I;
    final payload = {'traceId': traceId, if (context != null) ...context};
    switch (severity) {
      case 'DEBUG':
        logger.debug('ApiClient', message, payload);
      case 'INFO':
        logger.info('ApiClient', message, payload);
      case 'WARN':
        logger.warn('ApiClient', message, payload);
      case 'ERROR':
        logger.error('ApiClient', message, payload, traceId);
    }
  }

  /// Get authorization headers
  Future<Map<String, String>> _getHeaders({
    bool requireAuth = true,
    required String traceId,
  }) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'X-Request-Id': traceId,
    };

    if (requireAuth) {
      final token = await _tokenStorage.getAccessToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  Map<String, String> _publicHeaders(String traceId) {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'X-Request-Id': traceId,
    };
  }

  String _resolveResponseTraceId(
    http.Response response, {
    required String fallbackTraceId,
  }) {
    final header = response.headers['x-request-id'];
    if (header != null && header.trim().isNotEmpty) {
      return header.trim();
    }
    if (response.body.isEmpty) return fallbackTraceId;
    try {
      final body = jsonDecode(response.body);
      if (body is Map) {
        final requestId = body['requestId']?.toString();
        if (requestId != null && requestId.isNotEmpty) {
          return requestId;
        }
      }
    } catch (_) {
      // Ignore malformed JSON when resolving trace ID.
    }
    return fallbackTraceId;
  }

  /// Handle response and check for errors
  dynamic _handleResponse(http.Response response, {required String traceId}) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
    }

    final resolvedTraceId = _resolveResponseTraceId(
      response,
      fallbackTraceId: traceId,
    );

    final parsed = _parseErrorResponse(response);
    throw ApiException(
      parsed.message,
      response.statusCode,
      traceId: resolvedTraceId,
      code: parsed.code,
    );
  }

  ({String message, String? code}) _parseErrorResponse(http.Response response) {
    if (response.body.isEmpty) {
      return (
        message: response.statusCode == 401
            ? 'Unauthorized'
            : response.statusCode == 404
            ? 'Not found'
            : 'Request failed',
        code: null,
      );
    }

    try {
      final body = jsonDecode(response.body);
      if (body is! Map) {
        return (message: 'Request failed', code: null);
      }
      final map = Map<String, dynamic>.from(body);
      String message =
          map['message'] as String? ??
          map['detail'] as String? ??
          (response.statusCode == 401
              ? 'Unauthorized'
              : response.statusCode == 404
              ? 'Not found'
              : 'Request failed');
      if (map['errors'] is List && (map['errors'] as List).isNotEmpty) {
        final first = (map['errors'] as List).first;
        if (first is Map &&
            first['messages'] is List &&
            (first['messages'] as List).isNotEmpty) {
          message = (first['messages'] as List).first.toString();
        }
      }
      final code = map['code']?.toString();
      return (message: message, code: code);
    } catch (_) {
      return (
        message: response.statusCode == 401 ? 'Unauthorized' : 'Request failed',
        code: null,
      );
    }
  }

  /// Log request failures for debugging (connection refused, timeout, etc.)
  void _logRequestError(
    String method,
    String url,
    Object error,
    StackTrace? st, {
    String? traceId,
  }) {
    final resolvedTraceId = traceId ?? _newTraceId();
    _logApi(
      'ERROR',
      'API request failed: $method $url',
      traceId: resolvedTraceId,
      context: {
        'method': method,
        'url': url,
        'error': error.toString(),
        if (st != null) 'stack': st.toString(),
      },
    );
    developer.log(
      'API request failed: $method $url',
      name: 'ApiClient',
      error: error,
      stackTrace: st,
    );
    if (kDebugMode) {
      debugPrint(
        '[ApiClient] Request failed: $method $url (traceId=$resolvedTraceId)',
      );
      debugPrint('[ApiClient] Error type: ${error.runtimeType}');
      debugPrint('[ApiClient] Error: $error');
      if (st != null) debugPrint('[ApiClient] Stack: $st');
    }
  }

  /// Refresh access token using refresh token.
  ///
  /// Single-flight: concurrent 401s share one refresh call. Refresh tokens
  /// rotate server-side, so parallel refreshes invalidate each other and the
  /// losers get signed out mid-session.
  Future<bool> refreshToken() {
    return _refreshInFlight ??= _performRefresh().whenComplete(() {
      _refreshInFlight = null;
    });
  }

  Future<bool> _performRefresh() async {
    final refreshToken = await _tokenStorage.getRefreshToken();
    if (refreshToken == null) return false;

    final url = '$baseUrl/auth/refresh';
    try {
      final response = await http
          .post(
            Uri.parse(url).normalizePath(),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'refresh_token': refreshToken}),
          )
          .timeout(_refreshTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await _tokenStorage.saveTokens(
          accessToken: data['access_token'] as String,
          refreshToken: data['refresh_token'] as String,
        );
        _handlingSessionExpiry = false;
        return true;
      }
    } catch (e, st) {
      _logRequestError('POST', url, e, st);
    }

    return false;
  }

  /// Persists tokens and profile from an auth response and marks the session
  /// live again, so a later expiry is handled instead of silently swallowed.
  Future<void> _storeSession(dynamic data) async {
    await _tokenStorage.saveTokens(
      accessToken: data['tokens']['access_token'] as String,
      refreshToken: data['tokens']['refresh_token'] as String,
    );
    await _tokenStorage.saveUser(data['user']);
    _handlingSessionExpiry = false;
  }

  /// Clears stored credentials and returns the user to login when refresh fails.
  Future<Never> _failSessionExpired() async {
    if (!_handlingSessionExpiry) {
      _handlingSessionExpiry = true;
      await _tokenStorage.clearTokens();
      if (Get.isRegistered<SessionController>()) {
        Get.find<SessionController>().user.value = null;
        if (Get.isRegistered<DeepLinkService>()) {
          Get.find<DeepLinkService>().clearPending();
        }
        final loggedOutRoute = Get.find<AppConfig>().routeLoggedOut;
        final currentPath = PortalNavigation.require.currentPath;
        if (currentPath != loggedOutRoute) {
          Get.snackbar(
            'Session expired',
            'Please login again.',
            snackPosition: SnackPosition.BOTTOM,
            duration: const Duration(seconds: 4),
          );
          PortalNavigation.require.go(loggedOutRoute);
        }
      }
    }
    throw ApiException(
      'Session expired. Please login again.',
      401,
      traceId: _newTraceId(),
      code: 'AUTH_TOKEN_EXPIRED',
    );
  }

  /// Runs [request] once; on 401 tries refresh and retries; otherwise signs out.
  Future<http.Response> _authorizeWithRetry(
    String traceId,
    Future<http.Response> Function(Map<String, String> headers) request,
  ) async {
    var headers = await _getHeaders(traceId: traceId);
    var response = await request(headers).timeout(_requestTimeout);

    if (response.statusCode != 401) return response;

    final refreshed = await refreshToken();
    if (refreshed) {
      headers = await _getHeaders(traceId: traceId);
      response = await request(headers).timeout(_requestTimeout);
      if (response.statusCode != 401) return response;
    }

    return _failSessionExpired();
  }

  /// Make a request with automatic token refresh
  Future<dynamic> _requestWithRetry(
    String method,
    String url,
    Future<http.Response> Function(Map<String, String> headers) request,
  ) async {
    final traceId = _newTraceId();
    _logApi(
      'INFO',
      'Request started',
      traceId: traceId,
      context: {'method': method, 'url': url},
    );
    try {
      final response = await _authorizeWithRetry(traceId, request);
      final result = _handleResponse(response, traceId: traceId);
      _logApi(
        'INFO',
        'Request completed',
        traceId: traceId,
        context: {'method': method, 'url': url, 'status': response.statusCode},
      );
      return result;
    } catch (e, st) {
      _logRequestError(method, url, e, st, traceId: traceId);
      rethrow;
    }
  }

  Future<dynamic> _requestPublic(
    String method,
    String url,
    Future<http.Response> Function(Map<String, String> headers) request,
  ) async {
    final traceId = _newTraceId();
    _logApi(
      'INFO',
      'Request started',
      traceId: traceId,
      context: {'method': method, 'url': url},
    );
    try {
      final response =
          await request(_publicHeaders(traceId)).timeout(_requestTimeout);
      final result = _handleResponse(response, traceId: traceId);
      _logApi(
        'INFO',
        'Request completed',
        traceId: traceId,
        context: {'method': method, 'url': url, 'status': response.statusCode},
      );
      return result;
    } catch (e, st) {
      _logRequestError(method, url, e, st, traceId: traceId);
      rethrow;
    }
  }

  /// GET request
  Future<dynamic> get(
    String endpoint, {
    Map<String, String>? queryParams,
  }) async {
    final uri = endpoint.startsWith('http')
        ? resolveServerAssetUri(endpoint)
        : Uri.parse('$baseUrl$endpoint').normalizePath();
    var finalUri = uri;
    if (queryParams != null && queryParams.isNotEmpty) {
      finalUri = uri.replace(queryParameters: queryParams);
    }
    if (kDebugMode && _apiVerboseRequests) {
      developer.log('GET $finalUri', name: 'ApiClient');
      debugPrint('[ApiClient] GET $finalUri');
    }
    try {
      final result = await _requestWithRetry(
        'GET',
        finalUri.toString(),
        (headers) => http.get(finalUri, headers: headers),
      );
      if (kDebugMode && _apiVerboseRequests) {
        debugPrint('[ApiClient] GET $finalUri -> success');
      }
      return result;
    } catch (e, st) {
      if (kDebugMode) {
        // 404/401 are often handled by callers or [_failSessionExpired]
        final is404 = e is ApiException && e.statusCode == 404;
        final is401 = e is ApiException && e.statusCode == 401;
        if (!is404 && !is401) {
          debugPrint('[ApiClient] GET $finalUri -> failed: $e');
          developer.log(
            'GET failed',
            name: 'ApiClient',
            error: e,
            stackTrace: st,
          );
        }
      }
      rethrow;
    }
  }

  /// JSON-encode [body] for HTTP requests. Returns null when [body] is omitted
  /// so Express body-parser (strict JSON) does not reject primitive `null`.
  String? _encodeJsonBody(dynamic body) =>
      body == null ? null : jsonEncode(body);

  /// POST request
  Future<dynamic> post(String endpoint, {dynamic body}) async {
    final uri = endpoint.startsWith('http')
        ? resolveServerAssetUri(endpoint)
        : Uri.parse('$baseUrl$endpoint').normalizePath();

    return _requestWithRetry(
      'POST',
      uri.toString(),
      (headers) => http.post(uri, headers: headers, body: _encodeJsonBody(body)),
    );
  }

  /// POST without Authorization (password reset, vault recovery after reset).
  Future<dynamic> postPublic(String endpoint, {dynamic body}) async {
    final uri = endpoint.startsWith('http')
        ? resolveServerAssetUri(endpoint)
        : Uri.parse('$baseUrl$endpoint').normalizePath();
    return _requestPublic(
      'POST',
      uri.toString(),
      (headers) =>
          http.post(uri, headers: headers, body: _encodeJsonBody(body)),
    );
  }

  /// PUT request
  Future<dynamic> put(String endpoint, {dynamic body}) async {
    final uri = endpoint.startsWith('http')
        ? resolveServerAssetUri(endpoint)
        : Uri.parse('$baseUrl$endpoint').normalizePath();

    return _requestWithRetry(
      'PUT',
      uri.toString(),
      (headers) => http.put(uri, headers: headers, body: _encodeJsonBody(body)),
    );
  }

  /// PATCH request
  Future<dynamic> patch(String endpoint, {dynamic body}) async {
    final uri = endpoint.startsWith('http')
        ? resolveServerAssetUri(endpoint)
        : Uri.parse('$baseUrl$endpoint').normalizePath();

    return _requestWithRetry(
      'PATCH',
      uri.toString(),
      (headers) =>
          http.patch(uri, headers: headers, body: _encodeJsonBody(body)),
    );
  }

  /// DELETE request
  Future<dynamic> delete(
    String endpoint, {
    Map<String, String>? queryParams,
  }) async {
    final uri = endpoint.startsWith('http')
        ? resolveServerAssetUri(endpoint)
        : Uri.parse('$baseUrl$endpoint').normalizePath();
    var finalUri = uri;
    if (queryParams != null && queryParams.isNotEmpty) {
      finalUri = uri.replace(queryParameters: queryParams);
    }

    return _requestWithRetry(
      'DELETE',
      finalUri.toString(),
      (headers) => http.delete(finalUri, headers: headers),
    );
  }

  /// Rewrite a server-issued absolute URL so it uses the same host/port as [baseUrl] (emulator vs localhost).
  Uri resolveServerAssetUri(String absoluteUrl) {
    final u = Uri.parse(absoluteUrl);
    final b = Uri.parse(_baseUrl);
    return u.replace(scheme: b.scheme, host: b.host, port: b.port);
  }

  /// Multipart POST (e.g. SVG upload). Parses JSON body on success.
  Future<dynamic> postMultipart(
    String endpoint, {
    required String fieldName,
    required List<int> fileBytes,
    required String filename,
    Map<String, String>? fields,
  }) async {
    final uri = endpoint.startsWith('http')
        ? resolveServerAssetUri(endpoint)
        : Uri.parse('$baseUrl$endpoint').normalizePath();

    return _requestWithRetry('POST', uri.toString(), (headers) async {
      final h = Map<String, String>.from(headers);
      h.remove('Content-Type');
      final req = http.MultipartRequest('POST', uri);
      req.headers.addAll(h);
      if (fields != null) {
        req.fields.addAll(fields);
      }
      req.files.add(
        http.MultipartFile.fromBytes(fieldName, fileBytes, filename: filename),
      );
      final streamed = await req.send();
      return http.Response.fromStream(streamed);
    });
  }

  /// Multipart POST with multiple files under the same [fieldName] (e.g. Nest [FilesInterceptor]).
  Future<dynamic> postMultipartFiles(
    String endpoint, {
    required String fieldName,
    required List<({List<int> bytes, String filename})> files,
    Map<String, String>? fields,
  }) async {
    final uri = endpoint.startsWith('http')
        ? resolveServerAssetUri(endpoint)
        : Uri.parse('$baseUrl$endpoint').normalizePath();

    return _requestWithRetry('POST', uri.toString(), (headers) async {
      final h = Map<String, String>.from(headers);
      h.remove('Content-Type');
      final req = http.MultipartRequest('POST', uri);
      req.headers.addAll(h);
      if (fields != null) {
        req.fields.addAll(fields);
      }
      for (final f in files) {
        req.files.add(
          http.MultipartFile.fromBytes(
            fieldName,
            f.bytes,
            filename: f.filename,
          ),
        );
      }
      final streamed = await req.send();
      return http.Response.fromStream(streamed);
    });
  }

  /// GET raw UTF-8 body (for authenticated SVG). [absoluteOrRelative] may be full URL or path under [baseUrl].
  Future<String> getUtf8(String absoluteOrRelative) async {
    final uri = absoluteOrRelative.startsWith('http')
        ? resolveServerAssetUri(absoluteOrRelative)
        : Uri.parse('$baseUrl$absoluteOrRelative').normalizePath();
    final traceId = _newTraceId();
    _logApi(
      'INFO',
      'Request started',
      traceId: traceId,
      context: {'method': 'GET', 'url': uri.toString()},
    );

    try {
      final response = await _authorizeWithRetry(traceId, (headers) async {
        final h = Map<String, String>.from(headers);
        h.remove('Content-Type');
        return http.get(uri, headers: h);
      });

      if (response.statusCode >= 200 && response.statusCode < 300) {
        _logApi(
          'INFO',
          'Request completed',
          traceId: traceId,
          context: {
            'method': 'GET',
            'url': uri.toString(),
            'status': response.statusCode,
          },
        );
        return response.body;
      }

      final resolvedTraceId = _resolveResponseTraceId(
        response,
        fallbackTraceId: traceId,
      );
      final parsed = _parseErrorResponse(response);
      throw ApiException(
        parsed.message,
        response.statusCode,
        traceId: resolvedTraceId,
        code: parsed.code,
      );
    } catch (e, st) {
      _logRequestError('GET', uri.toString(), e, st, traceId: traceId);
      rethrow;
    }
  }

  /// GET binary body with auth (e.g. receipt images).
  Future<Uint8List> getBytes(String pathUnderWarp) async {
    final uri = pathUnderWarp.startsWith('http')
        ? resolveServerAssetUri(pathUnderWarp)
        : Uri.parse('$baseUrl$pathUnderWarp').normalizePath();
    final traceId = _newTraceId();
    _logApi(
      'INFO',
      'Request started',
      traceId: traceId,
      context: {'method': 'GET', 'url': uri.toString()},
    );

    try {
      final response = await _authorizeWithRetry(traceId, (headers) async {
        final h = Map<String, String>.from(headers);
        h.remove('Content-Type');
        return http.get(uri, headers: h);
      });

      if (response.statusCode >= 200 && response.statusCode < 300) {
        _logApi(
          'INFO',
          'Request completed',
          traceId: traceId,
          context: {
            'method': 'GET',
            'url': uri.toString(),
            'status': response.statusCode,
          },
        );
        return response.bodyBytes;
      }

      final resolvedTraceId = _resolveResponseTraceId(
        response,
        fallbackTraceId: traceId,
      );
      final parsed = _parseErrorResponse(response);
      throw ApiException(
        parsed.message,
        response.statusCode,
        traceId: resolvedTraceId,
        code: parsed.code,
      );
    } catch (e, st) {
      _logRequestError('GET', uri.toString(), e, st, traceId: traceId);
      rethrow;
    }
  }

  // ============ Health check (no token, for debugging) ============

  /// GET /api/health to verify server is reachable. Returns null on failure.
  Future<Map<String, dynamic>?> checkHealth() async {
    final url = '$baseUrl/health';
    try {
      final response = await http
          .get(
            Uri.parse(url).normalizePath(),
            headers: {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 5));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (response.body.isEmpty) return {'status': 'ok'};
        return jsonDecode(response.body) as Map<String, dynamic>?;
      }
      return {'error': 'HTTP ${response.statusCode}', 'body': response.body};
    } catch (e, st) {
      _logRequestError('GET', url, e, st);
      return {'error': e.toString()};
    }
  }

  /// GET /api/health/ready — HTTP server up and MongoDB accepts ping.
  Future<BackendReadinessResult> checkBackendReadiness({
    Duration timeout = const Duration(seconds: 12),
  }) async {
    final url = '$baseUrl/health/ready';
    try {
      final response = await http
          .get(
            Uri.parse(url).normalizePath(),
            headers: {'Accept': 'application/json'},
          )
          .timeout(timeout);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return const BackendReadinessResult(isReady: true);
      }
      String detail = 'HTTP ${response.statusCode}';
      if (response.body.isNotEmpty) {
        try {
          final map = jsonDecode(response.body) as Map<String, dynamic>;
          final mongo = map['mongodb'];
          if (mongo is Map && mongo['error'] != null) {
            detail = '${mongo['error']}';
          }
        } catch (_) {
          detail = response.body.length > 200
              ? '${response.body.substring(0, 200)}…'
              : response.body;
        }
      }
      return BackendReadinessResult(isReady: false, errorMessage: detail);
    } catch (e, st) {
      _logRequestError('GET', url, e, st);
      return BackendReadinessResult(isReady: false, errorMessage: e.toString());
    }
  }

  // ============ Auth Methods (no token required) ============

  /// Register a new user
  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String name,
  }) async {
    final url = '$baseUrl/auth/register';
    final data = await _requestPublic(
      'POST',
      url,
      (headers) => http.post(
        Uri.parse(url).normalizePath(),
        headers: headers,
        body: jsonEncode({'email': email, 'password': password, 'name': name}),
      ),
    );

    await _storeSession(data);

    return Map<String, dynamic>.from(data as Map);
  }

  /// Sign in with a Google ID token (verified server-side).
  Future<Map<String, dynamic>> loginWithGoogle({
    required String idToken,
  }) async {
    final url = '$baseUrl/auth/google';
    final data = await _requestPublic(
      'POST',
      url,
      (headers) => http.post(
        Uri.parse(url).normalizePath(),
        headers: headers,
        body: jsonEncode({'id_token': idToken}),
      ),
    );

    await _storeSession(data);

    return Map<String, dynamic>.from(data as Map);
  }

  /// Register or sign in a device-local user (OS username + hostname).
  Future<Map<String, dynamic>> registerOrLoginLocal({
    required String username,
    required String hostname,
  }) async {
    final url = '$baseUrl/auth/local';
    final data = await _requestPublic(
      'POST',
      url,
      (headers) => http.post(
        Uri.parse(url).normalizePath(),
        headers: headers,
        body: jsonEncode({'username': username, 'hostname': hostname}),
      ),
    );

    await _storeSession(data);

    return Map<String, dynamic>.from(data as Map);
  }

  /// Login user
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final url = '$baseUrl/auth/login';
    final data = await _requestPublic(
      'POST',
      url,
      (headers) => http.post(
        Uri.parse(url).normalizePath(),
        headers: headers,
        body: jsonEncode({'email': email, 'password': password}),
      ),
    );

    await _storeSession(data);

    return Map<String, dynamic>.from(data as Map);
  }

  /// Logout user
  Future<void> logout() async {
    await _tokenStorage.clearTokens();
  }

  /// Request a password-reset OTP (always returns ok if email format valid).
  Future<void> requestPasswordReset({required String email}) async {
    await postPublic(
      '/auth/password-reset/request',
      body: {'email': email.trim()},
    );
  }

  /// Change password while logged in (requires valid access token).
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await post(
      '/auth/password/change',
      body: {'current_password': currentPassword, 'new_password': newPassword},
    );
  }

  /// Verify OTP, set new password; may return [vault_recovery] for encrypted vaults.
  Future<Map<String, dynamic>> completePasswordReset({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    final data = await postPublic(
      '/auth/password-reset/complete',
      body: {
        'email': email.trim(),
        'code': code.trim(),
        'new_password': newPassword,
      },
    );
    return Map<String, dynamic>.from(data as Map);
  }

  /// Check if user is logged in
  Future<bool> isLoggedIn() async {
    return await _tokenStorage.hasValidToken();
  }

  /// Get current user
  Future<Map<String, dynamic>?> getCurrentUser() async {
    return await _tokenStorage.getUser();
  }

  /// Validates the access token against the user store and refreshes the local
  /// profile cache. Call before wardrobe (and similar) loads so stale JWTs
  /// after `seed --fresh` trigger refresh / re-auth instead of silent empty data.
  Future<void> syncProfileFromServer() async {
    final raw = await get('/auth/me');
    if (raw is! Map) return;
    final m = Map<String, dynamic>.from(raw);
    final id = m['id']?.toString() ?? '';
    await _tokenStorage.saveUser({
      'id': id,
      'email': m['email']?.toString() ?? '',
      'name': m['name']?.toString() ?? '',
    });
  }
}

/// Result of [ApiClient.checkBackendReadiness].
class BackendReadinessResult {
  const BackendReadinessResult({required this.isReady, this.errorMessage});

  final bool isReady;
  final String? errorMessage;
}

/// API Exception
class ApiException implements Exception {
  final String message;
  final int statusCode;
  final String? traceId;
  final String? code;

  ApiException(this.message, this.statusCode, {this.traceId, this.code});

  @override
  String toString() {
    final traceSuffix = traceId == null ? '' : ' (traceId: $traceId)';
    final codeSuffix = code == null ? '' : ' [${code!}]';
    return 'ApiException: $message (status: $statusCode)$codeSuffix$traceSuffix';
  }
}
