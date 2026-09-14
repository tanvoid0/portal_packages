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
    // Routing defaults to server-first, which would wrap this in a
    // FallbackCompletionClient (covered in fallback_completion_client_test.dart
    // and the "routing" group below) -- local-only isolates the older claim
    // this test makes: a stored provider is read and built at all.
    final runtime = PortalAiRuntime.create(
      post: noPost,
      store: await storeWith({
        'test_selected_backend_id': AiBackendKind.ollama.id,
        'test_ollama_model': 'gemma4',
        'test_routing_mode': AiRoutingMode.localOnly.id,
      }),
    );

    expect(runtime.client, isA<OllamaCompletionClient>());
    expect(runtime.usesLocalModel, isTrue);
  });

  group('routing', () {
    test(
      'server-first wraps a configured local backend rather than replacing it',
      () async {
        final runtime = PortalAiRuntime.create(
          post: noPost,
          store: await storeWith({
            'test_selected_backend_id': AiBackendKind.ollama.id,
            'test_ollama_model': 'gemma4',
          }),
        );

        expect(runtime.client, isA<FallbackCompletionClient>());
        expect(
          (runtime.client as FallbackCompletionClient).fallback,
          isA<OllamaCompletionClient>(),
        );
        expect(
          (runtime.client as FallbackCompletionClient).primary,
          isA<ServerCompletionClient>(),
        );
      },
    );

    test('server-only ignores a configured local backend', () async {
      final runtime = PortalAiRuntime.create(
        post: noPost,
        store: await storeWith({
          'test_selected_backend_id': AiBackendKind.ollama.id,
          'test_ollama_model': 'gemma4',
          'test_routing_mode': AiRoutingMode.serverOnly.id,
        }),
      );

      expect(runtime.client, isA<ServerCompletionClient>());
    });

    test(
      'local-only with nothing usable degrades to the server, carrying a hint',
      () async {
        // A server exists, so this is never "nothing to build" -- it must
        // not throw out of create() the way it used to, since apps call
        // create() unguarded at boot and this is reachable from prefs sync
        // landing an unbuildable choice made on another device.
        final store = await storeWith({
          'test_selected_backend_id': AiBackendKind.ollama.id,
          'test_routing_mode': AiRoutingMode.localOnly.id,
        });

        final runtime = PortalAiRuntime.create(post: noPost, store: store);

        expect(runtime.client, isA<ServerCompletionClient>());
        expect(runtime.configurationHint, contains('routing'));
      },
    );

    test('local-only with nothing configured at all is a wiring error', () async {
      // No server and nothing local: genuinely nothing to build.
      final store = await storeWith({
        'test_routing_mode': AiRoutingMode.localOnly.id,
      });

      expect(
        () => PortalAiRuntime.create(store: store),
        throwsA(isA<ArgumentError>()),
      );
    });
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

  test(
    'the badge names what answered, not a provider that fell back',
    () async {
      // Edge Gallery is a delegate, never an in-app client, so the runtime
      // quietly stays on the server. The badge used to read the stored kind and
      // announce "Edge Gallery" while Settings reported the Gemini model that
      // actually ran.
      final runtime = PortalAiRuntime.create(
        post: noPost,
        store: await storeWith({
          'test_selected_backend_id': AiBackendKind.edgeGalleryDelegate.id,
          'test_gemini_model': 'gemini-3.1-flash-lite',
        }),
      );

      expect(runtime.activeBackendKind, AiBackendKind.cloudGemini);
      expect(runtime.backendLabel, 'gemini-3.1-flash-lite');
    },
  );

  test(
    'switching provider in settings re-points the running assistant',
    () async {
      // applyBackend routes through the same store-wide resolution create()
      // uses, so with the default server-first routing and a server
      // transport present, picking a local backend wraps it rather than
      // replacing the server outright -- covered by the routing group above.
      // Local-only isolates this test's actual claim: a switch in settings
      // reaches the running assistant at all.
      final store = await storeWith({
        'test_routing_mode': AiRoutingMode.localOnly.id,
      });
      final runtime = PortalAiRuntime.create(post: noPost, store: store);
      expect(runtime.usesLocalModel, isFalse);

      await store.setSelectedKind(AiBackendKind.systemOnDevice);
      runtime.applyBackend(
        const AiBackendOption(
          kind: AiBackendKind.systemOnDevice,
          available: true,
        ),
      );
      expect(runtime.client, isA<SystemAiCompletionClient>());

      // applyBackend rebuilds from the store as a whole (routing included),
      // so -- same as the real caller, AiSettingsSection's `_select` --
      // the store is what has to move, not just the option passed in.
      await store.setSelectedKind(AiBackendKind.cloudGemini);
      runtime.applyBackend(
        const AiBackendOption(kind: AiBackendKind.cloudGemini, available: true),
      );
      expect(runtime.usesLocalModel, isFalse);
    },
  );

  test(
    'applyBackend respects server-first routing, not just the stored kind',
    () async {
      final store = await storeWith({});
      final runtime = PortalAiRuntime.create(post: noPost, store: store);

      await store.setSelectedKind(AiBackendKind.systemOnDevice);
      runtime.applyBackend(
        const AiBackendOption(
          kind: AiBackendKind.systemOnDevice,
          available: true,
        ),
      );

      expect(runtime.client, isA<FallbackCompletionClient>());
      expect(
        (runtime.client as FallbackCompletionClient).fallback,
        isA<SystemAiCompletionClient>(),
      );
    },
  );

  test(
    'the stored model is corrected when the provider stops offering it',
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
    },
  );
}
