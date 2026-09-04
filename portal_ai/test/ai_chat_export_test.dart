import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:portal_ai/portal_ai.dart';

void main() {
  test('export carries turns, payloads and the prompt it ran on', () {
    final json = jsonDecode(
      aiChatExportJson(
        app: 'Portal Recipe',
        title: 'Dinner ideas',
        at: DateTime.utc(2026, 9, 1, 12),
        systemPrompt: 'You are the in-app assistant.',
        toolSpecs: const ['list_recipes() - lists recipes'],
        turns: [
          const AiChatTurn(role: 'user', content: 'what can I cook?'),
          AiChatTurn(
            role: 'assistant',
            content: 'Pasta.',
            took: const Duration(seconds: 3),
            payload: const {
              'blocks': [
                {'kind': 'items'}
              ],
              'tokens': 412,
            },
          ),
        ],
      ),
    ) as Map<String, dynamic>;

    expect(json['app'], 'Portal Recipe');
    expect(json['title'], 'Dinner ideas');
    expect(json['exported_at'], '2026-09-01T12:00:00.000Z');
    expect(json['system_prompt'], contains('in-app assistant'));
    expect(json['tools'], ['list_recipes() - lists recipes']);

    final turns = json['turns'] as List<dynamic>;
    expect(turns, hasLength(2));
    expect(turns.first['role'], 'user');
    expect(turns.last['took_ms'], 3000);
    expect(turns.last['payload']['tokens'], 412);
  });

  test('optional context is left out rather than exported as null', () {
    final json = jsonDecode(
      aiChatExportJson(app: 'Portal Gym', turns: const [], at: DateTime.now()),
    ) as Map<String, dynamic>;
    expect(json.containsKey('system_prompt'), isFalse);
    expect(json.containsKey('tools'), isFalse);
    expect(json.containsKey('title'), isFalse);
    expect(json['turns'], isEmpty);
  });
}
