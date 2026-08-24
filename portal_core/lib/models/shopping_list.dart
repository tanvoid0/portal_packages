import 'package:freezed_annotation/freezed_annotation.dart';
import 'shopping_json.dart';

part 'shopping_list.freezed.dart';
part 'shopping_list.g.dart';

@freezed
class ShoppingList with _$ShoppingList {
  const factory ShoppingList({
    required String id,
    required String name,
    @JsonKey(name: 'sort_order') @Default(0) int sortOrder,
    @JsonKey(name: 'is_default') @Default(false) bool isDefault,
    String? icon,
  }) = _ShoppingList;

  factory ShoppingList.fromJson(Map<String, dynamic> json) =>
      _$ShoppingListFromJson(prepareShoppingListJson(json));
}
