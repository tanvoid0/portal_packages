import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portal_ai/portal_ai.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

/// Stands in for Ollama or an on-device engine: the page only ever sees
/// [AiModelManager], which is the point of the seam.
class _FakeManager implements AiModelManager {
  _FakeManager({
    List<String> installed = const [],
    this.failInstall = false,
    this.hang = false,
  }) : _installed = [...installed];

  final List<String> _installed;
  final bool failInstall;

  /// Reports half way, then never finishes.
  final bool hang;

  final removed = <String>[];
  final installs = <String>[];

  @override
  Future<List<String>> installed() async => List.of(_installed);

  @override
  Future<List<AiModelDownload>> catalog() async => [
    for (final entry in const [
      AiModelDownload(
        id: 'qwen3:1.7b',
        label: 'Qwen 3 1.7B',
        sizeBytes: 1400 * 1024 * 1024,
        note: 'Fast.',
      ),
    ])
      if (!_installed.contains(entry.id)) entry,
  ];

  @override
  Stream<double> install(String id) async* {
    installs.add(id);
    if (failInstall) throw const AiModelManagerException('disk full');
    yield 0.5;
    if (hang) await Completer<void>().future;
    yield 1.0;
    _installed.add(id);
  }

  @override
  Future<void> remove(String id) async {
    removed.add(id);
    _installed.remove(id);
  }
}

Future<void> _open(WidgetTester tester, AiModelManager manager) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: buildPortalTheme(brightness: Brightness.light),
      home: AiModelsPage(manager: manager),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('AiModelsPage', () {
    testWidgets('says so when nothing is installed yet', (tester) async {
      await _open(tester, _FakeManager());

      expect(find.text('No models downloaded yet.'), findsOneWidget);
      expect(find.text('Qwen 3 1.7B'), findsOneWidget);
      expect(find.text('1.4 GB · Fast.'), findsOneWidget);
    });

    testWidgets('an installed model is listed and not offered again', (
      tester,
    ) async {
      await _open(tester, _FakeManager(installed: const ['qwen3:1.7b']));

      expect(find.text('qwen3:1.7b'), findsOneWidget);
      expect(find.text('Qwen 3 1.7B'), findsNothing);
      expect(find.text('No models downloaded yet.'), findsNothing);
    });

    testWidgets('a download opens its page, then the model appears', (
      tester,
    ) async {
      final manager = _FakeManager();
      await _open(tester, manager);

      await tester.tap(find.text('Download').first);
      await tester.pumpAndSettle();

      expect(find.text('Qwen 3 1.7B is ready'), findsOneWidget);
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      expect(manager.installs, ['qwen3:1.7b']);
      expect(find.byType(AiModelDownloadPage), findsNothing);
      expect(find.text('qwen3:1.7b'), findsOneWidget);
    });

    testWidgets('a failed download is reported and can be retried', (
      tester,
    ) async {
      final manager = _FakeManager(failInstall: true);
      await _open(tester, manager);

      await tester.tap(find.text('Download').first);
      await tester.pumpAndSettle();

      expect(find.text("Couldn't download Qwen 3 1.7B"), findsOneWidget);
      expect(find.text('disk full'), findsOneWidget);

      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(manager.installs, ['qwen3:1.7b', 'qwen3:1.7b']);
    });

    testWidgets('cancel leaves the download page and installs nothing', (
      tester,
    ) async {
      final manager = _FakeManager(hang: true);
      await _open(tester, manager);

      await tester.tap(find.text('Download').first);
      await tester.pump();
      await tester.pump();
      expect(find.text('Downloading Qwen 3 1.7B'), findsOneWidget);

      await tester.tap(find.text('Cancel download'));
      await tester.pumpAndSettle();

      expect(find.byType(AiModelDownloadPage), findsNothing);
      expect(find.text('No models downloaded yet.'), findsOneWidget);
    });

    testWidgets('delete asks first, and a cancel leaves the model alone', (
      tester,
    ) async {
      final manager = _FakeManager(installed: const ['qwen3:1.7b']);
      await _open(tester, manager);

      await tester.tap(find.byTooltip('Options for qwen3:1.7b'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(manager.removed, isEmpty);
      expect(find.text('qwen3:1.7b'), findsOneWidget);
    });

    testWidgets('confirming the delete removes it', (tester) async {
      final manager = _FakeManager(installed: const ['qwen3:1.7b']);
      await _open(tester, manager);

      await tester.tap(find.byTooltip('Options for qwen3:1.7b'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete').last);
      await tester.pumpAndSettle();

      expect(manager.removed, ['qwen3:1.7b']);
      expect(find.text('No models downloaded yet.'), findsOneWidget);
    });

    testWidgets('a typed model id is installed too', (tester) async {
      final manager = _FakeManager();
      await _open(tester, manager);

      await tester.enterText(find.byType(TextField), 'deepseek-r1:1.5b');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(manager.installs, ['deepseek-r1:1.5b']);
    });

    testWidgets('a host with an active model gets the badge and Use action', (
      tester,
    ) async {
      final used = <String>[];
      await tester.pumpWidget(
        MaterialApp(
          theme: buildPortalTheme(brightness: Brightness.light),
          home: AiModelsPage(
            manager: _FakeManager(installed: const ['qwen3:1.7b']),
            activeId: () => 'qwen3:1.7b',
            onUse: (id) async => used.add(id),
            allowCustom: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Active'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);

      // The model in use has nothing to switch to.
      await tester.tap(find.byTooltip('Options for qwen3:1.7b'));
      await tester.pumpAndSettle();
      expect(find.text('Use this model'), findsNothing);
    });

    testWidgets('a fixed catalogue starts at the empty state', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildPortalTheme(brightness: Brightness.light),
          home: AiModelsPage(manager: _FakeManager(), allowCustom: false),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No models yet'), findsOneWidget);
      await tester.tap(find.text('Download a model'));
      await tester.pumpAndSettle();
      expect(find.text('Qwen 3 1.7B'), findsOneWidget);
    });

    testWidgets('a device that cannot run the backend says why', (
      tester,
    ) async {
      final controller = AiModelsController(
        _FakeManager(),
        unsupportedReason: () async => 'Needs Android 14.',
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: buildPortalTheme(brightness: Brightness.light),
          home: AiModelsPage(controller: controller),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Not available on this device'), findsOneWidget);
      expect(find.text('Needs Android 14.'), findsOneWidget);
    });
  });
}
