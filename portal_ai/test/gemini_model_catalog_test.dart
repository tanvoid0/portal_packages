import 'package:flutter_test/flutter_test.dart';
import 'package:portal_ai/portal_ai.dart';

void main() {
  group('GeminiModelCatalog', () {
    test('parses comma-separated GEMINI_MODELS', () {
      final catalog = GeminiModelCatalog.fromEnvironment({
        GeminiEnvKeys.apiKey: 'test-key',
        GeminiEnvKeys.models: 'gemini-2.0-flash, gemini-2.5-pro',
      });

      expect(catalog.hasApiKey, isTrue);
      expect(catalog.availableModels, ['gemini-2.0-flash', 'gemini-2.5-pro']);
      expect(catalog.isConfigured, isTrue);
      expect(catalog.defaultModel, 'gemini-2.0-flash');
    });

    test('falls back to GEMINI_MODEL then default when only key is set', () {
      final single = GeminiModelCatalog.fromEnvironment({
        GeminiEnvKeys.apiKey: 'test-key',
        GeminiEnvKeys.model: 'gemini-2.5-flash',
      });
      expect(single.availableModels, ['gemini-2.5-flash']);

      final fallback = GeminiModelCatalog.fromEnvironment({
        GeminiEnvKeys.apiKey: 'test-key',
      });
      expect(fallback.availableModels, [kDefaultGeminiModel]);
    });

    test('resolveModel prefers stored selection', () {
      final catalog = GeminiModelCatalog.fromEnvironment({
        GeminiEnvKeys.apiKey: 'test-key',
        GeminiEnvKeys.models: 'gemini-2.0-flash,gemini-2.5-pro',
      });

      expect(catalog.resolveModel('gemini-2.5-pro'), 'gemini-2.5-pro');
      expect(catalog.resolveModel('missing'), 'gemini-2.0-flash');
    });
  });

  group('AiModelCatalog', () {
    test('exposes gemini models from env catalog', () {
      final gemini = GeminiModelCatalog.fromEnvironment({
        GeminiEnvKeys.apiKey: 'key',
        GeminiEnvKeys.models: 'gemini-2.0-flash',
      });
      final catalog = AiModelCatalog(gemini: gemini);

      expect(catalog.geminiModels, ['gemini-2.0-flash']);
    });
  });
}
