import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../platform/portal_ai_voice.dart';
import 'ai_speech_text.dart';

/// What the voice conversation is doing, which is what the page draws.
enum AiVoicePhase { listening, thinking, speaking }

/// One voice conversation: hear, ask, read the reply aloud, hear again.
///
/// The microphone stays open the whole time, including while the reply is
/// being read. That is what lets the user talk over it -- a partial reading
/// that is not an echo of the reply stops the voice mid-sentence and becomes
/// the next question. Silence never ends the session; only [stop] does.
///
/// The page owns one of these and a [AiVoicePage] draws it. Nothing here
/// touches widgets: [ask] is the seam to the transcript, [onReplyDelta] the
/// seam from it.
class AiVoiceSession extends ChangeNotifier {
  AiVoiceSession({required this.ask, this.interrupt});

  /// Sends what was heard through the transcript and resolves with the
  /// finished reply, or null when nothing came back (failed, cancelled, a
  /// confirm card answered instead).
  final Future<String?> Function(String text) ask;

  /// Cancels the run in flight when the user talks over it, so a reply that
  /// will never be heard stops costing tokens.
  final VoidCallback? interrupt;

  AiVoicePhase phase = AiVoicePhase.listening;

  /// Microphone loudness, 0 to 1, as it changes; not on the notifier so the
  /// bars can redraw at frame rate without rebuilding the page.
  final level = ValueNotifier<double>(0);

  /// The recognizer's reading of the current question, refined as it goes.
  String heard = '';

  /// The reply as it streams, for the caption.
  String reply = '';

  String? error;

  bool get active => _active;
  bool _active = false;

  /// A question is being answered or read; finals heard now are dropped
  /// unless they are a barge-in during speech.
  bool _busy = false;
  bool _speaking = false;

  /// Bumped per question. A turn that was talked over finishes late, after
  /// the next one has started, and must not end that one on its way out.
  int _turnId = 0;

  final _speech = AiSpeechChunker();
  Future<bool>? _lastSpoken;
  StreamSubscription<AiHeard>? _hearing;

  /// Asks for the microphone and starts hearing. False when denied.
  Future<bool> start() async {
    if (_active) return true;
    if (!await PortalAiVoice.requestMicrophone()) return false;
    _active = true;
    error = null;
    heard = '';
    reply = '';
    phase = AiVoicePhase.listening;
    notifyListeners();
    _listen();
    return true;
  }

  void stop() {
    if (!_active) return;
    _active = false;
    _hearing?.cancel();
    _hearing = null;
    unawaited(PortalAiVoice.stopSpeaking());
    _speech.flush();
    _speaking = false;
    _busy = false;
    notifyListeners();
  }

  /// One streamed piece of the reply: captioned, and spoken once it makes
  /// a sentence.
  void onReplyDelta(String delta) {
    if (!_active || !_busy) return;
    reply += delta;
    _speech.add(delta).forEach(_say);
    notifyListeners();
  }

  /// Hears one utterance, then hears the next: the recognizer ends itself
  /// on silence, and the loop simply opens it again while the session is on.
  void _listen() {
    if (!_active) return;
    var closed = false;
    _hearing?.cancel();
    _hearing = PortalAiVoice.listen(onLevel: (l) => level.value = l).listen(
      (h) {
        if (h.text.trim().isEmpty) return;
        if (_busy) {
          // ponytail: echo test is "did the reply contain these words". A
          // device without echo cancellation feeds the voice's own reading
          // back through the microphone; that reading is always a substring
          // of the reply, so it never counts as the user talking over it.
          // Learn the speaker bleed level, as agent-platform does, if a
          // user's genuine "yes" keeps being swallowed because the reply
          // had one too.
          if (!_speaking || _isEcho(h.text)) return;
          _bargeIn();
        }
        heard = h.text;
        if (h.isFinal) {
          closed = true;
          unawaited(_turn(h.text));
        }
        notifyListeners();
      },
      onError: (Object e) {
        // The platform side writes its message for a person to read.
        error = e is PlatformException ? (e.message ?? e.code) : e.toString();
        stop();
      },
      onDone: () {
        // Silence, or a final that already moved on: either way keep hearing.
        if (_active && !closed) _listen();
      },
    );
  }

  bool _isEcho(String text) =>
      reply.toLowerCase().contains(text.trim().toLowerCase());

  void _bargeIn() {
    unawaited(PortalAiVoice.stopSpeaking());
    interrupt?.call();
    _speech.flush();
    _lastSpoken = null;
    _speaking = false;
    // Deltas still trickling from the interrupted run are dropped, and the
    // final reading of what the user said goes through as a new question.
    _busy = false;
    phase = AiVoicePhase.listening;
  }

  Future<void> _turn(String text) async {
    final id = ++_turnId;
    _busy = true;
    phase = AiVoicePhase.thinking;
    reply = '';
    _lastSpoken = null;
    notifyListeners();
    // The next utterance is heard while this one is answered.
    _listen();

    String? answer;
    try {
      answer = await ask(text);
    } catch (e) {
      error = e.toString();
    }
    if (!_active || id != _turnId) return;
    if (answer == null) {
      _endTurn();
      return;
    }
    final tail = _speech.flush();
    if (_lastSpoken == null && tail.isEmpty) {
      // Nothing streamed through onReplyDelta -- a host-driven page hands
      // back the finished reply only -- so it is captioned and read whole.
      reply = answer;
      final whole = AiSpeechChunker();
      [...whole.add(answer), ...whole.flush()].forEach(_say);
    } else {
      tail.forEach(_say);
    }
    notifyListeners();
    await (_lastSpoken ?? Future<bool>.value(false));
    if (!_active || id != _turnId) return;
    _endTurn();
  }

  void _endTurn() {
    _busy = false;
    _speaking = false;
    heard = '';
    phase = AiVoicePhase.listening;
    notifyListeners();
  }

  /// Queues one sentence behind whatever is already playing.
  void _say(String sentence) {
    if (!_busy) return;
    _lastSpoken = PortalAiVoice.speak(sentence);
    if (!_speaking) {
      _speaking = true;
      phase = AiVoicePhase.speaking;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    stop();
    level.dispose();
    super.dispose();
  }
}
