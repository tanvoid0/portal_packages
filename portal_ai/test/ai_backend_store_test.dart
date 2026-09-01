import 'package:flutter_test/flutter_test.dart';
import 'package:portal_ai/portal_ai.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AiBackendStore', () {
    late AiBackendStore store;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      store = AiBackendStore(prefs: prefs, keyPrefix: 'test');
    });

    test('resolveSelectedKind falls back to first available inference backend',
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
    });

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
  });

  group('AiBackendKindIds', () {
    test('round-trips backend ids', () {
      for (final kind in AiBackendKind.values) {
        expect(AiBackendKindIds.fromId(kind.id), kind);
      }
    });
  });
}
