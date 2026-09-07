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

  /// Whether a network interface exists, per `connectivity_plus`.
  bool _hasInterface = true;

  /// Whether the server actually answered the last time we tried it.
  ///
  /// An interface is not a connection. Captive-portal wifi, an expired DHCP
  /// lease, a VPN that is up but routing nowhere, and a server that is simply
  /// down all present a perfectly healthy interface — so on interface alone
  /// the app reported itself online, hid the offline banner, and burned a full
  /// request timeout per call while quietly queueing every write. [ApiClient]
  /// reports what it observes through [reportReachable] and the two are
  /// combined.
  bool _isReachable = true;

  /// Whether the app can currently reach the server.
  ///
  /// True only when a network interface exists *and* the server has not just
  /// failed to answer. Defaults to `true` until proven otherwise so a
  /// cold-start still tries optimistically.
  bool get isOnline => _isOnline.value;

  /// Observable version of [isOnline] for use with `Obx` / `ever`.
  RxBool get isOnlineRx => _isOnline;

  /// Report the outcome of a real request against the server.
  ///
  /// Called by [ApiClient]: `true` when a response came back (any status — a
  /// 500 still proves the server is there), `false` when the request never
  /// reached it. This is what makes "connected to wifi, no actual internet"
  /// visible; nothing else can see it.
  void reportReachable(bool reachable) {
    if (_isReachable == reachable) return;
    _isReachable = reachable;
    _recompute();
  }

  /// Folds [_hasInterface] and [_isReachable] into [isOnline], firing the
  /// reconnect listeners on a genuine offline → online edge.
  void _recompute() {
    final online = _hasInterface && _isReachable;
    if (_isOnline.value == online) return;
    _isOnline.value = online;
    if (!online) return;
    debugPrint('[ConnectivityService] Back online — notifying listeners');
    for (final cb in List<VoidCallback>.of(_reconnectListeners)) {
      cb();
    }
  }

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
      _hasInterface = _hasNetwork(results);
    } catch (e) {
      debugPrint('[ConnectivityService] Initial check failed: $e');
      _hasInterface = true;
    }
    _isOnline.value = _hasInterface && _isReachable;

    _sub = _connectivity.onConnectivityChanged.listen(_onChanged);
    return this;
  }

  void _onChanged(List<ConnectivityResult> results) {
    _hasInterface = _hasNetwork(results);
    // A new interface deserves an optimistic retry: whatever made the last
    // one unreachable (captive portal, dead router) does not carry over to a
    // network we have not tried yet.
    if (_hasInterface) _isReachable = true;
    _recompute();
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
