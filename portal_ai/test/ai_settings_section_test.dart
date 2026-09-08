import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portal_ai/portal_ai.dart';
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
  }) async => options;
}

/// An unreachable Ollama is exactly when its address needs changing, and its
/// row is disabled then — so gating the address controls on "is selected"
/// leaves the one control that would fix it unreachable. That dead end is what
/// these cover.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const labels = AiBackendLabels();

  Future<void> pump(WidgetTester tester, List<AiBackendOption> options) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: AiSettingsSection(
              store: AiBackendStore(prefs: prefs, keyPrefix: 'test'),
              discovery: _FixedDiscovery(options),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('an unreachable Ollama still offers its address and a scan', (
    tester,
  ) async {
    await pump(tester, const [
      AiBackendOption(kind: AiBackendKind.cloudGemini, available: true),
      AiBackendOption(
        kind: AiBackendKind.ollama,
        available: false,
        unavailableReason: 'Ollama is not running at http://10.0.2.2:11434',
      ),
    ]);

    expect(find.text(labels.ollamaHost), findsOneWidget);
    expect(find.text(labels.findOllama), findsOneWidget);
  });

  testWidgets('the model dropdown belongs to the selected provider only', (
    tester,
  ) async {
    await pump(tester, const [
      AiBackendOption(
        kind: AiBackendKind.cloudGemini,
        available: true,
        models: ['gemini-2.0-flash'],
      ),
      AiBackendOption(
        kind: AiBackendKind.ollama,
        available: true,
        models: ['gemma4'],
      ),
    ]);

    // Cloud is first and available, so it is what resolveSelectedKind picks.
    expect(find.text(labels.model), findsOneWidget);
    expect(find.text('gemini-2.0-flash'), findsWidgets);
    expect(
      find.widgetWithText(DropdownButtonFormField<String>, 'gemma4'),
      findsNothing,
    );
  });

  testWidgets('badges mark the selected provider and the unavailable one', (
    tester,
  ) async {
    await pump(tester, const [
      AiBackendOption(kind: AiBackendKind.cloudGemini, available: true),
      AiBackendOption(
        kind: AiBackendKind.ollama,
        available: false,
        unavailableReason: 'Not running',
      ),
    ]);

    // Cloud is first and available, so resolveSelectedKind picks it.
    expect(find.text(labels.selectedBadge), findsOneWidget);
    expect(find.text(labels.unavailable), findsOneWidget);
  });

  testWidgets(
    'a device model that only needs downloading offers the download',
    (tester) async {
      await pump(tester, const [
        AiBackendOption(kind: AiBackendKind.cloudGemini, available: true),
        AiBackendOption(
          kind: AiBackendKind.systemOnDevice,
          available: false,
          unavailableReason: 'The on-device model has not been downloaded yet',
          metadata: {'downloadable': true},
        ),
      ]);

      expect(find.text(labels.download), findsOneWidget);
    },
  );
}
