import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portal_ai/portal_ai.dart';
import 'package:portal_ui_core/portal_ui_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FixedDiscovery extends AiBackendDiscovery {
  _FixedDiscovery(this.options);

  final List<AiBackendOption> options;

  @override
  Future<List<AiBackendOption>> discover({
    bool includeCloud = true,
    bool cloudEligible = true,
    String ollamaHost = kDefaultOllamaBaseUrl,
    bool includeEdgeGalleryDelegate = true,
    String openAiBaseUrl = '',
    String openAiModel = '',
  }) async => options;
}

/// Stands in for the in-process engine: the group only ever sees it as a
/// [LocalLlmEngine], which is also an [AiModelManager].
class _FakeEngine implements LocalLlmEngine {
  _FakeEngine({this.installedIds = const [], this.catalogEntries = const []});

  final List<String> installedIds;
  final List<AiModelDownload> catalogEntries;

  @override
  Future<List<String>> installed() async => installedIds;

  @override
  Future<List<AiModelDownload>> catalog() async => catalogEntries;

  @override
  Stream<double> install(String id) => const Stream.empty();

  @override
  Future<void> remove(String id) async {}

  @override
  Future<String?> unsupportedReason() async => null;

  @override
  AiCompletionClient clientFor(String model) => throw UnimplementedError();
}

