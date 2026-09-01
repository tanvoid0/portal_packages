import 'package:flutter_test/flutter_test.dart';
import 'package:portal_ai/portal_ai.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The settings picker only matters if the runtime reads it. These cover the
/// two ways that breaks: the assistant ignoring a stored choice at startup,
/// and a provider switch in settings not reaching the running assistant.
Future<AiBackendStore> storeWith(Map<String, Object> values) async {
  SharedPreferences.setMockInitialValues(values);
  return AiBackendStore(
    prefs: await SharedPreferences.getInstance(),
    keyPrefix: 'test',
  );
}

Future<dynamic> noPost(String path, {dynamic body}) =>
    throw UnimplementedError();

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('with nothing stored the assistant talks to the server', () async {
    final runtime = PortalAiRuntime.create(
      post: noPost,
      store: await storeWith({}),
    );

    expect(runtime.usesLocalModel, isFalse);
  });

  test('a stored local provider is what the assistant starts on', () async {
    final runtime = PortalAiRuntime.create(
      post: noPost,
      store: await storeWith({
        'test_selected_backend_id': AiBackendKind.ollama.id,
        'test_ollama_model': 'gemma4',
      }),
    );

    expect(runtime.client, isA<OllamaCompletionClient>());
    expect(runtime.usesLocalModel, isTrue);
  });

  test('a half-configured provider falls back rather than throwing', () async {
    // Ollama selected but no model picked yet: the factory throws, and an
    // assistant that cannot be constructed is worse than one on the server.
    final runtime = PortalAiRuntime.create(
      post: noPost,
      store: await storeWith({
        'test_selected_backend_id': AiBackendKind.ollama.id,
      }),
    );

    expect(runtime.usesLocalModel, isFalse);
  });

  test('switching provider in settings re-points the running assistant',
      () async {
    final store = await storeWith({});
    final runtime = PortalAiRuntime.create(post: noPost, store: store);
    expect(runtime.usesLocalModel, isFalse);

    await store.setSelectedKind(AiBackendKind.systemOnDevice);
    runtime.applyBackend(
      const AiBackendOption(kind: AiBackendKind.systemOnDevice, available: true),
    );
    expect(runtime.client, isA<SystemAiCompletionClient>());

    runtime.applyBackend(
      const AiBackendOption(kind: AiBackendKind.cloudGemini, available: true),
    );
    expect(runtime.usesLocalModel, isFalse);
  });

  test('the stored model is corrected when the provider stops offering it',
      () async {
    final store = await storeWith({'test_ollama_model': 'gone'});

    await store.ensureModelFor(
      const AiBackendOption(
        kind: AiBackendKind.ollama,
        available: true,
        models: ['llama4', 'gemma4'],
      ),
    );
    expect(store.ollamaModel, 'llama4');

    // One it still offers is left alone.
    await store.ensureModelFor(
      const AiBackendOption(
        kind: AiBackendKind.ollama,
        available: true,
        models: ['gemma4', 'llama4'],
      ),
    );
    expect(store.ollamaModel, 'llama4');
  });
}
