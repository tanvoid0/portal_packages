import 'dart:convert';

import '../clients/ai_completion_client.dart';

/// Uploads a file to the app's API and returns the decoded response.
///
/// Matches `ApiClient.postMultipart` in portal_platform, so apps pass that
/// directly and document reads inherit their auth, retries and session
/// handling — the same deal [AiPostJson] gets for completions.
typedef AiPostMultipart =
    Future<dynamic> Function(
      String path, {
      required String fieldName,
      required List<int> fileBytes,
      required String filename,
      Map<String, String>? fields,
    });

/// A document read back as plain text.
class AiDocumentText {
  const AiDocumentText({required this.text, required this.source});

  final String text;

  /// `decoded` when the file was already text, `vision` when a model read it.
  final String source;
}

/// Turns an uploaded PDF, image or text file into plain text, server-side.
///
/// The server stops at the text on purpose: what a contract or a statement
/// *means* is the caller's prompt, so one route serves every app. Feed the
/// text to whichever [AiCompletionClient] the user has configured, or to
/// [extractJson] for the common "read this into a structured shape" case.
///
/// Server route: `POST /ai/extract-text` (multipart) -> `{ text, source }`.
class AiDocumentClient {
  const AiDocumentClient({
    required this.postMultipart,
    this.path = '/ai/extract-text',
    this.feature = 'document-extract',
  });

  final AiPostMultipart postMultipart;
  final String path;

  /// Groups server-side usage stats. Lowercase, digits and dashes only.
  final String feature;

  Future<AiDocumentText> extractText({
    required List<int> bytes,
    required String filename,
  }) async {
    final dynamic response = await postMultipart(
      path,
      fieldName: 'file',
      fileBytes: bytes,
      filename: filename,
      fields: <String, String>{'feature': feature},
    );

    final text = response is Map ? response['text'] as String? : null;
    if (text == null || text.trim().isEmpty) {
      throw const AiCompletionException('No readable text in that document');
    }
    return AiDocumentText(
      text: text,
      source: (response as Map)['source'] as String? ?? 'decoded',
    );
  }

  /// Reads a document, then asks [client] to turn it into JSON.
  ///
  /// [instruction] says what to pull out and in what shape — that prompt is
  /// the whole app-specific part, which is why it lives with the caller and
  /// not here. Throws [AiCompletionException] if the reply is not JSON.
  ///
  /// Long documents go through the model in pieces: the server caps a prompt
  /// at 16k characters and a bank statement's text is routinely three times
  /// that. The text is cut at line breaks, each piece is read on its own, and
  /// the replies are merged with [mergeJson] — a list of rows in every piece
  /// becomes one list.
  Future<dynamic> extractJson({
    required AiCompletionClient client,
    required List<int> bytes,
    required String filename,
    required String instruction,
    int maxChunkChars = maxPromptChars,
  }) async {
    final document = await extractText(bytes: bytes, filename: filename);
    final results = <dynamic>[];
    for (final chunk in splitText(document.text, maxChunkChars)) {
      final reply = await client.complete(
        systemPrompt: instruction,
        userPrompt: chunk,
        jsonMode: true,
      );
      results.add(decodeJsonReply(reply));
    }
    return mergeJson(results);
  }

  /// The server's `AiCompleteDto.prompt` limit, with room for the line the
  /// split lands on.
  static const int maxPromptChars = 15000;

  /// Cuts [text] into pieces of at most [max] characters, breaking at the
  /// last newline before the limit so a statement line is never torn in two.
  /// A single line longer than [max] is cut mid-line rather than dropped.
  static List<String> splitText(String text, int max) {
    if (text.length <= max) return <String>[text];
    final chunks = <String>[];
    var start = 0;
    while (start < text.length) {
      var end = start + max;
      if (end >= text.length) {
        end = text.length;
      } else {
        final cut = text.lastIndexOf('\n', end);
        if (cut > start) end = cut + 1;
      }
      chunks.add(text.substring(start, end));
      start = end;
    }
    return chunks;
  }

  /// Folds per-chunk replies into the shape one reply would have had: lists
  /// concatenate, maps merge key by key (list values concatenate, scalars keep
  /// the first non-null value seen), a lone reply comes back untouched.
  static dynamic mergeJson(List<dynamic> parts) {
    if (parts.length == 1) return parts.single;
    if (parts.every((p) => p is List)) {
      return parts.expand((p) => p as List).toList();
    }
    final merged = <String, dynamic>{};
    for (final part in parts) {
      if (part is! Map) continue;
      for (final entry in part.entries) {
        final key = entry.key as String;
        final existing = merged[key];
        if (entry.value is List) {
          merged[key] = <dynamic>[
            ...?(existing as List?),
            ...entry.value as List,
          ];
        } else {
          merged[key] ??= entry.value;
        }
      }
    }
    return merged;
  }

  /// Parses a model's JSON reply, tolerating the ```json fence some models
  /// add even in JSON mode.
  static dynamic decodeJsonReply(String reply) {
    var body = reply.trim();
    if (body.startsWith('```')) {
      body = body.replaceFirst(RegExp(r'^```[a-zA-Z]*\s*'), '');
      final fence = body.lastIndexOf('```');
      if (fence != -1) body = body.substring(0, fence);
      body = body.trim();
    }
    try {
      return jsonDecode(body);
    } on FormatException {
      throw AiCompletionException(
        'The assistant did not return usable data: ${body.length > 120 ? '${body.substring(0, 120)}...' : body}',
      );
    }
  }
}
