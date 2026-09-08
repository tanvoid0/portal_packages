import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:portal_ai/portal_ai.dart';

/// Records what the agent asked, and answers whatever it was told to.
class _RecordingClient implements AiCompletionClient {
  static const reply = '{"final": "ok"}';

  final prompts = <String>[];

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<String> complete({
    required String systemPrompt,
    required String userPrompt,
    AiSamplerConfig sampler = const AiSamplerConfig(),
    bool jsonMode = false,
  }) async {
    prompts.add(userPrompt);
    return reply;
  }

  @override
  Stream<String> completeStream({
    required String systemPrompt,
    required String userPrompt,
    AiSamplerConfig sampler = const AiSamplerConfig(),
  }) async* {
    yield await complete(systemPrompt: systemPrompt, userPrompt: userPrompt);
  }
}

void main() {
  test('a long thread is cut down to the newest turns', () async {
    final client = _RecordingClient();
    final agent = AiAgent(client: client, tools: const [], historyBudget: 120);
    final history = [
      for (var i = 0; i < 20; i++)
        AiChatTurn(role: i.isEven ? 'user' : 'assistant', content: 'turn $i'),
    ];

    await agent.run('and now?', history: history);

    final sent = client.prompts.single;
    // The newest survive, the oldest are gone, and the model is told so.
    expect(sent, contains('turn 19'));
    expect(sent, isNot(contains('turn 0')));
    expect(sent, contains('earlier turns omitted'));
    expect(sent, contains('User request: and now?'));
  });

  test('a short thread travels whole, with no omission note', () async {
    final client = _RecordingClient();
    final agent = AiAgent(client: client, tools: const []);

    await agent.run(
      'and now?',
      history: const [
        AiChatTurn(role: 'user', content: 'first'),
        AiChatTurn(role: 'assistant', content: 'second'),
      ],
    );

    final sent = client.prompts.single;
    expect(sent, contains('first'));
    expect(sent, contains('second'));
    expect(sent, isNot(contains('omitted')));
  });

  test('a network failure reads as offline, anything else as itself', () {
    const offline = 'No connection.';

    expect(
      aiErrorMessage(
        const SocketException('Failed host lookup: portal'),
        offline: offline,
      ),
      offline,
    );
    expect(aiErrorMessage(TimeoutException('slow'), offline: offline), offline);
    expect(
      aiErrorMessage(
        Exception('ClientException with SocketException'),
        offline: offline,
      ),
      offline,
    );
    expect(
      aiErrorMessage(
        const AiCompletionException('Model did not return JSON'),
        offline: offline,
      ),
      contains('did not return JSON'),
    );
  });
}
