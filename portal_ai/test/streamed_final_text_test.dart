import 'package:flutter_test/flutter_test.dart';
import 'package:portal_ai/portal_ai.dart';

/// Feeds a whole reply in one-character chunks, collecting what came out.
String _drip(String json) {
  final stream = StreamedFinalText();
  final out = StringBuffer();
  for (final char in json.split('')) {
    out.write(stream.add(char));
  }
  return out.toString();
}

void main() {
  test('emits the final string as it arrives, once each', () {
    final stream = StreamedFinalText();

    expect(stream.add('{"fin'), '');
    expect(stream.add('al": "Hello'), 'Hello');
    expect(stream.add(' there'), ' there');
    expect(stream.add('"}'), '');
    expect(stream.text, 'Hello there');
  });

  test('a tool call never emits', () {
    expect(_drip('{"tool": "add_item", "args": {"name": "milk"}}'), '');
  });

  test('escapes decode, including one split across chunks', () {
    final stream = StreamedFinalText();
    stream.add(r'{"final": "line one\');
    // The backslash alone must not print; the pair does.
    expect(stream.text, 'line one');
    expect(stream.add('nline two'), '\nline two');

    expect(_drip(r'{"final": "say \"hi\" \\ here"}'), r'say "hi" \ here');
    expect(_drip(r'{"final": "café"}'), 'café');
  });

  test('leading keys and whitespace do not confuse it', () {
    expect(
      _drip('{\n  "thinking": "ignored",\n  "final" :   "answer"\n}'),
      'answer',
    );
  });
}
