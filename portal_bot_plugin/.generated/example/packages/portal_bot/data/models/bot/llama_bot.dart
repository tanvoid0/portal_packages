import 'bot_model.dart';
import 'chat_model.dart';
import 'package:portal_bot/data/env.dart';
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;

class LlamaBot extends BaseBotModel<OllamaRawClient, Map<String, String>> {
  LlamaBot({
    final String? name,
    final String? api,
    super.systemInstructions,
    super.room,
  }) : super(
    name: name ?? "Llama",
    api: api ?? Env.ollamaApiKey,
    modelVersion: 'deepseek-r1:1.5b',
    type: BotType.ollama,
  );

  @override
  Future<QueryModel> chat(
      final String message, {
        required List<QueryModel> history,
      }) async {
    final res = await getModel().chat(
      model: modelVersion,
      messages: convertHistoryModels(history),
    );

    return QueryModel.empty(
      query: message,
      response: res,
    );
  }

  @override
  Stream<String> chatStream(String message) {
    final history = [
      ...convertHistoryModels(getHistory()),
      {'role': 'user', 'content': message}
    ];

    if (getInstructions().isNotEmpty) {
      history.add({'role': 'system', 'content': getInstructions()});
    }

    return getModel().chatStream(
      model: modelVersion,
      messages: history,
    );
  }

  @override
  List<Map<String, String>> convertHistoryModels(List<QueryModel> history) {
    return history.expand((item) {
      final msgs = [
        {'role': 'user', 'content': item.query.data}
      ];
      if (item.response != null) {
        msgs.add({'role': 'assistant', 'content': item.response!.data});
      }
      return msgs;
    }).toList();
  }

  @override
  OllamaRawClient getModel() {
    return OllamaRawClient(apiUrl: api ?? 'http://localhost:11434');
  }
}

class OllamaRawClient {
  final String apiUrl;

  OllamaRawClient({this.apiUrl = 'http://localhost:11434'});

  Future<String> chat({
    required String model,
    required List<Map<String, String>> messages,
  }) async {
    final uri = Uri.parse('$apiUrl/api/chat');
    final payload = {
      'model': model,
      'messages': messages,
      'stream': false,
    };

    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );

    if (res.statusCode != 200) {
      throw Exception('Ollama Error: ${res.body}');
    }

    final data = jsonDecode(res.body);
    return data['message']['content'] ?? '';
  }

  Stream<String> chatStream({
    required String model,
    required List<Map<String, String>> messages,
  }) async* {
    final uri = Uri.parse('$apiUrl/api/chat');
    final payload = {
      'model': model,
      'messages': messages,
      'stream': true,
    };

    final req = http.Request('POST', uri)
      ..headers['Content-Type'] = 'application/json'
      ..body = jsonEncode(payload);

    final res = await req.send();

    if (res.statusCode != 200) {
      throw Exception('Ollama Stream Error: ${res.reasonPhrase}');
    }

    final stream = res.stream.transform(utf8.decoder);
    await for (final chunk in stream) {
      // Ollama streams JSON lines (SSE-style)
      for (final line in LineSplitter.split(chunk)) {
        if (line.trim().isEmpty) continue;
        final jsonData = jsonDecode(line);
        yield jsonData['message']['content'] ?? '';
      }
    }
  }
}
