import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:uuid/uuid.dart';

import 'chat_model.dart';
import 'chatgpt_bot.dart';
import 'gemini_bot.dart';
import 'llama_bot.dart';

part 'bot_model.freezed.dart';

part 'bot_model.g.dart';

abstract class BaseBotModel<M, H> {
  String name;
  BotType type;
  String? api;
  String modelVersion;
  ChatRoom? room;
  String? systemInstructions;

  BaseBotModel({
    this.name = "Bot",
    this.type = BotType.ollama,
    this.api,
    required this.modelVersion,
    this.room,
    this.systemInstructions,
  });

  List<H> convertHistoryModels(List<QueryModel> history);

  Future<QueryModel> chat(String message, {required List<QueryModel> history});

  Stream<String> chatStream(String message);

  M getModel();

  // void updateModel(
  //     {final List<QueryModel> queries = const [], final String? instructions});

  String getInstructions() {
    return "${systemInstructions ?? ""}. ${room?.instructions ?? ""}";
  }

  void addQuery(final String question) {
    if (room == null) {
      throw Exception("Chat room is required to add queries");
    }
    room!.queries.add(QueryModel.empty(query: question));
  }

  // TODO: Need to make sure that there are non-global instructions appended to the model
  void setHistory({final ChatRoom? room}) {
    if (room != null) {
      this.room = room;
    }
    if (this.room == null) {
      throw Exception("Room Cannot be empty when making a query");
    }
  }

  List<QueryModel> getHistory() {
    return room?.queries ?? [];
  }

  static BaseBotModel create({
    final BotType type = BotType.ollama,
    final String systemInstructions = "",
  }) {
    if (type == BotType.gemini) {
      return GeminiBot(systemInstructions: systemInstructions);
    } else if (type == BotType.ollama) {
      return LlamaBot(systemInstructions: systemInstructions);
    } else if (type == BotType.chatGpt) {
      return ChatGptBot(systemInstructions: systemInstructions);
    } else {
      throw Exception("Invalid bot type $type");
    }
  }
}

// for storing as cache
@unfreezed
abstract class BotModel with _$BotModel {
  BotModel._();

  static final String cacheKey = "bot_model";

  factory BotModel({
    @Default("Bot") String name,
    @Default(BotType.ollama) BotType type,
    String? api,
    String? modelVersion,
    @JsonKey(includeFromJson: false, includeToJson: false) ChatRoom? room,
    String? systemInstructions,
  }) = _BotModel;

  factory BotModel.fromJson(final Map<String, dynamic> json) =>
      _$BotModelFromJson(json);

  BaseBotModel toBot() {
    final room = this.room ?? ChatRoom.empty();
    switch (type) {
      case BotType.ollama:
        return LlamaBot(name: name, room: room);
      case BotType.gemini:
        return GeminiBot(room: room);
      case BotType.chatGpt:
        return ChatGptBot(room: room);
      default:
        throw Exception("Unknown bot type error");
    }
  }

  factory BotModel.fromBot(final BaseBotModel baseBot) {
    return BotModel(
      name: baseBot.name,
      type: baseBot.type,
      api: baseBot.api,
      modelVersion: baseBot.modelVersion,
      room: baseBot.room,
      systemInstructions: baseBot.systemInstructions,
    );
  }
}

@unfreezed
abstract class BotAssistantModel with _$BotAssistantModel {
  BotAssistantModel._();

  factory BotAssistantModel({
    String? id,
    required String title,
    @Default("") String description,
    @IconDataConverter() @Default(FontAwesomeIcons.robot) IconData icon,
    required String instructions,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _BotAssistantModel;

  factory BotAssistantModel.create({
    String? id,
    required String title,
    String description = "",
    IconData icon = FontAwesomeIcons.robot,
    required String instructions,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => BotAssistantModel(
    id: id ?? const Uuid().v8(),
    title: title,
    description: description,
    icon: icon,
    instructions: instructions,
    createdAt: createdAt ?? DateTime.now(),
    updatedAt: updatedAt ?? DateTime.now(),
  );

  factory BotAssistantModel.fromJson(Map<String, dynamic> json) =>
      _$BotAssistantModelFromJson(json);
}

@unfreezed
abstract class PromptGroupModel with _$PromptGroupModel {
  PromptGroupModel._();

  factory PromptGroupModel({
    String? id,
    required String title,
    @Default("") String description,
    @Default("") String instruction,
    @IconDataConverter() @Default(FontAwesomeIcons.message) IconData icon,
    @Default([]) List<PromptModel> prompts,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _PromptGroupModel;

  factory PromptGroupModel.create({
    String? id,
    required String title,
    String description = "",
    String instruction = "",
    IconData icon = FontAwesomeIcons.message,
    List<PromptModel> prompts = const [],
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => PromptGroupModel(
    id: id ?? const Uuid().v8(),
    title: title,
    description: description,
    instruction: instruction,
    icon: icon,
    prompts: prompts,
    createdAt: createdAt ?? DateTime.now(),
    updatedAt: updatedAt ?? DateTime.now(),
  );

  factory PromptGroupModel.fromJson(Map<String, dynamic> json) =>
      _$PromptGroupModelFromJson(json);
}

@unfreezed
abstract class PromptModel with _$PromptModel {
  PromptModel._();

  factory PromptModel({
    String? id,
    required String title,
    @Default("") String prompt,
    @Default("") String instruction,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _PromptModel;

  factory PromptModel.create({
    String? id,
    required String title,
    String prompt = "",
    String instruction = "",
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => PromptModel(
    id: id ?? const Uuid().v8(),
    title: title,
    prompt: prompt,
    instruction: instruction,
    createdAt: createdAt ?? DateTime.now(),
    updatedAt: updatedAt ?? DateTime.now(),
  );

  factory PromptModel.fromJson(Map<String, dynamic> json) =>
      _$PromptModelFromJson(json);
}

@unfreezed
abstract class BotTemplateModel with _$BotTemplateModel {
  BotTemplateModel._();

  factory BotTemplateModel({
    String? id,
    required String title,
    @Default(FontAwesomeIcons.file) icon,
    @Default("") String description,
    @Default("") String instruction,
    @Default("English") String language,
    @Default(1) int output,
    @Default(BotTone.professional) BotTone tone,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _BotTemplateModel;

  factory BotTemplateModel.fromJson(final Map<String, dynamic> json) =>
      _$BotTemplateModelFromJson(json);
}

enum BotTone {
  adventure,
  friendly,
  luxury,
  professional,
  persuasive,
  relaxed,
  witty,
  informative,
  marketing,
  educational,
}

class IconDataConverter
    implements JsonConverter<IconData, Map<String, dynamic>> {
  const IconDataConverter();

  @override
  IconData fromJson(Map<String, dynamic> json) {
    return IconData(
      json['codePoint'],
      fontFamily: json['fontFamily'],
      fontPackage: json['fontPackage'],
      matchTextDirection: json['matchTextDirection'],
      fontFamilyFallback: json['fontFamilyFallback'],
    );
  }

  @override
  Map<String, dynamic> toJson(IconData object) {
    return {
      'codePoint': object.codePoint,
      'fontFamily': object.fontFamily,
      'fontPackage': object.fontPackage,
      'matchTextDirection': object.matchTextDirection,
      'fontFamilyFallback': object.fontFamilyFallback,
    };
  }
}
