import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'ai_tool.dart';

/// Env key that turns web search on.
abstract final class AiSearchEnvKeys {
  /// A Tavily API key. Absent means the assistant simply has no search tool.
  static const tavilyKey = 'AI_TAVILY_KEY';
}

/// How much of one result's extract reaches the model.
///
/// Search text is the largest thing that ever lands in the transcript, and a
/// local 7B has a few thousand tokens of room in total -- three full pages
/// would push the user's actual request out of the window.
const _extractChars = 400;

/// Searches allowed per day, across every app on this device.
///
/// A free Tavily plan is 1000 a month. What spends that is not a user asking
/// questions -- it is an agent that decides searching is the answer and runs
/// the same query every step of a loop, at machine speed, unattended. Well
/// under the monthly rate, so one bad day cannot burn the month.
const _dailyLimit = 25;

/// Repeat queries answer from memory instead of the network.
const _cacheEntries = 20;

const _dayKey = 'ai_search_day';
const _countKey = 'ai_search_count';

/// Takes one search out of today's budget, or returns false when it is spent.
///
/// Counted before the request rather than after, so a failing search still
/// costs: a retry loop against a broken endpoint is exactly the runaway this
/// exists to stop.
Future<bool> _spendOne(int limit) async {
  final prefs = await SharedPreferences.getInstance();
  final today = DateTime.now().toIso8601String().substring(0, 10);
  if (prefs.getString(_dayKey) != today) {
    await prefs.setString(_dayKey, today);
    await prefs.setInt(_countKey, 0);
  }
  final used = prefs.getInt(_countKey) ?? 0;
  if (used >= limit) return false;
  await prefs.setInt(_countKey, used + 1);
  return true;
}

/// Looks facts up on the web, for the things a model cannot know: prices,
/// opening times, anything that happened after it was trained.
///
/// Backed by Tavily, which does the searching and the page extraction and
/// returns plain text — the alternative is fetching result pages here and
/// stripping HTML in Dart, which is a scraper to maintain forever.
///
/// The result is untrusted text written by strangers. It reaches the model
/// inside the agent's BEGIN/END TOOL RESULTS fence, which already tells it
/// that region is data and never instructions; nothing here should hand back
/// anything that escapes that fence.
AiTool webSearchTool({
  required String apiKey,
  http.Client? httpClient,
  int maxResults = 3,
  int dailyLimit = _dailyLimit,
}) {
  // ponytail: one counter for the whole device, and a cache that dies with the
  // process. Both per-device on purpose -- the quota is spent per device too.
  // Move the budget server-side along with the key.
  final cache = <String, String>{};
  return AiTool(
    name: 'web_search',
    description:
        'Look something up on the web. For facts you cannot know: '
        'current prices, news, opening times. Not for general knowledge you '
        'already have, and not for the user\'s own saved data.',
    parameters: const {'query': 'what to search for (required)'},
    run: (call) async {
      final query = call.argString('query');
      if (query == null) throw ArgumentError('query is required');

      // An agent asking the same thing twice in one run is the common case,
      // not the exception: it searches, misreads the answer, searches again.
      final cached = cache[query.toLowerCase()];
      if (cached != null) return cached;

      if (!await _spendOne(dailyLimit)) {
        return 'search budget for today is used up. Answer from what you '
            'already know, and say you could not look it up.';
      }

      final client = httpClient ?? http.Client();
      try {
        final response = await client
            .post(
              Uri.parse('https://api.tavily.com/search'),
              headers: {
                'content-type': 'application/json',
                'authorization': 'Bearer $apiKey',
              },
              body: jsonEncode({'query': query, 'max_results': maxResults}),
            )
            .timeout(const Duration(seconds: 20));
        if (response.statusCode != 200) {
          // Returned, not thrown: a dead search is one failed step the agent
          // can answer around, not a failed conversation.
          return 'search failed (${response.statusCode})';
        }
        final results = (jsonDecode(response.body) as Map)['results'];
        if (results is! List || results.isEmpty) {
          return 'no results for "$query"';
        }
        final text = results
            .whereType<Map>()
            .take(maxResults)
            .map((result) {
              final extract = '${result['content'] ?? ''}'.trim();
              return '${result['title'] ?? 'untitled'} (${result['url'] ?? ''})\n'
                  '${extract.length > _extractChars ? '${extract.substring(0, _extractChars)}...' : extract}';
            })
            .join('\n\n');
        // Only answers are cached. A cheap failure should be free to
        // succeed on the next try.
        if (cache.length >= _cacheEntries) cache.remove(cache.keys.first);
        cache[query.toLowerCase()] = text;
        return text;
      } on Exception catch (error) {
        return 'search failed ($error)';
      } finally {
        if (httpClient == null) client.close();
      }
    },
  );
}
