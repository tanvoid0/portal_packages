// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shopping_list.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ShoppingListImpl _$$ShoppingListImplFromJson(Map<String, dynamic> json) =>
    _$ShoppingListImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
      isDefault: json['is_default'] as bool? ?? false,
      icon: json['icon'] as String?,
    );

Map<String, dynamic> _$$ShoppingListImplToJson(_$ShoppingListImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'sort_order': instance.sortOrder,
      'is_default': instance.isDefault,
      'icon': instance.icon,
    };
