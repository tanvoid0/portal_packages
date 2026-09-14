import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portal_ai/portal_ai.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AiBackendStore', () {
    late AiBackendStore store;
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      FlutterSecureStorage.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      store = AiBackendStore(prefs: prefs, keyPrefix: 'test');
    });

    test(
      'resolveSelectedKind falls back to first available inference backend',
      () async {
        final kind = await store.resolveSelectedKind(const [
          AiBackendOption(
            kind: AiBackendKind.cloudGemini,
            available: false,
            unavailableReason: 'Not signed in',
          ),
          AiBackendOption(
            kind: AiBackendKind.ollama,
            available: true,
            models: ['llama3.2'],
          ),
        ]);

        expect(kind, AiBackendKind.ollama);
        expect(store.selectedKind, AiBackendKind.ollama);
      },
    );

    test('keeps stored backend when still available', () async {
      await store.setSelectedKind(AiBackendKind.ollama);
      final kind = await store.resolveSelectedKind(const [
        AiBackendOption(
          kind: AiBackendKind.ollama,
          available: true,
          models: ['llama3.2'],
        ),
      ]);

      expect(kind, AiBackendKind.ollama);
    });

    test('keeps stored backend even when momentarily unavailable', () async {
      await store.setSelectedKind(AiBackendKind.ollama);
      final kind = await store.resolveSelectedKind(const [
        AiBackendOption(
          kind: AiBackendKind.ollama,
          available: false,
          unavailableReason: 'Not reachable',
        ),
        AiBackendOption(kind: AiBackendKind.cloudGemini, available: true),
      ]);

      expect(kind, AiBackendKind.ollama);
      // The scan must not silently switch the stored choice to whatever
      // fallback was available during this one scan.
      expect(store.selectedKind, AiBackendKind.ollama);
    });

    test('keeps stored Edge Gallery delegate when installed', () async {
      await store.setSelectedKind(AiBackendKind.edgeGalleryDelegate);
      final kind = await store.resolveSelectedKind(const [
        AiBackendOption(
          kind: AiBackendKind.edgeGalleryDelegate,
          available: true,
        ),
        AiBackendOption(
          kind: AiBackendKind.ollama,
          available: true,
          models: ['llama3.2'],
        ),
      ]);

      expect(kind, AiBackendKind.edgeGalleryDelegate);
    });

    test('persists ollama host and model', () async {
      await store.setOllamaHost('http://192.168.1.10:11434');
      await store.setOllamaModel('gemma3');

      expect(store.ollamaHost, 'http://192.168.1.10:11434');
      expect(store.ollamaModel, 'gemma3');
    });

    test('routing mode round-trips and defaults to serverFirst', () async {
      expect(store.routingMode, AiRoutingMode.serverFirst);

      await store.setRoutingMode(AiRoutingMode.localOnly);
      expect(store.routingMode, AiRoutingMode.localOnly);

      await store.setRoutingMode(AiRoutingMode.serverOnly);
      expect(store.routingMode, AiRoutingMode.serverOnly);
    });

    test('openAiBaseUrl round-trips', () async {
      expect(store.openAiBaseUrl, '');
      await store.setOpenAiBaseUrl('https://api.groq.com/openai/v1');
      expect(store.openAiBaseUrl, 'https://api.groq.com/openai/v1');
    });

    test('openAiApiKey round-trips through the write-through cache', () async {
      expect(store.openAiApiKey, '');

      await store.setOpenAiApiKey('sk-secret');
      expect(store.openAiApiKey, 'sk-secret');

      // A key written by a prior run is not in the cache until warmed --
      // a fresh store instance simulates a cold start.
      final reopened = AiBackendStore(prefs: prefs, keyPrefix: 'test');
      expect(reopened.openAiApiKey, '');
      await reopened.loadOpenAiApiKey();
      expect(reopened.openAiApiKey, 'sk-secret');
    });
  });

  group('AiBackendKindIds', () {
    test('round-trips backend ids', () {
      for (final kind in AiBackendKind.values) {
        expect(AiBackendKindIds.fromId(kind.id), kind);
      }
    });
  });
}
