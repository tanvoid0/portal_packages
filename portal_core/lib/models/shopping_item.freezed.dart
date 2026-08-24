// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'shopping_item.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

ShoppingItem _$ShoppingItemFromJson(Map<String, dynamic> json) {
  return _ShoppingItem.fromJson(json);
}

/// @nodoc
mixin _$ShoppingItem {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get category => throw _privateConstructorUsedError;
  int get quantity => throw _privateConstructorUsedError;
  int get priority => throw _privateConstructorUsedError; // 1-5
  ShoppingStatus get status => throw _privateConstructorUsedError;
  @JsonKey(name: 'linked_quest_id')
  String? get linkedQuestId => throw _privateConstructorUsedError;
  @JsonKey(name: 'list_id')
  String? get listId => throw _privateConstructorUsedError;
  String get source => throw _privateConstructorUsedError;
  @JsonKey(name: 'source_id')
  String? get sourceId => throw _privateConstructorUsedError;
  String get aisle => throw _privateConstructorUsedError;
  @JsonKey(name: 'image_url')
  String? get imageUrl => throw _privateConstructorUsedError;
  ItemUnit get unit => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $ShoppingItemCopyWith<ShoppingItem> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ShoppingItemCopyWith<$Res> {
  factory $ShoppingItemCopyWith(
          ShoppingItem value, $Res Function(ShoppingItem) then) =
      _$ShoppingItemCopyWithImpl<$Res, ShoppingItem>;
  @useResult
  $Res call(
      {String id,
      String name,
      String category,
      int quantity,
      int priority,
      ShoppingStatus status,
      @JsonKey(name: 'linked_quest_id') String? linkedQuestId,
      @JsonKey(name: 'list_id') String? listId,
      String source,
      @JsonKey(name: 'source_id') String? sourceId,
      String aisle,
      @JsonKey(name: 'image_url') String? imageUrl,
      ItemUnit unit});

  $ItemUnitCopyWith<$Res> get unit;
}

/// @nodoc
class _$ShoppingItemCopyWithImpl<$Res, $Val extends ShoppingItem>
    implements $ShoppingItemCopyWith<$Res> {
  _$ShoppingItemCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? category = null,
    Object? quantity = null,
    Object? priority = null,
    Object? status = null,
    Object? linkedQuestId = freezed,
    Object? listId = freezed,
    Object? source = null,
    Object? sourceId = freezed,
    Object? aisle = null,
    Object? imageUrl = freezed,
    Object? unit = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      category: null == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as String,
      quantity: null == quantity
          ? _value.quantity
          : quantity // ignore: cast_nullable_to_non_nullable
              as int,
      priority: null == priority
          ? _value.priority
          : priority // ignore: cast_nullable_to_non_nullable
              as int,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as ShoppingStatus,
      linkedQuestId: freezed == linkedQuestId
          ? _value.linkedQuestId
          : linkedQuestId // ignore: cast_nullable_to_non_nullable
              as String?,
      listId: freezed == listId
          ? _value.listId
          : listId // ignore: cast_nullable_to_non_nullable
              as String?,
      source: null == source
          ? _value.source
          : source // ignore: cast_nullable_to_non_nullable
              as String,
      sourceId: freezed == sourceId
          ? _value.sourceId
          : sourceId // ignore: cast_nullable_to_non_nullable
              as String?,
      aisle: null == aisle
          ? _value.aisle
          : aisle // ignore: cast_nullable_to_non_nullable
              as String,
      imageUrl: freezed == imageUrl
          ? _value.imageUrl
          : imageUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      unit: null == unit
          ? _value.unit
          : unit // ignore: cast_nullable_to_non_nullable
              as ItemUnit,
    ) as $Val);
  }

  @override
  @pragma('vm:prefer-inline')
  $ItemUnitCopyWith<$Res> get unit {
    return $ItemUnitCopyWith<$Res>(_value.unit, (value) {
      return _then(_value.copyWith(unit: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$ShoppingItemImplCopyWith<$Res>
    implements $ShoppingItemCopyWith<$Res> {
  factory _$$ShoppingItemImplCopyWith(
          _$ShoppingItemImpl value, $Res Function(_$ShoppingItemImpl) then) =
      __$$ShoppingItemImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String name,
      String category,
      int quantity,
      int priority,
      ShoppingStatus status,
      @JsonKey(name: 'linked_quest_id') String? linkedQuestId,
      @JsonKey(name: 'list_id') String? listId,
      String source,
      @JsonKey(name: 'source_id') String? sourceId,
      String aisle,
      @JsonKey(name: 'image_url') String? imageUrl,
      ItemUnit unit});

  @override
  $ItemUnitCopyWith<$Res> get unit;
}

/// @nodoc
class __$$ShoppingItemImplCopyWithImpl<$Res>
    extends _$ShoppingItemCopyWithImpl<$Res, _$ShoppingItemImpl>
    implements _$$ShoppingItemImplCopyWith<$Res> {
  __$$ShoppingItemImplCopyWithImpl(
      _$ShoppingItemImpl _value, $Res Function(_$ShoppingItemImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? category = null,
    Object? quantity = null,
    Object? priority = null,
    Object? status = null,
    Object? linkedQuestId = freezed,
    Object? listId = freezed,
    Object? source = null,
    Object? sourceId = freezed,
    Object? aisle = null,
    Object? imageUrl = freezed,
    Object? unit = null,
  }) {
    return _then(_$ShoppingItemImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      category: null == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as String,
      quantity: null == quantity
          ? _value.quantity
          : quantity // ignore: cast_nullable_to_non_nullable
              as int,
      priority: null == priority
          ? _value.priority
          : priority // ignore: cast_nullable_to_non_nullable
              as int,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as ShoppingStatus,
      linkedQuestId: freezed == linkedQuestId
          ? _value.linkedQuestId
          : linkedQuestId // ignore: cast_nullable_to_non_nullable
              as String?,
      listId: freezed == listId
          ? _value.listId
          : listId // ignore: cast_nullable_to_non_nullable
              as String?,
      source: null == source
          ? _value.source
          : source // ignore: cast_nullable_to_non_nullable
              as String,
      sourceId: freezed == sourceId
          ? _value.sourceId
          : sourceId // ignore: cast_nullable_to_non_nullable
              as String?,
      aisle: null == aisle
          ? _value.aisle
          : aisle // ignore: cast_nullable_to_non_nullable
              as String,
      imageUrl: freezed == imageUrl
          ? _value.imageUrl
          : imageUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      unit: null == unit
          ? _value.unit
          : unit // ignore: cast_nullable_to_non_nullable
              as ItemUnit,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ShoppingItemImpl implements _ShoppingItem {
  const _$ShoppingItemImpl(
      {required this.id,
      required this.name,
      this.category = '',
      this.quantity = 1,
      this.priority = 1,
      this.status = ShoppingStatus.pending,
      @JsonKey(name: 'linked_quest_id') this.linkedQuestId,
      @JsonKey(name: 'list_id') this.listId,
      this.source = 'manual',
      @JsonKey(name: 'source_id') this.sourceId,
      this.aisle = '',
      @JsonKey(name: 'image_url') this.imageUrl,
      this.unit = const ItemUnit()});

  factory _$ShoppingItemImpl.fromJson(Map<String, dynamic> json) =>
      _$$ShoppingItemImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  @JsonKey()
  final String category;
  @override
  @JsonKey()
  final int quantity;
  @override
  @JsonKey()
  final int priority;
// 1-5
  @override
  @JsonKey()
  final ShoppingStatus status;
  @override
  @JsonKey(name: 'linked_quest_id')
  final String? linkedQuestId;
  @override
  @JsonKey(name: 'list_id')
  final String? listId;
  @override
  @JsonKey()
  final String source;
  @override
  @JsonKey(name: 'source_id')
  final String? sourceId;
  @override
  @JsonKey()
  final String aisle;
  @override
  @JsonKey(name: 'image_url')
  final String? imageUrl;
  @override
  @JsonKey()
  final ItemUnit unit;

  @override
  String toString() {
    return 'ShoppingItem(id: $id, name: $name, category: $category, quantity: $quantity, priority: $priority, status: $status, linkedQuestId: $linkedQuestId, listId: $listId, source: $source, sourceId: $sourceId, aisle: $aisle, imageUrl: $imageUrl, unit: $unit)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ShoppingItemImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.category, category) ||
                other.category == category) &&
            (identical(other.quantity, quantity) ||
                other.quantity == quantity) &&
            (identical(other.priority, priority) ||
                other.priority == priority) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.linkedQuestId, linkedQuestId) ||
                other.linkedQuestId == linkedQuestId) &&
            (identical(other.listId, listId) || other.listId == listId) &&
            (identical(other.source, source) || other.source == source) &&
            (identical(other.sourceId, sourceId) ||
                other.sourceId == sourceId) &&
            (identical(other.aisle, aisle) || other.aisle == aisle) &&
            (identical(other.imageUrl, imageUrl) ||
                other.imageUrl == imageUrl) &&
            (identical(other.unit, unit) || other.unit == unit));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      name,
      category,
      quantity,
      priority,
      status,
      linkedQuestId,
      listId,
      source,
      sourceId,
      aisle,
      imageUrl,
      unit);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ShoppingItemImplCopyWith<_$ShoppingItemImpl> get copyWith =>
      __$$ShoppingItemImplCopyWithImpl<_$ShoppingItemImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ShoppingItemImplToJson(
      this,
    );
  }
}

abstract class _ShoppingItem implements ShoppingItem {
  const factory _ShoppingItem(
      {required final String id,
      required final String name,
      final String category,
      final int quantity,
      final int priority,
      final ShoppingStatus status,
      @JsonKey(name: 'linked_quest_id') final String? linkedQuestId,
      @JsonKey(name: 'list_id') final String? listId,
      final String source,
      @JsonKey(name: 'source_id') final String? sourceId,
      final String aisle,
      @JsonKey(name: 'image_url') final String? imageUrl,
      final ItemUnit unit}) = _$ShoppingItemImpl;

  factory _ShoppingItem.fromJson(Map<String, dynamic> json) =
      _$ShoppingItemImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  String get category;
  @override
  int get quantity;
  @override
  int get priority;
  @override // 1-5
  ShoppingStatus get status;
  @override
  @JsonKey(name: 'linked_quest_id')
  String? get linkedQuestId;
  @override
  @JsonKey(name: 'list_id')
  String? get listId;
  @override
  String get source;
  @override
  @JsonKey(name: 'source_id')
  String? get sourceId;
  @override
  String get aisle;
  @override
  @JsonKey(name: 'image_url')
  String? get imageUrl;
  @override
  ItemUnit get unit;
  @override
  @JsonKey(ignore: true)
  _$$ShoppingItemImplCopyWith<_$ShoppingItemImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
