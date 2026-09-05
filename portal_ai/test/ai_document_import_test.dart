import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portal_ai/portal_ai.dart';

class _FakeCompletionClient implements AiCompletionClient {
  _FakeCompletionClient(this.reply);

  final String reply;

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<String> complete({
    required String systemPrompt,
    required String userPrompt,
    AiSamplerConfig sampler = const AiSamplerConfig(),
    bool jsonMode = false,
  }) async => reply;

  @override
  Stream<String> completeStream({
    required String systemPrompt,
    required String userPrompt,
    AiSamplerConfig sampler = const AiSamplerConfig(),
  }) => Stream<String>.value(reply);
}

void main() {
  AiDocumentClient documentsReturning(String text) => AiDocumentClient(
    postMultipart:
        (
          path, {
          required fieldName,
          required fileBytes,
          required filename,
          fields,
        }) async => <String, dynamic>{'text': text, 'source': 'vision'},
  );

  Future<void> pumpSheet(
    WidgetTester tester, {
    required String reply,
    required Future<void> Function(List<AiProposal>) onApply,
    List<AiProposal> Function(dynamic)? toProposals,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AiDocumentImportSheet(
            documents: documentsReturning('Klarna, 4 payments'),
            client: _FakeCompletionClient(reply),
            instruction: 'Return JSON',
            pick: () async =>
                const AiPickedFile(bytes: <int>[1, 2, 3], name: 'contract.pdf'),
            toProposals:
                toProposals ??
                (json) => [
                  for (final row in json as List)
                    AiProposal(
                      id: row['id'] as String,
                      title: row['title'] as String,
                    ),
                ],
            onApply: onApply,
          ),
        ),
      ),
    );
  }

  testWidgets('applies only the rows left ticked', (tester) async {
    List<AiProposal>? applied;
    await pumpSheet(
      tester,
      reply: '[{"id":"a","title":"Payment 1"},{"id":"b","title":"Payment 2"}]',
      onApply: (accepted) async => applied = accepted,
    );

    await tester.tap(find.text('Choose a file'));
    await tester.pumpAndSettle();

    expect(find.text('Payment 1'), findsOneWidget);
    expect(find.text('contract.pdf'), findsOneWidget);
    expect(
      find.text('Add selected (2)'),
      findsOneWidget,
      reason: 'all ticked by default',
    );

    await tester.tap(find.text('Payment 2'));
    await tester.pump();
    await tester.tap(find.text('Add selected (1)'));
    await tester.pumpAndSettle();

    expect(applied, isNotNull);
    expect(applied!.single.id, 'a');
  });

  testWidgets('nothing is written when the model returns junk', (tester) async {
    var applyCalled = false;
    await pumpSheet(
      tester,
      reply: 'I could not read that document.',
      onApply: (_) async => applyCalled = true,
    );

    await tester.tap(find.text('Choose a file'));
    await tester.pumpAndSettle();

    expect(applyCalled, isFalse);
    expect(find.textContaining('did not return usable data'), findsOneWidget);
    expect(
      find.text('Choose a file'),
      findsOneWidget,
      reason: 'back to the start',
    );
  });

  testWidgets('an empty read says so instead of showing an empty list', (
    tester,
  ) async {
    await pumpSheet(tester, reply: '[]', onApply: (_) async {});

    await tester.tap(find.text('Choose a file'));
    await tester.pumpAndSettle();

    expect(find.text('Nothing to import from that file.'), findsOneWidget);
  });

  testWidgets('a failed write keeps the review open', (tester) async {
    await pumpSheet(
      tester,
      reply: '[{"id":"a","title":"Payment 1"}]',
      onApply: (_) async => throw Exception('offline'),
    );

    await tester.tap(find.text('Choose a file'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add selected (1)'));
    await tester.pumpAndSettle();

    expect(find.textContaining('offline'), findsOneWidget);
    expect(find.text('Payment 1'), findsOneWidget);
  });
}
