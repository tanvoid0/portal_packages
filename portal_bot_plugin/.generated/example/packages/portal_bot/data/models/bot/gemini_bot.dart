import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

import '../../env.dart';
import 'bot_model.dart';
import 'chat_model.dart';

class GeminiBot extends BaseBotModel<GenerativeModel, Content> {
  GeminiBot({
    final String? name,
    final String? systemInstructions,
    super.room,
    String? api,
  }) : super(
         name: name ?? "Gemini",
         api: api ?? Env.geminiApiKey,
         modelVersion: 'gemini-1.5-flash',
         systemInstructions: systemInstructions ?? "",
         type: BotType.gemini,
       );

  @override
  List<Content> convertHistoryModels(final List<QueryModel> history) {
    return history.isEmpty
        ? []
        : history
              .expand<Content>(
                (item) => [
                  Content.multi([TextPart(item.query.data)]),
                  if (item.response != null)
                    Content.model([TextPart(item.response!.data)]),
                ],
              )
              .toList();
  }

  @override
  Future<QueryModel> chat(
    final String message, {
    required final List<QueryModel> history,
  }) async {
    // final content = Content.text(message);
    // final chat = model.startChat(history: convertHistoryModels(history));
    // final GenerateContentResponse response = await chat.sendMessage(content);
    final response = await getModel().generateContent([
      ...convertHistoryModels(history),
      Content.text(message),
    ]);
    debugPrint(response.text);
    return QueryModel.empty(
      query: message,
      response: response.text ?? "Something Occurred",
    );
  }

  @override
  Stream<String> chatStream(final String message) {
    return getModel()
        .generateContentStream([
          ...convertHistoryModels(getHistory()),
          Content.text(message),
        ])
        .map((GenerateContentResponse item) => item.text.toString());
  }

  @override
  GenerativeModel getModel() {
    return GenerativeModel(
      model: modelVersion,
      apiKey: api!,
      // safetySettings: Adjust safety settings
      // See https://ai.google.dev/gemini-api/docs/safety-settings
      generationConfig: GenerationConfig(
        temperature: 1,
        topK: 64,
        topP: 0.95,
        maxOutputTokens: 8192,
        responseMimeType: 'text/plain',
      ),
      systemInstruction: Content.system(getInstructions()),
    );
  }
}

Future<String?> geminiBot({
  final String? apiKey,
  required final String message,
  final String? instructions,
}) async {
  if (apiKey == null) {
    stderr.writeln(r'No $GEMINI_API_KEY environment variable');
    exit(1);
  }

  final model = GenerativeModel(
    model: 'gemini-1.5-flash',
    apiKey: apiKey,
    // safetySettings: Adjust safety settings
    // See https://ai.google.dev/gemini-api/docs/safety-settings
    generationConfig: GenerationConfig(
      temperature: 1,
      topK: 64,
      topP: 0.95,
      maxOutputTokens: 8192,
      responseMimeType: 'text/plain',
    ),
    systemInstruction: Content.system(instructions ?? ""),
  );

  final chat = model.startChat(
    history: [
      Content.multi([TextPart('Hi!')]),
      Content.model([
        TextPart(
          'Hi there! 👋  It\'s great to hear from you.  How can I help you today?  Whether you need a coding hand, a schedule refresh, or just a friendly ear, I\'m here to make your day a little bit easier! 😊 \n',
        ),
      ]),
    ],
  );
  final content = Content.text(message);

  final response = await chat.sendMessage(content);
  debugPrint(response.text);
  return response.text;
}
