import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// What to put on screen when a run fails.
///
/// A dropped connection and a model that refused used to read the same:
/// `ClientException: Failed host lookup`, printed raw under the composer. The
/// two need different reactions from the user -- one is "try again in a
/// minute", the other is "ask differently" -- so they get different sentences.
///
/// [offline] is the copy for a connection failure, so the host keeps control
/// of the wording. Anything unrecognised falls through to the error's own
/// message: an unhelpful message is still better than a wrong diagnosis.
String aiErrorMessage(Object error, {required String offline}) {
  if (isAiOfflineError(error)) return offline;
  final text = error.toString().trim();
  return text.isEmpty ? offline : _sentenceIn(text);
}

/// The readable sentence inside a provider's error, or [text] unchanged.
///
/// Both transports report a failure by pasting the upstream JSON body into
/// the exception's message, so a busy model reached the user as eleven lines
/// of `{"error": {"code": 503, ...}}` under the composer. The body's own
/// `message` is a sentence written for a human -- "This model is currently
/// experiencing high demand" -- so that is what gets shown.
String _sentenceIn(String text) {
  final start = text.indexOf('{');
  if (start < 0) return text;
  final envelope = text.substring(0, start).trim();
  try {
    final decoded = jsonDecode(text.substring(start));
    if (decoded is Map) {
      final error = decoded['error'];
      final message = error is Map ? error['message'] : decoded['message'];
      if (message is String && message.trim().isNotEmpty) {
        return message.trim();
      }
    }
  } on FormatException {
    // Not JSON after all -- a message that merely contains a brace. The
    // envelope is still the readable half.
  }
  return envelope.isEmpty ? text : envelope;
}

/// Whether [error] is the network being unavailable rather than the model
/// having something to say.
///
/// Matches on type where the platform gives one, and on the handful of
/// phrases `http` puts in a `ClientException` where it does not (the web build
/// has no [SocketException] at all).
bool isAiOfflineError(Object error) {
  if (error is SocketException || error is TimeoutException) return true;
  final text = error.toString().toLowerCase();
  return text.contains('failed host lookup') ||
      text.contains('connection refused') ||
      text.contains('connection closed') ||
      text.contains('connection reset') ||
      text.contains('network is unreachable') ||
      // The Portal API client's own wording for the same thing, which does
      // not match any of the phrases `http` uses.
      text.contains('network_unreachable') ||
      text.contains('no connection to the server') ||
      text.contains('software caused connection abort') ||
      text.contains('xmlhttprequest error') ||
      text.contains('clientexception');
}
