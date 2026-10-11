import 'package:portal_platform/portal_platform.dart' show ApiClient, PortalApiPaths;

import '../model/action.dart';
import 'action_handler.dart';

/// Runs a [ServerCallAction] against a Portal server route using the app's
/// already-authenticated [ApiClient] — the main way a routine acts on another
/// Portal app (create a task, log a workout, add to a list…).
///
/// The action's `path` is module-relative (`task/tasks`); it is resolved
/// against the client's API base, so a routine definition never hard-codes a
/// host and survives a server move.
class ServerCallHandler extends ActionHandler {
  ServerCallHandler(this._api);

  final ApiClient _api;

  @override
  String get type => ServerCallAction.kind;

  @override
  Future<String> run(AutomationAction action) async {
    final a = action as ServerCallAction;
    final url = PortalApiPaths.module(_api.baseUrl, a.path);
    final method = a.method.toUpperCase();

    switch (method) {
      case 'GET':
        await _api.get(url);
      case 'POST':
        await _api.post(url, body: a.body);
      case 'PUT':
        await _api.put(url, body: a.body);
      case 'DELETE':
        await _api.delete(url);
      default:
        throw ArgumentError('unsupported method "$method"');
    }
    return '$method ${a.path}';
  }
}
