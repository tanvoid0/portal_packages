import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portal_ai/portal_ai.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Selection moved from a per-tile `onChanged` to a single [RadioGroup] that
/// reports the tapped tile's *value*, so the widget now has to map that id back
/// to its option. These two tests are what fails if that mapping breaks, or if
/// an unavailable backend stops being disabled and becomes selectable.
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const labels = AiBackendLabels();

  /// Pumps the selector over [options], taps the tile titled [label], and
  /// returns whatever the widget reported through `onChanged`.
  ///
  /// The list order matters: `resolveSelectedKind` preselects the first
  /// available backend, and tapping an already-selected radio reports nothing.
  Future<AiBackendOption?> pumpAndTap(
    WidgetTester tester,
    List<AiBackendOption> options,
    String label,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    AiBackendOption? selected;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AiBackendSelector(
            store: AiBackendStore(prefs: prefs, keyPrefix: 'test'),
            discovery: _FixedDiscovery(options),
            onChanged: (option) => selected = option,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text(label));
    await tester.pumpAndSettle();
    return selected;
  }

  testWidgets('tapping an available backend selects that backend', (
    tester,
  ) async {
    final selected = await pumpAndTap(tester, const [
      AiBackendOption(kind: AiBackendKind.cloudGemini, available: true),
      AiBackendOption(kind: AiBackendKind.ollama, available: true),
    ], labels.titleFor(AiBackendKind.ollama));
    expect(selected?.kind, AiBackendKind.ollama);
  });

  testWidgets('an unavailable backend cannot be selected', (tester) async {
    final selected = await pumpAndTap(tester, const [
      AiBackendOption(kind: AiBackendKind.ollama, available: true),
      AiBackendOption(
        kind: AiBackendKind.cloudGemini,
        available: false,
        unavailableReason: 'Not signed in',
      ),
    ], labels.titleFor(AiBackendKind.cloudGemini));
    expect(selected, isNull);
  });
}
