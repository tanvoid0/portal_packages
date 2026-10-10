import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:portal_ai/portal_ai.dart';

void main() {
  group('OllamaModelManager', () {
    test('lists the tags the daemon reports', () async {
      final manager = OllamaModelManager(
        baseUrl: 'http://host:11434/',
        client: MockClient((request) async {
          expect(request.url.path, '/api/tags');
          return http.Response(
            jsonEncode({
              'models': [
                {'name': 'qwen3:1.7b'},
                {'name': 'llama3.2:3b'},
              ],
            }),
            200,
          );
        }),
      );

      expect(await manager.installed(), ['qwen3:1.7b', 'llama3.2:3b']);
    });

    test('the catalog hides what is already pulled', () async {
      final manager = OllamaModelManager(
        baseUrl: 'http://host:11434',
        client: MockClient(
          (_) async => http.Response(
            jsonEncode({
              'models': [
                {'name': 'qwen3:1.7b'},
              ],
            }),
            200,
          ),
        ),
      );

      final ids = (await manager.catalog()).map((m) => m.id);
      expect(ids, isNot(contains('qwen3:1.7b')));
      expect(ids, contains('llama3.2:3b'));
    });

    test('pull reports a fraction per layer and ignores status-only lines',
        () async {
      final manager = OllamaModelManager(
        baseUrl: 'http://host:11434',
        client: MockClient.streaming((request, _) async {
          expect(request.url.path, '/api/pull');
          final lines = [
            '{"status":"pulling manifest"}',
            '{"status":"downloading","completed":50,"total":200}',
            '',
            'not json at all',
            '{"status":"downloading","completed":200,"total":200}',
            '{"status":"success"}',
          ].join('\n');
          return http.StreamedResponse(
            Stream.value(utf8.encode(lines)),
            200,
          );
        }),
      );

      expect(await manager.install('qwen3:1.7b').toList(), [0.25, 1.0]);
    });

    test('an error line in the stream fails the pull', () async {
      final manager = OllamaModelManager(
        baseUrl: 'http://host:11434',
        client: MockClient.streaming(
          (_, _) async => http.StreamedResponse(
            Stream.value(utf8.encode('{"error":"model not found"}')),
            200,
          ),
        ),
      );

      expect(
        manager.install('nope:1b'),
        emitsError(isA<AiModelManagerException>()),
      );
    });

    test('a refused pull says so rather than completing silently', () async {
      final manager = OllamaModelManager(
        baseUrl: 'http://host:11434',
        client: MockClient.streaming(
          (_, _) async =>
              http.StreamedResponse(const Stream.empty(), 500),
        ),
      );

      expect(
        manager.install('qwen3:1.7b'),
        emitsError(isA<AiModelManagerException>()),
      );
    });
  });
}
