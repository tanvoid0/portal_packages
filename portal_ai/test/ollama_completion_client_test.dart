import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:portal_ai/portal_ai.dart';

void main() {
  group('completeStream', () {
    test('an NDJSON line split across two network reads is not dropped', () async {
      // One line, cut mid-line -- a real socket read has no idea where the
      // JSON ends, so a per-chunk split (rather than per-line) drops
      // whichever half lands in the second read.
      final full =
          '${jsonEncode({
            'message': {'content': 'hello world'},
          })}\n';
      final cut = full.length ~/ 2;
      final client = OllamaCompletionClient(
        baseUrl: 'http://localhost:11434',
        model: 'gemma3',
        client: MockClient.streaming((request, bodyStream) async {
          return http.StreamedResponse(
            Stream.fromIterable([
              utf8.encode(full.substring(0, cut)),
              utf8.encode(full.substring(cut)),
            ]),
            200,
          );
        }),
      );

      final text = await client
          .completeStream(systemPrompt: 'sys', userPrompt: 'hi')
          .join();

      expect(text, 'hello world');
    });
  });
}
