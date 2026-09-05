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
