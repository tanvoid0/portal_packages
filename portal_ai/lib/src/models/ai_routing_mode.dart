/// How the assistant picks between the Portal server and a local backend,
/// when both are available. Irrelevant to an app with no server transport --
/// there is nothing to route between, so the stored backend always wins.
enum AiRoutingMode {
  /// Try the server; fall back to the stored local backend only when the
  /// server is unreachable. The default.
  serverFirst,

  /// Always use the stored local backend, even with a server present.
  localOnly,

  /// Always use the server, even with a local backend configured.
  serverOnly,
}

extension AiRoutingModeIds on AiRoutingMode {
  String get id => switch (this) {
    AiRoutingMode.serverFirst => 'server_first',
    AiRoutingMode.localOnly => 'local_only',
    AiRoutingMode.serverOnly => 'server_only',
  };

  static AiRoutingMode? fromId(String? id) {
    if (id == null || id.isEmpty) return null;
    for (final mode in AiRoutingMode.values) {
      if (mode.id == id) return mode;
    }
    return null;
  }
}
