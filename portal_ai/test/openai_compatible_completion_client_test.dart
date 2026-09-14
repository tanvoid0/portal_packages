import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:portal_ai/portal_ai.dart';

void main() {
  group('complete', () {
    test('posts the OpenAI shape, with a key, and parses the reply', () async {
      http.Request? seen;
      final client = OpenAiCompatibleCompletionClient(
        baseUrl: 'https://api.example.com/v1',
        model: 'gpt-test',
        apiKey: 'sk-secret',
        httpClient: MockClient((request) async {
          seen = request;
          return http.Response(
            jsonEncode({
              'model': 'gpt-test',
              'choices': [
                {
                  'message': {'role': 'assistant', 'content': 'hi there'},
                },
              ],
              'usage': {'prompt_tokens': 5, 'completion_tokens': 2},
            }),
            200,
          );
        }),
      );

      final reply = await client.complete(
        systemPrompt: 'be nice',
        userPrompt: 'hello',
      );

      expect(reply, 'hi there');
      expect(seen!.url.toString(), 'https://api.example.com/v1/chat/completions');
      expect(seen!.headers['Authorization'], 'Bearer sk-secret');
      final body = jsonDecode(seen!.body) as Map;
      expect(body['model'], 'gpt-test');
      expect(body['stream'], isFalse);
      expect(body['messages'], [
        {'role': 'system', 'content': 'be nice'},
        {'role': 'user', 'content': 'hello'},
      ]);
      expect(body.containsKey('response_format'), isFalse);
      expect(client.lastStats?.promptTokens, 5);
      expect(client.lastStats?.replyTokens, 2);
    });

    test('omits the system message and the Authorization header when empty', () async {
      http.Request? seen;
      final client = OpenAiCompatibleCompletionClient(
        baseUrl: 'http://localhost:1234/v1',
        model: 'local-model',
        httpClient: MockClient((request) async {
          seen = request;
          return http.Response(
            jsonEncode({
              'choices': [
                {
                  'message': {'content': 'ok'},
                },
              ],
            }),
            200,
          );
        }),
      );

      await client.complete(systemPrompt: '', userPrompt: 'hi');

      expect(seen!.headers.containsKey('Authorization'), isFalse);
      final body = jsonDecode(seen!.body) as Map;
      expect(body['messages'], [
        {'role': 'user', 'content': 'hi'},
      ]);
    });

    test('jsonMode asks for a JSON object response', () async {
      Map<String, dynamic>? sentBody;
      final client = OpenAiCompatibleCompletionClient(
        baseUrl: 'https://api.example.com/v1',
        model: 'gpt-test',
        httpClient: MockClient((request) async {
          sentBody = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response(
            jsonEncode({
              'choices': [
                {
                  'message': {'content': '{}'},
                },
              ],
            }),
            200,
          );
        }),
      );

      await client.complete(
        systemPrompt: 'sys',
        userPrompt: 'hi',
        jsonMode: true,
      );

      expect(sentBody!['response_format'], {'type': 'json_object'});
    });

    test('a non-2xx surfaces the provider\'s own error message', () async {
      final client = OpenAiCompatibleCompletionClient(
        baseUrl: 'https://api.example.com/v1',
        model: 'gpt-test',
        httpClient: MockClient(
          (_) async => http.Response(
            jsonEncode({
              'error': {'message': 'Invalid API key'},
            }),
            401,
          ),
        ),
      );

      await expectLater(
        client.complete(systemPrompt: 'sys', userPrompt: 'hi'),
        throwsA(
          isA<AiCompletionException>().having(
            (e) => e.message,
            'message',
            'Invalid API key',
          ),
        ),
      );
    });

    test('a non-JSON error body falls back to a status line', () async {
      final client = OpenAiCompatibleCompletionClient(
        baseUrl: 'https://api.example.com/v1',
        model: 'gpt-test',
        httpClient: MockClient((_) async => http.Response('boom', 500)),
      );

      await expectLater(
        client.complete(systemPrompt: 'sys', userPrompt: 'hi'),
        throwsA(
          isA<AiCompletionException>().having(
            (e) => e.message,
            'message',
            'HTTP 500',
          ),
        ),
      );
    });
  });

  group('completeStream', () {
    test('yields deltas and stops at [DONE]', () async {
      final client = OpenAiCompatibleCompletionClient(
        baseUrl: 'https://api.example.com/v1',
        model: 'gpt-test',
        httpClient: MockClient((_) async {
          final frames = [
            'data: ${jsonEncode({
              'choices': [
                {
                  'delta': {'content': 'one '},
                },
              ],
            })}',
            'data: ${jsonEncode({
              'choices': [
                {
                  'delta': {'content': 'two'},
                },
              ],
            })}',
            'data: [DONE]',
          ].join('\n\n');
          return http.Response(frames, 200);
        }),
      );

      final text = await client
          .completeStream(systemPrompt: 'sys', userPrompt: 'hi')
          .join();

      expect(text, 'one two');
    });

    test('a data: line split across two network reads is not dropped', () async {
      // One SSE frame, cut mid-line -- not at a frame boundary -- the way a
      // real socket read has no idea where the JSON ends.
      final full = 'data: ${jsonEncode({
        'choices': [
          {
            'delta': {'content': 'hello world'},
          },
        ],
      })}\n\n';
      final cut = full.length ~/ 2;
      final client = OpenAiCompatibleCompletionClient(
        baseUrl: 'https://api.example.com/v1',
        model: 'gpt-test',
        httpClient: MockClient.streaming((request, bodyStream) async {
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

    test('an error frame throws', () {
      final client = OpenAiCompatibleCompletionClient(
        baseUrl: 'https://api.example.com/v1',
        model: 'gpt-test',
        httpClient: MockClient((_) async {
          final frame = jsonEncode({
            'error': {'message': 'overloaded'},
          });
          return http.Response('data: $frame', 200);
        }),
      );

      expect(
        client.completeStream(systemPrompt: 'sys', userPrompt: 'hi'),
        emitsError(isA<AiCompletionException>()),
      );
    });
  });

  group('isAvailable', () {
    test('true on a 2xx from /models', () async {
      final client = OpenAiCompatibleCompletionClient(
        baseUrl: 'https://api.example.com/v1',
        model: 'gpt-test',
        httpClient: MockClient((_) async => http.Response('{}', 200)),
      );

      expect(await client.isAvailable(), isTrue);
    });

    test('false on a non-2xx or a thrown error', () async {
      final failing = OpenAiCompatibleCompletionClient(
        baseUrl: 'https://api.example.com/v1',
        model: 'gpt-test',
        httpClient: MockClient((_) async => http.Response('', 500)),
      );
      expect(await failing.isAvailable(), isFalse);

      final offline = OpenAiCompatibleCompletionClient(
        baseUrl: 'https://api.example.com/v1',
        model: 'gpt-test',
        httpClient: MockClient((_) async => throw Exception('offline')),
      );
      expect(await offline.isAvailable(), isFalse);
    });
  });
}
