import '../models/ai_sampler_config.dart';
import '../platform/portal_ai_platform.dart';
import 'ai_completion_client.dart';

/// Runs the device's own built-in model over the platform channel.
///
/// On Android that is ML Kit GenAI talking to AICore (Gemini Nano). The model
/// name is never named here — the platform reports what it runs.
class SystemAiCompletionClient implements AiCompletionClient {
  const SystemAiCompletionClient();

  @override
  Future<bool> isAvailable() async {
    final description = await PortalAiPlatform.describeSystemAi();
    return description.isAvailable;
  }

  @override
  Future<String> complete({
    required String systemPrompt,
    required String userPrompt,
    AiSamplerConfig sampler = const AiSamplerConfig(),
    bool jsonMode = false,
  }) async {
    final text = await PortalAiPlatform.generate(
      prompt: _prompt(systemPrompt, userPrompt, jsonMode: jsonMode),
      temperature: sampler.temperature,
      topK: sampler.topK,
    );
    if (text.trim().isEmpty) {
      throw const AiCompletionException(
        'The on-device model returned an empty response',
      );
    }
    return text;
  }

  @override
  Stream<String> completeStream({
    required String systemPrompt,
    required String userPrompt,
    AiSamplerConfig sampler = const AiSamplerConfig(),
  }) {
    return PortalAiPlatform.generateStream(
      prompt: _prompt(systemPrompt, userPrompt, jsonMode: false),
      temperature: sampler.temperature,
      topK: sampler.topK,
    );
  }

  /// One flat prompt: a system role is optional on-device (ML Kit only exposes
  /// it on some devices, see `isSystemPromptAvailable`), and JSON mode is an
  /// instruction rather than a decoding constraint. [AiAgent] already tolerates
  /// JSON wrapped in prose, which is what a small model tends to produce.
  static String _prompt(
    String systemPrompt,
    String userPrompt, {
    required bool jsonMode,
  }) {
    return [
      if (systemPrompt.trim().isNotEmpty) systemPrompt.trim(),
      if (jsonMode) 'Reply with a single JSON object and nothing else.',
      userPrompt.trim(),
    ].join('\n\n');
  }
}
