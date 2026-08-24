import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:local_auth/local_auth.dart';

import 'device_security_preferences.dart';
import 'device_security_service.dart';
import 'portal_device_security_strings.dart';
import 'web_app_pin_store.dart';

/// Manages app lock state and the device-security preference.
class DeviceSecurityController extends GetxService with WidgetsBindingObserver {
  DeviceSecurityController({
    required DeviceSecurityPreferences preferences,
    DeviceSecurityService? service,
    PortalDeviceSecurityStrings? strings,
  })  : _preferences = preferences,
        _service = service ?? DeviceSecurityService(),
        strings = strings ?? _defaultStrings;

  final DeviceSecurityPreferences _preferences;
  final DeviceSecurityService _service;
  final PortalDeviceSecurityStrings strings;

  final enabled = false.obs;
  final isLocked = false.obs;
  final isSupported = false.obs;
  final isBusy = false.obs;
  final availableBiometrics = <BiometricType>[].obs;

  /// Web: user must create an app PIN before the shell is usable.
  final needsWebPinSetup = false.obs;

  final webPinError = RxnString();

  bool _shouldGuard = false;
  bool _retainLockOnUnguarded = false;
  bool _pausedForBackground = false;
  bool _autoUnlockScheduled = false;
  DateTime? _backgroundedAt;

  static const _defaultStrings = PortalDeviceSecurityStrings(
    settingsTitle: 'Device security',
    settingsSubtitle: 'Require Face ID, fingerprint, or device PIN to open the app',
    unavailableSubtitle: 'Not available on this device',
    unlockTitle: 'App locked',
    unlockSubtitle: 'Use Face ID, fingerprint, or your device PIN to continue',
    unlockButton: 'Unlock',
    authenticateReason: 'Unlock Portal',
    enableReason: 'Confirm your identity to turn on device security',
    notAvailableMessage: 'Device security is not available on this device.',
    enableFailedMessage: 'Could not verify your identity. Device security was not enabled.',
  );

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  /// Loads the saved toggle, validates device support, and optionally locks.
  Future<void> init({bool lockOnStart = false}) async {
    enabled.value = _preferences.enabled;
    await _refreshSupport();
    if (enabled.value && lockOnStart) lock();
  }

  Future<void> _refreshSupport() async {
    if (kIsWeb) {
      isSupported.value = await WebAppPinStore.hasPin();
    } else {
      isSupported.value = await _service.isDeviceSupported();
      if (isSupported.value) {
        availableBiometrics.assignAll(await _service.availableBiometrics());
      }
    }
    if (!isSupported.value && enabled.value) {
      await _persistEnabled(false);
    }
  }

  Future<void> _persistEnabled(bool value) async {
    await _preferences.setEnabled(value);
    enabled.value = value;
  }

  Future<bool> setupWebPin(String pin, String confirmPin) async {
    webPinError.value = null;
    if (pin.length < 4) {
      webPinError.value = 'PIN must be at least 4 digits';
      return false;
    }
    if (pin != confirmPin) {
      webPinError.value = 'PINs do not match';
      return false;
    }
    isBusy.value = true;
    try {
      await WebAppPinStore.setPin(pin);
      isSupported.value = true;
      needsWebPinSetup.value = false;
      await _persistEnabled(true);
      unlock();
      return true;
    } finally {
      isBusy.value = false;
    }
  }

  Future<bool> submitWebPin(String pin) async {
    webPinError.value = null;
    isBusy.value = true;
    try {
      final ok = await WebAppPinStore.verifyPin(pin);
      if (!ok) {
        webPinError.value = 'Incorrect PIN';
        return false;
      }
      unlock();
      return true;
    } finally {
      isBusy.value = false;
    }
  }

  void setRetainLockOnUnguarded(bool value) {
    _retainLockOnUnguarded = value;
  }

  void updateShouldGuard(
    bool value, {
    bool retainLockOnUnguarded = false,
  }) {
    _retainLockOnUnguarded = retainLockOnUnguarded;
    final wasGuarding = _shouldGuard;
    _shouldGuard = value;
    if (!value) {
      if (!_retainLockOnUnguarded) isLocked.value = false;
      return;
    }
    if (!wasGuarding && enabled.value) lock();
  }

  void lock() {
    if (!enabled.value) return;
    isLocked.value = true;
    _autoUnlockScheduled = false;
  }

  bool shouldShieldApp(bool routeShouldGuard) {
    if (!routeShouldGuard || !enabled.value) return false;
    return isLocked.value || isBusy.value;
  }

  void scheduleAutoUnlock() {
    if (!_shouldGuard ||
        !enabled.value ||
        !isLocked.value ||
        isBusy.value ||
        _autoUnlockScheduled) {
      return;
    }
    _autoUnlockScheduled = true;
    scheduleMicrotask(() async {
      _autoUnlockScheduled = false;
      await tryUnlock();
    });
  }

  void unlock() {
    isLocked.value = false;
    _pausedForBackground = false;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!enabled.value || !_shouldGuard) return;

    switch (state) {
      case AppLifecycleState.inactive:
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        _pausedForBackground = true;
        _backgroundedAt = DateTime.now();
      case AppLifecycleState.resumed:
        if (_pausedForBackground) {
          _pausedForBackground = false;
          _lockAfterReturningFromBackground();
        }
      case AppLifecycleState.detached:
        break;
    }
  }

  void _lockAfterReturningFromBackground() {
    if (_backgroundedAt == null) return;
    _backgroundedAt = null;
    lock();
    scheduleAutoUnlock();
  }

  Future<void> tryUnlock() async {
    if (!isLocked.value || isBusy.value) return;
    if (kIsWeb) return;
    isBusy.value = true;
    try {
      final ok = await _service.authenticate(
        reason: strings.authenticateReason,
      );
      if (ok) unlock();
    } finally {
      isBusy.value = false;
    }
  }

  Future<bool> authenticateForAction({String? reason}) async {
    if (!enabled.value) return true;
    if (isLocked.value) {
      await tryUnlock();
      return !isLocked.value;
    }
    if (kIsWeb) return true;
    isBusy.value = true;
    try {
      return await _service.authenticate(
        reason: reason ?? strings.authenticateReason,
      );
    } finally {
      isBusy.value = false;
    }
  }

  Future<void> setEnabled(bool value) async {
    if (value == enabled.value) return;

    if (value) {
      if (!isSupported.value) {
        Get.snackbar('', strings.notAvailableMessage);
        return;
      }
      isBusy.value = true;
      try {
        final ok = await _service.authenticate(reason: strings.enableReason);
        if (!ok) {
          Get.snackbar('', strings.enableFailedMessage);
          return;
        }
        await _persistEnabled(true);
        unlock();
      } finally {
        isBusy.value = false;
      }
      return;
    }

    await _persistEnabled(false);
    unlock();
  }

  String biometricsLabel() {
    final types = availableBiometrics.toSet();
    if (types.contains(BiometricType.face)) return 'Face ID';
    if (types.contains(BiometricType.fingerprint)) return 'Fingerprint';
    if (types.contains(BiometricType.strong) ||
        types.contains(BiometricType.weak)) {
      return 'Biometrics';
    }
    return 'Device PIN';
  }
}
