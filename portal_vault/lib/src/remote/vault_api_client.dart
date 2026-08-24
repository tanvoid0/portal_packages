import 'dart:convert';

import 'package:get/get.dart';
import 'package:portal_crypto/portal_crypto.dart';
import 'package:portal_platform/portal_platform.dart';

class VaultWrapsResponse {
  const VaultWrapsResponse({
    this.passwordWrap,
    this.recoveryWrap,
    this.googleWrap,
  });

  final WrappedKeyBundle? passwordWrap;
  final WrappedKeyBundle? recoveryWrap;
  final WrappedKeyBundle? googleWrap;
}

/// Client for `/task/vault/*` endpoints.
class VaultApiClient {
  VaultApiClient([ApiClient? api]) : _api = api ?? Get.find<ApiClient>();

  final ApiClient _api;

  String get _vaultBase {
    final base = _api.baseUrl;
    if (base.endsWith('/api/warp')) {
      return base.replaceFirst(RegExp(r'/api/warp$'), '/api/task/vault');
    }
    if (base.contains('/api/task')) {
      return base.replaceAll(RegExp(r'/task/?$'), '/task/vault');
    }
    return '$base/task/vault';
  }

  Future<VaultWrapsResponse> fetchWraps() async {
    final data = await _api.get('$_vaultBase/wraps') as Map<String, dynamic>?;
    if (data == null) return const VaultWrapsResponse();
    return VaultWrapsResponse(
      passwordWrap: _parseWrap(data['wrap_password']),
      recoveryWrap: _parseWrap(data['wrap_recovery']),
      googleWrap: _parseWrap(data['wrap_google']),
    );
  }

  Future<void> putWraps({
    WrappedKeyBundle? passwordWrap,
    WrappedKeyBundle? recoveryWrap,
    WrappedKeyBundle? googleWrap,
    List<int>? recoverySecretForGrant,
  }) async {
    if (passwordWrap == null && googleWrap == null) {
      throw ArgumentError('At least one of passwordWrap or googleWrap is required.');
    }
    await _api.put(
      '$_vaultBase/wraps',
      body: {
        if (passwordWrap != null) 'wrap_password': passwordWrap.toJson(),
        if (recoveryWrap != null) 'wrap_recovery': recoveryWrap.toJson(),
        if (googleWrap != null) 'wrap_google': googleWrap.toJson(),
        if (recoverySecretForGrant != null)
          'recovery_secret': base64Encode(recoverySecretForGrant),
      },
    );
  }

  Future<Map<String, dynamic>> startRecovery() async {
    return Map<String, dynamic>.from(
      await _api.post('$_vaultBase/recovery/start', body: {}) as Map,
    );
  }

  Future<void> completeRecovery({
    required String grantToken,
    required WrappedKeyBundle wrapPassword,
    WrappedKeyBundle? wrapRecovery,
  }) async {
    await _api.post(
      '$_vaultBase/recovery/complete',
      body: {
        'grant_token': grantToken,
        'wrap_password': wrapPassword.toJson(),
        if (wrapRecovery != null) 'wrap_recovery': wrapRecovery.toJson(),
      },
    );
  }

  /// Re-wrap vault keys after password reset (no login required).
  Future<void> completeResetRecovery({
    required String email,
    required String grantToken,
    required WrappedKeyBundle wrapPassword,
    WrappedKeyBundle? wrapRecovery,
  }) async {
    await _api.postPublic(
      '$_vaultBase/recovery/complete-reset',
      body: {
        'email': email.trim(),
        'grant_token': grantToken,
        'wrap_password': wrapPassword.toJson(),
        if (wrapRecovery != null) 'wrap_recovery': wrapRecovery.toJson(),
      },
    );
  }

  Future<void> putBlob({
    required String blobId,
    required String encodedBlob,
    int version = 1,
  }) async {
    await _api.put(
      '$_vaultBase/blobs/$blobId',
      body: {
        'version': version,
        'ciphertext': encodedBlob,
      },
    );
  }

  Future<String?> getBlob(String blobId) async {
    try {
      final data =
          await _api.get('$_vaultBase/blobs/$blobId') as Map<String, dynamic>?;
      return data?['ciphertext'] as String?;
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  Future<Map<String, dynamic>> fetchMeta() async {
    final data = await _api.get('$_vaultBase/meta') as Map<String, dynamic>?;
    return data ?? {};
  }

  WrappedKeyBundle? _parseWrap(dynamic raw) {
    if (raw is! Map) return null;
    return WrappedKeyBundle.fromJson(Map<String, dynamic>.from(raw));
  }
}
