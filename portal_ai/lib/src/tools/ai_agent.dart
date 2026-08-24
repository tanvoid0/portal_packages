import 'dart:convert';

import '../clients/ai_completion_client.dart';
import '../models/ai_sampler_config.dart';
import 'ai_tool.dart';

/// Extracts the outermost JSON object from a model reply that may be wrapped
/// in prose or markdown fences. Returns null when there is nothing to parse.
Map<String, dynamic>? extractJsonObject(String raw) {
  final trimmed = raw.trim();
  final start = trimmed.indexOf('{');
  final end = trimmed.lastIndexOf('}');
  if (start == -1 || end <= start) return null;
  try {
    final decoded = jsonDecode(trimmed.substring(start, end + 1));
    return decoded is Map<String, dynamic> ? decoded : null;
  } catch (_) {
    return null;
  }
}

class AiAgentResult {
  const AiAgentResult({required this.message, required this.steps});

  final String message;
  final List<AiAgentStep> steps;
}

/// Runs a tool-calling loop over any [AiCompletionClient].
///
/// Uses JSON mode rather than provider-native function calling so the same
/// loop works on Gemini, Ollama and future on-device backends.
class AiAgent {
  AiAgent({
    required this.client,
    required this.tools,
    this.appDescription = '',
    this.maxSteps = 6,
  });

  final AiCompletionClient client;
  final List<AiTool> tools;

  /// One or two lines telling the model what app it is acting inside.
  final String appDescription;
  final int maxSteps;

  /// Runs [prompt] to completion.
  ///
  /// [confirm] gates every tool marked [AiTool.mutates]; returning false feeds
  /// the refusal back to the model instead of running the tool. When null,
  /// mutating tools run unattended — callers with a UI should always pass it.
  /// [onStep] fires after each tool result so a UI can show progress.
  Future<AiAgentResult> run(
    String prompt, {
    Future<bool> Function(AiTool tool, AiToolCall call)? confirm,
    void Function(AiAgentStep step)? onStep,
  }) async {
    final steps = <AiAgentStep>[];
    final transcript = <String>[];

    for (var i = 0; i < maxSteps; i++) {
      final raw = await client.complete(
        systemPrompt: _systemPrompt,
        userPrompt: _userPrompt(prompt, transcript),
        jsonMode: true,
        sampler: const AiSamplerConfig(temperature: 0.2),
      );

      final decoded = extractJsonObject(raw);
      if (decoded == null) {
        throw AiCompletionException('Model did not return JSON: $raw');
      }

      final finalMessage = decoded['final'];
      if (finalMessage is String && finalMessage.trim().isNotEmpty) {
        return AiAgentResult(message: finalMessage.trim(), steps: steps);
      }

      final name = (decoded['tool'] as Object?)?.toString().trim() ?? '';
      final tool = tools.where((t) => t.name == name).firstOrNull;
      if (tool == null) {
        transcript.add('error: unknown tool "$name". Use one of: '
            '${tools.map((t) => t.name).join(', ')}');
        continue;
      }

      final rawArgs = decoded['args'];
      final call = AiToolCall(
        name,
        rawArgs is Map ? Map<String, dynamic>.from(rawArgs) : const {},
      );

      if (tool.mutates && confirm != null && !await confirm(tool, call)) {
        final step = AiAgentStep(
          call: call,
          result: 'user declined this action',
          failed: true,
        );
        steps.add(step);
        onStep?.call(step);
        transcript.add('${steps.length}. $call -> declined by user');
        continue;
      }

      late final AiAgentStep step;
      try {
        step = AiAgentStep(call: call, result: await tool.run(call));
      } catch (e) {
        step = AiAgentStep(call: call, result: e.toString(), failed: true);
      }
      steps.add(step);
      onStep?.call(step);
      transcript.add(
        '${steps.length}. $call -> ${step.failed ? 'error: ' : ''}${step.result}',
      );
    }

    return AiAgentResult(
      message: 'Stopped after $maxSteps steps without finishing.',
      steps: steps,
    );
  }

  String get _systemPrompt => '''
You are the in-app assistant. $appDescription
You act by calling tools. Reply with ONE JSON object and nothing else, either:
{"tool": "<name>", "args": {...}}
{"final": "<short message for the user>"}

Tools:
${tools.map((t) => t.spec).join('\n')}

Rules:
- One tool per reply. Read the previous results before deciding the next call.
- Never invent ids or names. Use a list/search tool first to find them.
- Tools marked [changes data] need the user's confirmation; expect refusals.
- Reply with "final" as soon as the request is done, impossible, or needs
  information only the user can give.''';

  String _userPrompt(String prompt, List<String> transcript) {
    if (transcript.isEmpty) return 'User request: $prompt';
    return 'User request: $prompt\n\nSteps so far:\n${transcript.join('\n')}';
  }
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull {
    final it = iterator;
    return it.moveNext() ? it.current : null;
  }
}
