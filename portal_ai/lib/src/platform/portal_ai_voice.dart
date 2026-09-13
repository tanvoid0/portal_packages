import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Whether the device can hear and speak without a server.
///
/// Both halves are checked natively: recognition through Android's on-device
/// recognizer (API 31+), synthesis through a TTS voice that reports no network
/// requirement. Anything else -- older Android, web, a device whose only
/// voices are cloud-backed -- is [none], and the page draws no microphone.
class AiVoiceCapability {
  const AiVoiceCapability({required this.canListen, required this.canSpeak});

  static const none = AiVoiceCapability(canListen: false, canSpeak: false);

  final bool canListen;
  final bool canSpeak;

  /// A conversation needs both directions.
  bool get isAvailable => canListen && canSpeak;
}

/// One thing heard. [text] is refined as the recognizer goes; the last event
/// of a listen carries [isFinal].
typedef AiHeard = ({String text, bool isFinal});

/// On-device speech in and out. Android only; every other platform answers
/// [AiVoiceCapability.none] and nothing else here is ever called.
abstract final class PortalAiVoice {
  static const _channel = MethodChannel('portal_ai/platform');
  static const _listen = EventChannel('portal_ai/listen');

  static Future<AiVoiceCapability> describe() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return AiVoiceCapability.none;
    }
    try {
      await _applyRate(await rate());
      final map = await _channel.invokeMapMethod<Object?, Object?>(
        'describeVoice',
      );
      return AiVoiceCapability(
        canListen: map?['stt'] == true,
        canSpeak: map?['tts'] == true,
      );
    } on MissingPluginException {
      return AiVoiceCapability.none;
    } on PlatformException {
      return AiVoiceCapability.none;
    }
  }

  /// Asks for the microphone. True when granted, or already was.
  static Future<bool> requestMicrophone() async {
    try {
      return await _channel.invokeMethod<bool>('requestMicrophone') ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// Hears one utterance. Ends after the final event, or after silence with
  /// no final event at all. Cancel the subscription to stop early.
  /// [onLevel] gets the microphone's loudness, 0 to 1, as it changes.
  static Stream<AiHeard> listen({
    String? locale,
    void Function(double level)? onLevel,
  }) => _listen
      .receiveBroadcastStream({'locale': ?locale})
      .map((event) => event as Map)
      .where((map) {
        if (map['level'] case final num level) {
          onLevel?.call(level.toDouble());
          return false;
        }
        return true;
      })
      .map(
        (map) => (
          text: map['text'] as String? ?? '',
          isFinal: map['final'] == true,
        ),
      );

  /// Reads [text] aloud after whatever is already queued, or in place of
  /// it with [flush]. Completes once this chunk has been spoken: a streaming
  /// reply queues each sentence as it arrives and awaits only the last.
  /// False when stopped or the engine refused it.
  static Future<bool> speak(String text, {bool flush = false}) async {
    try {
      return await _channel.invokeMethod<bool>('speak', {
            'text': text,
            'flush': flush,
          }) ??
          false;
    } on PlatformException {
      return false;
    }
  }

  static const _rateKey = 'portal_ai_voice_rate';

  /// Speed as a multiple of the voice's normal, 0.5 to 2. Persisted, and
  /// applied to the engine on the next [describe] or [setRate].
  static Future<double> rate() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_rateKey) ?? 1.0;
  }

  static Future<void> setRate(double value) async {
    final rate = value.clamp(0.5, 2.0).toDouble();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_rateKey, rate);
    await _applyRate(rate);
  }

  static Future<void> _applyRate(double rate) async {
    try {
      await _channel.invokeMethod<void>('setVoiceRate', {'rate': rate});
    } on MissingPluginException {
      // Not Android.
    } on PlatformException {
      // The engine keeps its old speed.
    }
  }

  static Future<void> stopSpeaking() async {
    try {
      await _channel.invokeMethod<void>('stopSpeaking');
    } on PlatformException {
      // Already quiet.
    }
  }
}
