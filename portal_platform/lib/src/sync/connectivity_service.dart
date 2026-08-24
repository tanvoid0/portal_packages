import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

/// Reactive network-connectivity monitor built on `connectivity_plus`.
///
/// [ConnectivityService] checks the device's network interfaces (Wi-Fi,
/// mobile data, ethernet, etc.) and exposes a reactive [isOnline] flag
/// that the rest of the app can observe.
///
/// When the device transitions from **offline → online**, every callback
/// registered via [addReconnectListener] is fired.  [SyncManager] uses
/// this to automatically push queued changes and pull fresh data the
/// moment the connection is restored.
///
/// ## Initialisation
///
/// Register as a GetX service **before** [SyncManager]:
///
/// ```dart
/// await Get.putAsync(() => ConnectivityService().init());
/// ```
///
/// ## Reactive UI binding
///
/// ```dart
/// Obx(() {
///   final online = Get.find<ConnectivityService>().isOnlineRx.value;
///   return Icon(online ? Icons.cloud_done : Icons.cloud_off);
/// })
/// ```
class ConnectivityService extends GetxService {
  final _connectivity = Connectivity();
  final _isOnline = true.obs;
  StreamSubscription<List<ConnectivityResult>>? _sub;
  final _reconnectListeners = <VoidCallback>[];

  /// Whether the device currently has a network interface available.
  ///
  /// Defaults to `true` until the first check completes so that the
  /// app attempts network calls optimistically on cold-start.
  bool get isOnline => _isOnline.value;

  /// Observable version of [isOnline] for use with `Obx` / `ever`.
  RxBool get isOnlineRx => _isOnline;

  /// Register a [callback] to be invoked each time the device
  /// transitions from offline → online.
  ///
  /// Typically used by [SyncManager] to trigger [SyncManager.syncAll].
  void addReconnectListener(VoidCallback callback) {
    _reconnectListeners.add(callback);
  }

  /// Remove a previously registered reconnect listener.
  void removeReconnectListener(VoidCallback callback) {
    _reconnectListeners.remove(callback);
  }

  /// Performs the initial connectivity check and starts listening for
  /// changes.  Returns itself so it can be used with [Get.putAsync].
  Future<ConnectivityService> init() async {
    try {
      final results = await _connectivity.checkConnectivity();
      _isOnline.value = _hasNetwork(results);
    } catch (e) {
      debugPrint('[ConnectivityService] Initial check failed: $e');
      _isOnline.value = true;
    }

    _sub = _connectivity.onConnectivityChanged.listen(_onChanged);
    return this;
  }

  void _onChanged(List<ConnectivityResult> results) {
    final online = _hasNetwork(results);
    final wasOffline = !_isOnline.value;
    _isOnline.value = online;

    if (online && wasOffline) {
      debugPrint('[ConnectivityService] Back online — notifying listeners');
      for (final cb in _reconnectListeners) {
        cb();
      }
    }
  }

  bool _hasNetwork(List<ConnectivityResult> results) =>
      results.isNotEmpty && !results.every((r) => r == ConnectivityResult.none);

  @override
  void onClose() {
    _sub?.cancel();
    _reconnectListeners.clear();
    super.onClose();
  }
}
