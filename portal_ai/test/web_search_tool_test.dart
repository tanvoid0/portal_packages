import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:portal_ai/portal_ai.dart';
import 'package:shared_preferences/shared_preferences.dart';

http.Client _serving(String body, {int status = 200}) =>
    MockClient((_) async => http.Response(body, status));

Future<String> _search(http.Client client, {String query = 'chicken tikka'}) =>
    webSearchTool(
      apiKey: 'k',
      httpClient: client,
    ).call(AiToolCall('web_search', {'query': query})).then((r) => r.forModel);

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  test('formats results as title, url and a trimmed extract', () async {
    final result = await _search(
      _serving(
        jsonEncode({
          'results': [
            {
              'title': 'Chicken Tikka',
              'url': 'https://example.com/tikka',
              'content': 'x' * 900,
            },
          ],
        }),
      ),
    );

    expect(result, contains('Chicken Tikka'));
    expect(result, contains('https://example.com/tikka'));
    expect(result, endsWith('...'));
    expect(result.length, lessThan(600));
  });

  test('says so rather than throwing when the search fails', () async {
    expect(await _search(_serving('nope', status: 500)), contains('500'));
    expect(
      await _search(_serving(jsonEncode({'results': []}))),
      contains('no results'),
    );
    expect(
      await _search(MockClient((_) async => throw const _Offline())),
      contains('search failed'),
    );
  });

  test('answers a repeated query without asking the network again', () async {
    var requests = 0;
    final client = MockClient((_) async {
      requests++;
      return http.Response(
        jsonEncode({
          'results': [
            {'title': 'Tikka', 'url': 'https://e.com', 'content': 'yoghurt'},
          ],
        }),
        200,
      );
    });
    final tool = webSearchTool(apiKey: 'k', httpClient: client);

    Future<String> ask(String q) => tool
        .call(AiToolCall('web_search', {'query': q}))
        .then((r) => r.forModel);

    expect(await ask('chicken tikka'), contains('yoghurt'));
    expect(await ask('Chicken Tikka'), contains('yoghurt'));
    expect(requests, 1);
  });

  test('stops at the daily budget, counting failures too', () async {
    var requests = 0;
    final client = MockClient((_) async {
      requests++;
      return http.Response('boom', 500);
    });
    final tool = webSearchTool(apiKey: 'k', httpClient: client, dailyLimit: 2);

    // Distinct queries, so nothing is served from the cache.
    final replies = [
      for (var i = 0; i < 4; i++)
        await tool
            .call(AiToolCall('web_search', {'query': 'query number $i'}))
            .then((r) => r.forModel),
    ];

    expect(requests, 2);
    expect(replies.take(2), everyElement(contains('500')));
    expect(replies.skip(2), everyElement(contains('budget for today')));
  });

  test('a new day refills the budget', () async {
    SharedPreferences.setMockInitialValues({
      'ai_search_day': '2000-01-01',
      'ai_search_count': 99,
    });
    expect(
      await _search(_serving(jsonEncode({'results': []}))),
      contains('no results'),
    );
  });

  test('is registered only when a key is configured', () {
    List<String> toolsWith(Map<String, String> env) => PortalAiRuntime.create(
      post: (path, {body}) async => <String, dynamic>{},
      env: env,
    ).tools.map((t) => t.name).toList();

    expect(toolsWith(const {}), isNot(contains('web_search')));
    expect(
      toolsWith(const {'AI_TAVILY_KEY': ' '}),
      isNot(contains('web_search')),
    );
    expect(toolsWith(const {'AI_TAVILY_KEY': 'k'}), contains('web_search'));
  });
}

class _Offline implements Exception {
  const _Offline();
}
