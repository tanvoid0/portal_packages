import 'package:chat_gpt_sdk/chat_gpt_sdk.dart';
import 'package:portal_bot/data/env.dart';

import 'bot_model.dart';
import 'chat_model.dart';

class ChatGptBot extends BaseBotModel<OpenAI, Map<String, dynamic>> {
  ChatGptBot(
      {final String? name,
      final String? systemInstructions,
      super.room,
      String? api})
      : super(
          name: name ?? "ChatGPT",
          api: api ?? Env.chatgptApiKey,
          modelVersion: 'gpt-3.5-turbo',
          systemInstructions: systemInstructions ?? "",
          type: BotType.chatGpt,
        );

  @override
  Future<QueryModel> chat(final String message,
      {required List<QueryModel> history}) async {
    final request = ChatCompleteText(
        messages: convertHistoryModels(history),
        maxToken: 200,
        model: GptTurboChatModel());

    final response = await getModel().onChatCompletion(request: request);
    return QueryModel.empty(
        query: message, response: response!.choices.join(" "));
  }

  @override
  Stream<String> chatStream(String message) {
    final request = ChatCompleteText(
        messages: convertHistoryModels(getHistory()),
        maxToken: 200,
        model: GptTurboChatModel());
    return getModel().onChatCompletionSSE(request: request).map(
        (ChatResponseSSE item) =>
            (item.choices!.isEmpty ? "" : item.choices![0].message?.content) ??
            "");
  }

  @override
  List<Map<String, dynamic>> convertHistoryModels(List<QueryModel> history) {
    return history.isEmpty
        ? []
        : history.expand<Map<String, dynamic>>((item) {
            return [
              Map.of({"role": "user", "content": item.query.data}),
              Map.of({"role": "model", "content": item.response?.data}),
            ];
          }).toList();
  }

  @override
  OpenAI getModel() {
    return OpenAI.instance.build(
      token: api,
      baseOption: HttpSetup(receiveTimeout: const Duration(seconds: 5)),
      enableLog: true,
    );
  }
}

final OpenAI _client = OpenAI.instance.build(
    token: Env.chatgptApiKey,
    baseOption: HttpSetup(receiveTimeout: const Duration(seconds: 5)),
    enableLog: true);

Future<ChatCTResponse?> chatgptBot({
  final String? apiKey,
  required final String message,
  final String? instructions,
}) async {
  final request = ChatCompleteText(messages: [
    Map.of({"role": "user", "content": 'Hello!'})
  ], maxToken: 200, model: GptTurboChatModel());

  final response = await _client.onChatCompletion(request: request);
  return response;
}

Stream<ChatResponseSSE> chatgptBotStream({
  final String? apiKey,
  required final String message,
  final String? instructions,
}) {
  final request = ChatCompleteText(messages: [
    Map.of({"role": "user", "content": 'Hello!'})
  ], maxToken: 200, model: GptTurboChatModel());

  return _client.onChatCompletionSSE(request: request);
}
