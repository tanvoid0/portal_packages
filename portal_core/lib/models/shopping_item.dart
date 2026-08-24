import 'package:freezed_annotation/freezed_annotation.dart';
import 'item_unit.dart';
import 'shopping_json.dart';

part 'shopping_item.freezed.dart';
part 'shopping_item.g.dart';

enum ShoppingStatus {
  pending,
  purchased;

  String get displayName {
    switch (this) {
      case ShoppingStatus.pending:
        return 'Pending';
      case ShoppingStatus.purchased:
        return 'Purchased';
    }
  }
}

@freezed
class ShoppingItem with _$ShoppingItem {
  const factory ShoppingItem({
    required String id,
    required String name,
    @Default('') String category,
    @Default(1) int quantity,
    @Default(1) int priority, // 1-5
    @Default(ShoppingStatus.pending) ShoppingStatus status,
    @JsonKey(name: 'linked_quest_id') String? linkedQuestId,
    @JsonKey(name: 'list_id') String? listId,
    @Default('manual') String source,
    @JsonKey(name: 'source_id') String? sourceId,
    @Default('') String aisle,
    @JsonKey(name: 'image_url') String? imageUrl,
    @Default(ItemUnit())
    ItemUnit unit,
  }) = _ShoppingItem;

  factory ShoppingItem.fromJson(Map<String, dynamic> json) =>
      _$ShoppingItemFromJson(prepareShoppingItemJson(json));
}
