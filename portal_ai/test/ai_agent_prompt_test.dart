import 'package:flutter_test/flutter_test.dart';
import 'package:portal_ai/portal_ai.dart';

class _NullClient implements AiCompletionClient {
  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<String> complete({
    required String systemPrompt,
    required String userPrompt,
    AiSamplerConfig sampler = const AiSamplerConfig(),
    bool jsonMode = false,
  }) async => '{"final":"done"}';

  @override
  Stream<String> completeStream({
    required String systemPrompt,
    required String userPrompt,
    AiSamplerConfig sampler = const AiSamplerConfig(),
    bool jsonMode = false,
  }) => Stream.value('{"final":"done"}');
}

/// Nothing else in the prompt anchors "this week", so a plan asked for today
/// was written to whenever the model's training stopped.
void main() {
  test('the system prompt states today', () {
    final agent = AiAgent(client: _NullClient(), tools: const []);
    final today = DateTime.now().toIso8601String().split('T').first;

    expect(agent.systemPrompt, contains('Today is $today'));
  });
}
