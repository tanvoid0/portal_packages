import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portal_ai/portal_ai.dart';
import 'package:portal_ai/src/discovery/litert_probe.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('LiteRT is never offered while no runtime is wired up', () async {
    final result = await LiteRtProbe().probe(modelPath: '/tmp/model.task');

    expect(LiteRtProbe.runtimeImplemented, isFalse);
    expect(
      result.isAvailable,
      isFalse,
      reason: 'a selectable LiteRT backend throws on every generate',
    );
    expect(result.reason, isNotNull);
  });

  group('direct Gemini wiring', () {
    Future<AiBackendStore> emptyStore() async {
      SharedPreferences.setMockInitialValues({});
      return AiBackendStore(
        prefs: await SharedPreferences.getInstance(),
        keyPrefix: 'test_gemini',
      );
    }

    test('a bare GEMINI_API_KEY is enough to configure the catalog', () {
      final catalog = GeminiModelCatalog.fromEnvironment({
        GeminiEnvKeys.apiKey: 'test-key',
      });

      expect(catalog.isConfigured, isTrue);
      expect(catalog.defaultModel, kDefaultGeminiModel);
    });

    test('a configured catalog builds a direct client, not the server one',
        () async {
      final catalog = GeminiModelCatalog.fromEnvironment({
        GeminiEnvKeys.apiKey: 'test-key',
        GeminiEnvKeys.models: 'gemini-2.0-flash,gemini-2.5-pro',
      });

      final client = AiCompletionClientFactory(geminiCatalog: catalog).create(
        kind: AiBackendKind.cloudGemini,
        store: await emptyStore(),
      );

      expect(client, isA<GeminiCompletionClient>());
      expect(await client.isAvailable(), isTrue);
    });

    test('no key falls back to the server-side pipeline', () async {
      final catalog = GeminiModelCatalog.fromEnvironment(const {});

      final client = AiCompletionClientFactory(geminiCatalog: catalog).create(
        kind: AiBackendKind.cloudGemini,
        store: await emptyStore(),
      );

      expect(catalog.isConfigured, isFalse);
      expect(client, isA<CloudGeminiCompletionClient>());
    });
  });

  test('unset Ollama host resolves to a reachable default per platform',
      () async {
    SharedPreferences.setMockInitialValues({});
    final store = AiBackendStore(
      prefs: await SharedPreferences.getInstance(),
      keyPrefix: 'test_ai',
    );

    expect(store.ollamaHost, defaultOllamaBaseUrl);

    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    expect(
      defaultOllamaBaseUrl,
      kAndroidEmulatorOllamaBaseUrl,
      reason: '127.0.0.1 on Android is the phone, not the Ollama host',
    );

    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    expect(defaultOllamaBaseUrl, kDefaultOllamaBaseUrl);
  });
}
