// Manual smoke test against a live OpenAI-compatible server. Not a unit
// test: `dart run tool/smoke_openai_compat.dart [baseUrl] [model]`.
import 'dart:io';
import 'package:portal_ai/src/clients/openai_compatible_completion_client.dart';

Future<void> main(List<String> args) async {
  final client = OpenAiCompatibleCompletionClient(
    baseUrl: args.isNotEmpty ? args[0] : 'http://localhost:11434/v1',
    model: args.length > 1 ? args[1] : 'gemma4:latest',
  );
  stdout.writeln('available: ${await client.isAvailable()}');
  final text = await client.complete(
    systemPrompt: 'Answer in five words or fewer.',
    userPrompt: 'What colour is the sky?',
  );
  stdout.writeln('complete: $text');
  stdout.write('stream: ');
  await for (final d in client.completeStream(
    systemPrompt: 'Answer in five words or fewer.',
    userPrompt: 'Name one fruit.',
  )) {
    stdout.write(d);
  }
  stdout.writeln();
  final json = await client.complete(
    systemPrompt: 'Reply with JSON only.',
    userPrompt: 'Give {"n": 3}',
    jsonMode: true,
  );
  stdout.writeln('json: $json');
}
