import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portal_ai/src/chat/ai_voice_session.dart';

/// Fakes the platform side: the microphone stream is driven by hand and
/// every `speak` completes when the test says so.
class _Voice {
  _Voice() {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(
      const MethodChannel('portal_ai/platform'),
      (call) async {
        calls.add(call.method);
        switch (call.method) {
          case 'requestMicrophone':
            return micGranted;
          case 'speak':
            final c = Completer<bool>();
            spoken.add((call.arguments as Map)['text'] as String);
            speaking.add(c);
            return c.future;
          default:
            return null;
        }
      },
    );
    messenger.setMockStreamHandler(
      const EventChannel('portal_ai/listen'),
      MockStreamHandler.inline(
        onListen: (_, sink) {
          listens++;
          this.sink = sink;
        },
        onCancel: (_) => sink = null,
      ),
    );
  }

  bool micGranted = true;
  final calls = <String>[];
  final spoken = <String>[];
  final speaking = <Completer<bool>>[];
  MockStreamHandlerEventSink? sink;
  int listens = 0;

  Future<void> hear(String text, {bool isFinal = true}) async {
    sink!.success({'text': text, 'final': isFinal});
    await Future<void>.delayed(Duration.zero);
  }

  Future<void> finishSpeaking() async {
    for (final c in speaking) {
      if (!c.isCompleted) c.complete(true);
    }
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _Voice voice;
  setUp(() => voice = _Voice());

  test('a denied microphone leaves the session inactive', () async {
    voice.micGranted = false;
    final session = AiVoiceSession(ask: (_) async => null);
    expect(await session.start(), isFalse);
    expect(session.active, isFalse);
    expect(voice.listens, 0);
  });

  test('hear, ask, read aloud, then listen again', () async {
    final asked = <String>[];
    late AiVoiceSession session;
    session = AiVoiceSession(
      ask: (text) async {
        asked.add(text);
        session.onReplyDelta('Hello there, friend. ');
        session.onReplyDelta('How are you doing today?');
        return 'Hello there, friend. How are you doing today?';
      },
    );
    expect(await session.start(), isTrue);
    expect(session.phase, AiVoicePhase.listening);

    await voice.hear('hi', isFinal: false);
    expect(session.heard, 'hi');
    await voice.hear('hi there');
    expect(asked, ['hi there']);
    expect(session.phase, AiVoicePhase.speaking);
    expect(session.reply, 'Hello there, friend. How are you doing today?');
    expect(voice.spoken.join(' '), contains('How are you doing today?'));
    // The microphone reopened for the next question while this one plays.
    expect(voice.listens, 2);

    await voice.finishSpeaking();
    expect(session.phase, AiVoicePhase.listening);
    expect(session.heard, '');
    session.dispose();
  });

  test('a reply handed back whole is still read aloud', () async {
    final session = AiVoiceSession(ask: (_) async => 'Forty two, as always.');
    await session.start();
    await voice.hear('answer');
    expect(session.reply, 'Forty two, as always.');
    expect(voice.spoken, isNotEmpty);
    session.dispose();
  });

  test('the voice hearing itself is not the user talking over it', () async {
    var interrupted = 0;
    final asked = <String>[];
    late AiVoiceSession session;
    session = AiVoiceSession(
      interrupt: () => interrupted++,
      ask: (text) async {
        asked.add(text);
        session.onReplyDelta('Your pace was about five minutes per km.');
        return 'Your pace was about five minutes per km.';
      },
    );
    await session.start();
    await voice.hear('how fast');
    expect(session.phase, AiVoicePhase.speaking);

    await voice.hear('about five minutes per km');
    expect(interrupted, 0);
    expect(asked, ['how fast']);
    expect(session.phase, AiVoicePhase.speaking);
    session.dispose();
  });

  test('talking over the reply stops it and asks the new question', () async {
    var interrupted = 0;
    final asked = <String>[];
    final firstAnswer = Completer<String?>();
    late AiVoiceSession session;
    session = AiVoiceSession(
      interrupt: () => interrupted++,
      ask: (text) async {
        asked.add(text);
        if (asked.length == 1) {
          session.onReplyDelta('Here is a very long reply that keeps going. ');
          return firstAnswer.future;
        }
        return 'Second answer done.';
      },
    );
    await session.start();
    await voice.hear('first');
    expect(session.phase, AiVoicePhase.speaking);
    final spokenBefore = voice.spoken.length;

    await voice.hear('actually never mind');
    expect(interrupted, 1);
    expect(voice.calls, contains('stopSpeaking'));
    expect(asked, ['first', 'actually never mind']);
    expect(session.reply, 'Second answer done.');

    // The talked-over turn finishing late must not end the live one.
    firstAnswer.complete('stale');
    await Future<void>.delayed(Duration.zero);
    expect(session.reply, 'Second answer done.');
    expect(session.phase, AiVoicePhase.speaking);
    expect(voice.spoken.length, greaterThan(spokenBefore));

    await voice.finishSpeaking();
    expect(session.phase, AiVoicePhase.listening);
    session.dispose();
  });

  test('a final heard while thinking is dropped', () async {
    final asked = <String>[];
    final answer = Completer<String?>();
    final session = AiVoiceSession(
      ask: (text) async {
        asked.add(text);
        return answer.future;
      },
    );
    await session.start();
    await voice.hear('one');
    expect(session.phase, AiVoicePhase.thinking);
    await voice.hear('two');
    expect(asked, ['one']);
    answer.complete(null);
    await Future<void>.delayed(Duration.zero);
    expect(session.phase, AiVoicePhase.listening);
    session.dispose();
  });

  test('a recognizer error stops the session and is reported', () async {
    final session = AiVoiceSession(ask: (_) async => null);
    await session.start();
    voice.sink!.error(code: 'mic', message: 'lost');
    await Future<void>.delayed(Duration.zero);
    expect(session.active, isFalse);
    expect(session.error, contains('lost'));
    session.dispose();
  });

  test('silence reopens the microphone; stop does not', () async {
    final session = AiVoiceSession(ask: (_) async => null);
    await session.start();
    expect(voice.listens, 1);
    voice.sink!.endOfStream();
    await Future<void>.delayed(Duration.zero);
    expect(voice.listens, 2);

    session.stop();
    voice.sink?.endOfStream();
    await Future<void>.delayed(Duration.zero);
    expect(voice.listens, 2);
    expect(voice.calls, contains('stopSpeaking'));
    session.dispose();
  });
}
