import 'package:flutter_test/flutter_test.dart';
import 'package:portal_ai/src/chat/ai_speech_text.dart';

void main() {
  test('first chunk closes early on a comma, later ones need a sentence', () {
    final chunker = AiSpeechChunker();
    expect(chunker.add('Sure thing friend, '), ['Sure thing friend,']);
    expect(chunker.add("here is the plan for tonight's run. First, "), [
      "here is the plan for tonight's run.",
    ]);
    // "First," is a comma but no longer the first chunk; "First, warm up."
    // would close a sentence but is under the minimum, so it waits.
    expect(chunker.add('warm up. Then'), isEmpty);
    expect(chunker.add(' run for twenty minutes.'), [
      'First, warm up. Then run for twenty minutes.',
    ]);
    expect(chunker.flush(), isEmpty);
  });

  test('a decimal point does not split the sentence', () {
    final chunker = AiSpeechChunker();
    expect(chunker.add('Your pace was about 5.5 minutes per km. Nice.'), [
      'Your pace was about 5.5 minutes per km.',
    ]);
    expect(chunker.flush(), ['Nice.']);
  });

  test('markdown marks go, a fence becomes one notice across chunks', () {
    final chunker = AiSpeechChunker();
    final heard = [
      ...chunker.add('**Bold** and [a link](http://x). Then:\n```dart\n'),
      ...chunker.add('print(1);\n```\nDone now.'),
      ...chunker.flush(),
    ];
    // "Then:" alone is under the minimum, so it rides with the next chunk.
    expect(heard, ['Bold and a link.', 'Then: Code omitted. Done now.']);
  });
}
