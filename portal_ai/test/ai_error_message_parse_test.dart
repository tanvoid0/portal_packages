import 'package:flutter_test/flutter_test.dart';
import 'package:portal_ai/portal_ai.dart';

/// Providers report a failure by pasting the upstream JSON body into the
/// exception message. What reaches the user has to be the sentence in it.
void main() {
  test('a provider JSON envelope is reduced to its message', () {
    const raw =
        'Gemini stream failed (503). {\n'
        '  "error": {\n'
        '    "code": 503,\n'
        '    "message": "This model is currently experiencing high demand.",\n'
        '    "status": "UNAVAILABLE"\n'
        '  }\n'
        '}';

    expect(
      aiErrorMessage(raw, offline: 'offline'),
      'This model is currently experiencing high demand.',
    );
  });

  test('an unparseable body still loses the blob', () {
    expect(
      aiErrorMessage('Gemini stream failed (503). {not json', offline: 'off'),
      'Gemini stream failed (503).',
    );
  });

  test('a plain message is left alone', () {
    expect(aiErrorMessage('Quota exceeded', offline: 'off'), 'Quota exceeded');
  });

  test("the API client's own offline wording is recognised", () {
    const raw =
        'ApiException: No connection to the server. (status: 0) '
        '[NETWORK_UNREACHABLE] (traceId: 4a0)';

    expect(aiErrorMessage(raw, offline: 'You are offline'), 'You are offline');
    expect(isAiOfflineError(raw), isTrue);
  });
}
