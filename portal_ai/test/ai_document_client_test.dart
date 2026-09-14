import 'package:flutter_test/flutter_test.dart';
import 'package:portal_ai/portal_ai.dart';

class _FakeCompletionClient implements AiCompletionClient {
  _FakeCompletionClient(this.reply);

  final String reply;
  String? seenPrompt;

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<String> complete({
    required String systemPrompt,
    required String userPrompt,
    AiSamplerConfig sampler = const AiSamplerConfig(),
    bool jsonMode = false,
  }) async {
    seenPrompt = userPrompt;
    return reply;
  }

  @override
  Stream<String> completeStream({
    required String systemPrompt,
    required String userPrompt,
    AiSamplerConfig sampler = const AiSamplerConfig(),
  }) => Stream<String>.value(reply);
}

class _CountingClient extends _FakeCompletionClient {
  _CountingClient(this.prompts) : super('');

  final List<String> prompts;

  @override
  Future<String> complete({
    required String systemPrompt,
    required String userPrompt,
    AiSamplerConfig sampler = const AiSamplerConfig(),
    bool jsonMode = false,
  }) async {
    prompts.add(userPrompt);
    return '{"currency":"GBP","transactions":[{"n":${prompts.length}}]}';
  }
}

void main() {
  AiDocumentClient clientReturning(
    dynamic response, {
    List<Map<String, dynamic>>? log,
  }) {
    return AiDocumentClient(
      postMultipart:
          (
            path, {
            required fieldName,
            required fileBytes,
            required filename,
            fields,
          }) async {
            log?.add(<String, dynamic>{
              'path': path,
              'fieldName': fieldName,
              'filename': filename,
              'fields': fields,
            });
            return response;
          },
    );
  }

  test('posts the file and returns the text', () async {
    final log = <Map<String, dynamic>>[];
    final document = await clientReturning(<String, dynamic>{
      'text': 'Klarna 4 x 24.99',
      'source': 'vision',
    }, log: log).extractText(bytes: <int>[1, 2], filename: 'contract.pdf');

    expect(document.text, 'Klarna 4 x 24.99');
    expect(document.source, 'vision');
    expect(log.single['path'], '/ai/extract-text');
    expect(log.single['fieldName'], 'file');
    expect(log.single['fields'], <String, String>{
      'feature': 'document-extract',
    });
  });

  test('an empty read is an error, not an empty document', () {
    expect(
      () => clientReturning(<String, dynamic>{
        'text': '   ',
      }).extractText(bytes: <int>[1], filename: 'blank.png'),
      throwsA(isA<AiCompletionException>()),
    );
  });

  test('extractJson feeds the extracted text to the model', () async {
    final model = _FakeCompletionClient('{"instalments": 4}');
    final result = await clientReturning(<String, dynamic>{'text': 'pay in 4'})
        .extractJson(
          client: model,
          bytes: <int>[1],
          filename: 'contract.pdf',
          instruction: 'Return JSON',
        );

    expect(model.seenPrompt, 'pay in 4');
    expect(result, <String, dynamic>{'instalments': 4});
  });

  test('extractJson reads a long document in pieces and merges the rows', () async {
    final prompts = <String>[];
    final model = _CountingClient(prompts);
    final text = List.generate(40, (i) => 'line $i').join('\n');
    final result = await clientReturning(<String, dynamic>{'text': text})
        .extractJson(
          client: model,
          bytes: <int>[1],
          filename: 'statement.pdf',
          instruction: 'Return JSON',
          maxChunkChars: 60,
        );

    expect(prompts.length, greaterThan(1));
    expect(prompts.join(), text);
    for (final p in prompts) {
      expect(p.length, lessThanOrEqualTo(60));
      expect(p.endsWith('\n') || p == prompts.last, isTrue);
    }
    final rows = (result as Map)['transactions'] as List;
    expect(rows.length, prompts.length);
    expect(result['currency'], 'GBP');
  });

  test('mergeJson concatenates bare lists', () {
    expect(
      AiDocumentClient.mergeJson(<dynamic>[
        <dynamic>[1],
        <dynamic>[2, 3],
      ]),
      <dynamic>[1, 2, 3],
    );
  });

  test('decodeJsonReply strips a code fence', () {
    expect(
      AiDocumentClient.decodeJsonReply('```json\n{"a": 1}\n```'),
      <String, dynamic>{'a': 1},
    );
  });

  test('decodeJsonReply rejects prose', () {
    expect(
      () => AiDocumentClient.decodeJsonReply('Sorry, I cannot read that.'),
      throwsA(isA<AiCompletionException>()),
    );
  });
}
