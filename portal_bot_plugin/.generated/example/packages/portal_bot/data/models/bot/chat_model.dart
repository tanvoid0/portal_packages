import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:uuid/uuid.dart';

part 'chat_model.freezed.dart';
part 'chat_model.g.dart';

@JsonEnum()
enum BotType {
  unknown,
  @JsonValue("gemini")
  gemini,
  @JsonValue("ollama")
  ollama,
  @JsonValue("chat_gpt")
  chatGpt;
}

@Freezed(makeCollectionsUnmodifiable: false)
abstract class ChatHistory with _$ChatHistory {
  static const String cacheKey = 'chat_history';
  ChatHistory._();
  @override
  String get key => cacheKey;

  @override
  bool get isList => false;

  String getInstruction(final String? roomId) {
    return "$instruction\n${rooms.firstWhere((item) => item.id == roomId).instructions}";
  }

  factory ChatHistory({
    @Default('') final String title,
    @Default('') final String instruction,
    @Default([]) final List<ChatRoom> rooms,
    @JsonKey(name: 'botType', unknownEnumValue: BotType.unknown) @Default(BotType.ollama) final BotType botType,
    DateTime? createdAt,
  }) = _ChatHistory;

  factory ChatHistory.fromJson(Map<String, dynamic> json) =>
      _$ChatHistoryFromJson(json);

  @override
  ChatHistory fromJson(final Map<String, dynamic> json) => _$ChatHistoryFromJson(json);

  @override
  ChatHistory defaultObject() => ChatHistory.empty();

  factory ChatHistory.empty() => ChatHistory(
    createdAt: DateTime.now(),
  );
}

@Freezed(makeCollectionsUnmodifiable: false)
abstract class ChatRoom with _$ChatRoom {
  factory ChatRoom.empty({final QueryModel? query}) {
    return ChatRoom(
      id: const Uuid().v8(),
      title: query?.query.data ?? "",
      queries: null == query ? [] : [query],
      createdAt: DateTime.now(),
      updateAt: DateTime.now(),
    );
  }

  factory ChatRoom({
    String? id,
    @Default("") String title,
    @Default("") String instructions,
    @Default([]) List<QueryModel> queries,
    DateTime? createdAt,
    DateTime? updateAt,
  }) = _ChatRoom;

  factory ChatRoom.fromJson(final Map<String, dynamic> json) =>
      _$ChatRoomFromJson(json);
}

@Freezed(makeCollectionsUnmodifiable: false)
abstract class QueryModel with _$QueryModel {
  QueryModel._();

  factory QueryModel.empty(
          {required final String query, final String? response}) =>
      QueryModel(
        id: const Uuid().v8(),
        query: ChatMessage.empty(data: query),
        response: ChatMessage.empty(data: response ?? ""),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

  factory QueryModel({
    String? id,
    required ChatMessage query,
    ChatMessage? response,
    final DateTime? createdAt,
    final DateTime? updatedAt,
  }) = _QueryModel;

  factory QueryModel.fromJson(Map<String, dynamic> json) =>
      _$QueryModelFromJson(json);
}

enum ChatMessageType { text, audio, image, video }

enum MessageStatus { sent, notSeen, seen }

final now = DateTime.now();

@unfreezed
abstract class ChatMessage with _$ChatMessage {
  ChatMessage._();

  void appendStreamMessage(final String message) {
    data += message;
  }

  factory ChatMessage.empty({required final String data}) => ChatMessage(
        id: const Uuid().v8(),
        data: data,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

  factory ChatMessage({
    final String? id,
    @Default('') String data,
    @Default(ChatMessageType.text) final ChatMessageType messageType,
    @Default(MessageStatus.sent) final MessageStatus messageStatus,
    @Default(true) bool isSender,
    final DateTime? createdAt,
    final DateTime? updatedAt,
  }) = _ChatMessage;

  factory ChatMessage.fromJson(final Map<String, dynamic> json) =>
      _$ChatMessageFromJson(json);
}
