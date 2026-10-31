import 'package:flutter_test/flutter_test.dart';
import 'package:portal_platform/src/observability/portal_logger.dart';
import 'package:portal_platform/src/observability/portal_log_severity.dart';
import 'package:talker_flutter/talker_flutter.dart';

// Guards the one branch in PortalLogger._toTalker: ApiClient entries land in
// talker's http section (the debug panel's HTTP inspector), everything else by
// level. logToFile:false keeps path_provider out of the test.
void main() {
  test('ApiClient logs key into talker http; others by level', () async {
    final logger = await PortalLogger.init(
      sourceName: 'test',
      logToFile: false,
      logLevel: PortalLogSeverity.debug,
    );

    logger.info('ApiClient', 'Request completed', {
      'method': 'GET',
      'url': '/x',
      'status': 200,
    });
    logger.error('ApiClient', 'API request failed');
    logger.warn('SomeWidget', 'careful');

    final keys = logger.talker.history.map((e) => e.key).toList();
    expect(keys, contains(TalkerKey.httpRequest));
    expect(keys, contains(TalkerKey.httpError));
    // A non-ApiClient entry must not be mis-filed as http.
    expect(keys.where((k) => k == TalkerKey.httpRequest).length, 1);
  });
}