const _cloudOnly = [
  AiBackendOption(kind: AiBackendKind.cloudGemini, available: true),
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const labels = AiBackendLabels();

  late AiBackendStore store;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    store = AiBackendStore(
      prefs: await SharedPreferences.getInstance(),
      keyPrefix: 'test',
    );
  });

  Future<void> pump(
    WidgetTester tester, {
    List<AiBackendOption> options = _cloudOnly,
    bool hasServer = false,
    bool cloudEligible = true,
    LocalLlmEngine? localLlm,
    VoidCallback? onModels,
    ValueChanged<AiBackendOption>? onChanged,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildPortalTheme(brightness: Brightness.light),
        home: Scaffold(
          body: SingleChildScrollView(
            child: AiSettingsGroup(
              store: store,
              discovery: _FixedDiscovery(options),
              hasServer: hasServer,
              cloudEligible: cloudEligible,
              localLlm: localLlm,
              onModels: onModels,
              onChanged: onChanged,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('AiSettingsGroup', () {
    testWidgets('renders the provider, routing and models rows', (
      tester,
    ) async {
      await pump(tester, hasServer: true, localLlm: _FakeEngine());

      expect(find.text(labels.assistantTitle), findsOneWidget);
      expect(find.text(labels.providerRow), findsOneWidget);
      expect(find.text(labels.routingRow), findsOneWidget);
      expect(find.text(labels.modelsRow), findsOneWidget);
    });

    testWidgets('the provider value follows the store', (tester) async {
      const options = [
        AiBackendOption(kind: AiBackendKind.cloudGemini, available: true),
        AiBackendOption(kind: AiBackendKind.ollama, available: true),
      ];
      await store.setSelectedKind(AiBackendKind.ollama);
      await pump(tester, options: options);

      expect(find.text(labels.ollamaTitle), findsOneWidget);
      expect(find.text(labels.cloudGeminiTitle), findsNothing);
    });

    testWidgets('with nothing stored the first available provider shows', (
      tester,
    ) async {
      await pump(tester);

      expect(find.text(labels.cloudGeminiTitle), findsOneWidget);
    });

    testWidgets('an account that cannot use the cloud is told so', (
      tester,
    ) async {
      await pump(tester, cloudEligible: false);
      expect(find.text(labels.cloudNote), findsOneWidget);

      await pump(tester);
      expect(find.text(labels.cloudNote), findsNothing);
    });

    testWidgets('the routing row is absent without a server', (tester) async {
      await pump(tester, localLlm: _FakeEngine());

      expect(find.text(labels.routingRow), findsNothing);
      expect(find.text(labels.providerRow), findsOneWidget);
    });

    testWidgets('the models row is absent with no manager', (tester) async {
      await pump(tester, hasServer: true);

      expect(find.text(labels.modelsRow), findsNothing);
    });

    testWidgets('the models row shows the installed total', (tester) async {
      await pump(
        tester,
        localLlm: _FakeEngine(
          installedIds: const ['a'],
          catalogEntries: const [
            AiModelDownload(id: 'a', label: 'A', sizeBytes: 586 * 1024 * 1024),
          ],
        ),
      );

      expect(find.text('586 MB'), findsOneWidget);
    });

    testWidgets('tapping the models row opens the manager sheet', (
      tester,
    ) async {
      await pump(tester, localLlm: _FakeEngine());

      await tester.tap(find.text(labels.modelsRow));
      await tester.pumpAndSettle();

      expect(find.byType(AiModelManagerSheet), findsOneWidget);
    });

    testWidgets('onModels wins over the built-in sheet', (tester) async {
      var calls = 0;
      await pump(tester, localLlm: _FakeEngine(), onModels: () => calls++);

      await tester.tap(find.text(labels.modelsRow));
      await tester.pumpAndSettle();

      expect(calls, 1);
      expect(find.byType(AiModelManagerSheet), findsNothing);
    });

    testWidgets('the provider sheet reuses the section, minus routing', (
      tester,
    ) async {
      await pump(tester, hasServer: true);

      await tester.tap(find.text(labels.providerRow));
      await tester.pumpAndSettle();

      expect(find.byType(AiSettingsSection), findsOneWidget);
      expect(find.byType(SegmentedButton<AiRoutingMode>), findsNothing);
    });

    testWidgets('applying a routing mode persists it and re-fires onChanged', (
      tester,
    ) async {
      final fired = <AiBackendKind>[];
      await pump(
        tester,
        hasServer: true,
        onChanged: (option) => fired.add(option.kind),
      );
      expect(find.text(labels.routingServerFirst), findsOneWidget);

      await tester.tap(find.text(labels.routingRow));
      await tester.pumpAndSettle();
      await tester.tap(find.text(labels.routingLocalOnly));
      await tester.pump();
      await tester.tap(find.text(labels.apply));
      await tester.pumpAndSettle();

      expect(store.routingMode, AiRoutingMode.localOnly);
      expect(fired, [AiBackendKind.cloudGemini]);
      expect(find.text(labels.routingLocalOnly), findsOneWidget);
    });
  });

  group('aiInstalledModelsLabel', () {
    const mb = 1024 * 1024;

    test('sums the sizes when the catalog knows every installed model', () async {
      final engine = _FakeEngine(
        installedIds: const ['a', 'b'],
        catalogEntries: const [
          AiModelDownload(id: 'a', label: 'A', sizeBytes: 300 * mb),
          AiModelDownload(id: 'b', label: 'B', sizeBytes: 286 * mb),
        ],
      );

      expect(await aiInstalledModelsLabel(engine, labels), '586 MB');
    });

    test('switches to GB from a gigabyte up', () async {
      final engine = _FakeEngine(
        installedIds: const ['a'],
        catalogEntries: const [
          AiModelDownload(id: 'a', label: 'A', sizeBytes: 1536 * mb),
        ],
      );

      expect(await aiInstalledModelsLabel(engine, labels), '1.5 GB');
    });

    test('counts them when any size is unknown', () async {
      final engine = _FakeEngine(
        installedIds: const ['a', 'b'],
        catalogEntries: const [
          AiModelDownload(id: 'a', label: 'A', sizeBytes: 300 * mb),
          AiModelDownload(id: 'b', label: 'B'),
        ],
      );

      expect(await aiInstalledModelsLabel(engine, labels), '2 installed');
    });

    test('counts them when the catalog leaves installed ones out', () async {
      final engine = _FakeEngine(installedIds: const ['a']);

      expect(await aiInstalledModelsLabel(engine, labels), '1 installed');
    });

    test('says so when nothing is installed', () async {
      expect(
        await aiInstalledModelsLabel(_FakeEngine(), labels),
        labels.noInstalledModels,
      );
    });
  });
}
