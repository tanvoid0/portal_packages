import 'package:flutter/cupertino.dart';
import 'package:portal_bot/data/models/bot/bot_model.dart';
import 'package:portal_bot/data/models/bot/chat_model.dart';

class BotService {
  BaseBotModel bot;
  BotType botType;

  BotService({
    BotType initialType = BotType.ollama,
  })  : botType = initialType,
        bot = BaseBotModel.create();

  void setBotType(BotType type) {
    botType = type;
    bot = BaseBotModel.create();
  }

  void configureBot({
    required String name,
    required String instructions,
    required BotType type,
  }) {
    bot
      ..name = name
      ..type = type
      ..systemInstructions = instructions;
  }

  Stream<String> ask(String question, ChatRoom room) {
    debugPrint("Asking bot: $botType, question: $question");
    bot.setHistory(room: room);
    return bot.chatStream(question);
  }
}
