import 'dart:async';
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
  return text.isEmpty ? offline : text;
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
      text.contains('software caused connection abort') ||
      text.contains('xmlhttprequest error') ||
      text.contains('clientexception');
}
