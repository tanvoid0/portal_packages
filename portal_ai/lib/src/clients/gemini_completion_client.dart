import 'package:google_generative_ai/google_generative_ai.dart';

import '../config/gemini_model_catalog.dart';
import '../models/ai_sampler_config.dart';
import 'ai_completion_client.dart';
import 'ai_completion_stats.dart';

/// Direct Gemini completions using an API key from app environment.
class GeminiCompletionClient
    with AiCompletionStatsSource
    implements AiCompletionClient {
  GeminiCompletionClient({
    required GeminiModelCatalog catalog,
    required String model,
  })  : _catalog = catalog,
        _modelName = catalog.resolveModel(model);

  final GeminiModelCatalog _catalog;
  final String _modelName;

  @override
  Future<bool> isAvailable() async => _catalog.isConfigured;

  @override
  Future<String> complete({
    required String systemPrompt,
    required String userPrompt,
    AiSamplerConfig sampler = const AiSamplerConfig(),
    bool jsonMode = false,
  }) async {
    if (!_catalog.isConfigured) {
      throw const AiCompletionException(
        'Gemini is not configured. Set GEMINI_API_KEY and GEMINI_MODELS in .env.',
      );
    }

    final model = GenerativeModel(
      model: _modelName,
      apiKey: _catalog.apiKey,
      generationConfig: GenerationConfig(
        temperature: sampler.temperature,
        topP: sampler.topP,
        topK: sampler.topK,
        responseMimeType: jsonMode ? 'application/json' : 'text/plain',
      ),
      systemInstruction: Content.system(systemPrompt),
    );

    try {
      final response = await model.generateContent([Content.text(userPrompt)]);
      final usage = response.usageMetadata;
      lastStats = AiCompletionStats(
        model: _modelName,
        promptTokens: usage?.promptTokenCount,
        replyTokens: usage?.candidatesTokenCount,
      );
      final text = response.text?.trim();
      if (text == null || text.isEmpty) {
        throw const AiCompletionException('Gemini returned an empty response');
      }
      return text;
    } on GenerativeAIException catch (e) {
      throw AiCompletionException(e.message);
    }
  }

  @override
  Stream<String> completeStream({
    required String systemPrompt,
    required String userPrompt,
    AiSamplerConfig sampler = const AiSamplerConfig(),
  }) async* {
    if (!_catalog.isConfigured) {
      throw const AiCompletionException(
        'Gemini is not configured. Set GEMINI_API_KEY and GEMINI_MODELS in .env.',
      );
    }

    final model = GenerativeModel(
      model: _modelName,
      apiKey: _catalog.apiKey,
      generationConfig: GenerationConfig(
        temperature: sampler.temperature,
        topP: sampler.topP,
        topK: sampler.topK,
      ),
      systemInstruction: Content.system(systemPrompt),
    );

    try {
      await for (final chunk in model.generateContentStream([
        Content.text(userPrompt),
      ])) {
        final text = chunk.text;
        if (text != null && text.isNotEmpty) yield text;
      }
    } on GenerativeAIException catch (e) {
      throw AiCompletionException(e.message);
    }
  }
}
