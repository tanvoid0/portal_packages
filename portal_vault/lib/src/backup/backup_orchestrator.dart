import 'dart:convert';

import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:get/get.dart';
import 'package:portal_platform/portal_platform.dart';

import '../storage/device_vault_backend.dart';
import '../storage/google_drive_vault_backend.dart';
import '../storage/portal_cloud_vault_backend.dart';
import '../storage/vault_storage_backend.dart';
import '../vault_service.dart';
import 'backup_settings.dart';

/// Fans out encrypted snapshots to enabled storage backends.
class BackupOrchestrator extends GetxService {
  BackupOrchestrator({
    required VaultService vault,
    required DeviceVaultBackend device,
    required PortalCloudVaultBackend portalCloud,
    required GoogleDriveVaultBackend googleDrive,
  })  : _vault = vault,
        _device = device,
        _portalCloud = portalCloud,
        _googleDrive = googleDrive;

  final VaultService _vault;
  final DeviceVaultBackend _device;
  final PortalCloudVaultBackend _portalCloud;
  final GoogleDriveVaultBackend _googleDrive;

  final isRunning = false.obs;
  final lastError = RxnString();

  static const snapshotPath = 'snapshots/latest.json.enc';

  Future<List<VaultStorageBackend>> _enabledBackends() async {
    if (!Get.isRegistered<AppConfig>()) {
      return _settingsEnabledBackends();
    }
    final mode = Get.find<AppConfig>().dataStorage;
    switch (mode) {
      case DataStorageMode.local:
        if (!kIsWeb) return [_device];
        return [];
      case DataStorageMode.server:
        return [_portalCloud];
      case DataStorageMode.googleDrive:
        if (await _googleDrive.isAvailable()) return [_googleDrive];
        return [];
    }
  }

  Future<List<VaultStorageBackend>> _settingsEnabledBackends() async {
    final backends = <VaultStorageBackend>[];
    if (!kIsWeb) backends.add(_device);
    if (await BackupSettingsStore.portalCloudEnabled()) {
      backends.add(_portalCloud);
    }
    if (await BackupSettingsStore.googleDriveEnabled() &&
        await _googleDrive.isAvailable()) {
      backends.add(_googleDrive);
    }
    return backends;
  }

  Future<bool> _canRunNetworkBackups() async {
    if (!await BackupSettingsStore.wifiOnly()) return true;
    if (!Get.isRegistered<ConnectivityService>()) return true;
    final connectivity = Get.find<ConnectivityService>();
    return connectivity.isOnline;
  }

  /// Encrypts [plaintextJson] and writes to all enabled backends.
  Future<void> backupSnapshot(String plaintextJson) async {
    if (!_vault.hasDek) return;
    if (isRunning.value) return;
    isRunning.value = true;
    lastError.value = null;
    try {
      final encrypted = await _vault.encryptPayload(utf8.encode(plaintextJson));
      final backends = await _enabledBackends();
      final allowNetwork = await _canRunNetworkBackups();

      for (final backend in backends) {
        if (backend.backendId != 'device' && !allowNetwork) continue;
        try {
          if (!await backend.isAvailable()) continue;
          await backend.putEncrypted(snapshotPath, encrypted);
          await BackupSettingsStore.markBackedUp(backend.backendId);
        } catch (e, st) {
          debugPrint('[BackupOrchestrator] ${backend.backendId} failed: $e\n$st');
          lastError.value = e.toString();
        }
      }
    } finally {
      isRunning.value = false;
    }
  }

  /// Restores from the configured entity storage backend.
  Future<String?> restoreLatestSnapshot() async {
    if (!_vault.hasDek) return null;
    final order = await _enabledBackends();
    if (order.isEmpty) {
      return _restoreFromDefaultBackendOrder();
    }
    for (final backend in order) {
      try {
        if (!await backend.isAvailable()) continue;
        final raw = await backend.getEncrypted(snapshotPath);
        if (raw == null) continue;
        final plain = await _vault.decryptPayload(raw);
        return utf8.decode(plain);
      } catch (e) {
        debugPrint('[BackupOrchestrator] restore ${backend.backendId}: $e');
      }
    }
    return null;
  }

  Future<String?> _restoreFromDefaultBackendOrder() async {
    final order = <VaultStorageBackend>[
      _portalCloud,
      _googleDrive,
      if (!kIsWeb) _device,
    ];
    for (final backend in order) {
      try {
        if (!await backend.isAvailable()) continue;
        final raw = await backend.getEncrypted(snapshotPath);
        if (raw == null) continue;
        final plain = await _vault.decryptPayload(raw);
        return utf8.decode(plain);
      } catch (e) {
        debugPrint('[BackupOrchestrator] restore ${backend.backendId}: $e');
      }
    }
    return null;
  }

  Future<void> onLocalDataChanged(String aggregateJson) async {
    await backupSnapshot(aggregateJson);
  }
}
