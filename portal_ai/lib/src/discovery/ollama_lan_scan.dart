import 'dart:async';
import 'dart:io';

/// Finds an Ollama daemon on the same network as this device.
///
/// Ollama does not advertise itself — no mDNS, no discovery protocol — so the
/// only way to find one is to knock on every address. That is why this runs on
/// a button rather than on every settings open: a full sweep of the subnet is
/// not something to do behind the user's back, or repeatedly.
///
/// ponytail: assumes a /24, which is every home network and most office ones.
/// A device on a /16 finds nothing and the user types the address, same as now.
abstract final class OllamaLanScan {
  static const port = 11434;

  /// How many addresses are in flight at once. A phone will open far more
  /// sockets than this, but there is no reason to; 64 sweeps a /24 in about a
  /// second and leaves the rest of the app responsive.
  static const _concurrency = 64;

  /// The first Ollama base URL that answers, or null.
  ///
  /// [timeout] is per address, not for the whole sweep.
  static Future<String?> find({
    Duration timeout = const Duration(milliseconds: 500),
  }) async {
    final candidates = await _candidates();
    if (candidates.isEmpty) return null;

    for (var i = 0; i < candidates.length; i += _concurrency) {
      final batch = candidates.skip(i).take(_concurrency);
      final open = await Future.wait(
        batch.map((host) => _isOpen(host, timeout)),
      );
      for (var j = 0; j < open.length; j++) {
        if (open[j]) return 'http://${batch.elementAt(j)}:$port';
      }
    }
    return null;
  }

  /// Every address on this device's own private subnets, nearest first.
  ///
  /// This device's own address is included: on a desktop the daemon is on
  /// this machine, and its LAN address answers just as well as loopback.
  static Future<List<String>> _candidates() async {
    final interfaces = await NetworkInterface.list(
      type: InternetAddressType.IPv4,
      includeLoopback: false,
    );

    final hosts = <String>[];
    final seen = <String>{};
    for (final interface in interfaces) {
      for (final address in interface.addresses) {
        final ip = address.address;
        if (!_isPrivate(ip)) continue;
        final prefix = ip.substring(0, ip.lastIndexOf('.'));
        if (!seen.add(prefix)) continue;
        for (var host = 1; host < 255; host++) {
          hosts.add('$prefix.$host');
        }
      }
    }
    return hosts;
  }

  /// A TCP connect, not an HTTP request: the caller probes what it finds
  /// properly, and a refused connection is the answer for 253 of 254
  /// addresses. Asking each of them for `/api/tags` would take far longer for
  /// exactly the same result.
  static Future<bool> _isOpen(String host, Duration timeout) async {
    Socket? socket;
    try {
      socket = await Socket.connect(host, port, timeout: timeout);
      return true;
    } catch (_) {
      return false;
    } finally {
      socket?.destroy();
    }
  }

  /// RFC 1918 only. A public address on an interface is not somewhere to go
  /// knocking on ports.
  static bool _isPrivate(String ip) {
    final parts = ip.split('.');
    if (parts.length != 4) return false;
    final first = int.tryParse(parts[0]);
    final second = int.tryParse(parts[1]);
    if (first == null || second == null) return false;
    if (first == 10) return true;
    if (first == 192 && second == 168) return true;
    if (first == 172 && second >= 16 && second <= 31) return true;
    return false;
  }
}
