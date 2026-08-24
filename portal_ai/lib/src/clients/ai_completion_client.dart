import '../models/ai_sampler_config.dart';

/// Unified text completion API across cloud, Ollama, and on-device backends.
abstract class AiCompletionClient {
  Future<bool> isAvailable();

  Future<String> complete({
    required String systemPrompt,
    required String userPrompt,
    AiSamplerConfig sampler = const AiSamplerConfig(),
    bool jsonMode = false,
  });

  Stream<String> completeStream({
    required String systemPrompt,
    required String userPrompt,
    AiSamplerConfig sampler = const AiSamplerConfig(),
  });
}

class AiCompletionException implements Exception {
  const AiCompletionException(this.message);

  final String message;

  @override
  String toString() => message;
}
