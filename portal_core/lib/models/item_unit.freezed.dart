// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'item_unit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

ItemUnit _$ItemUnitFromJson(Map<String, dynamic> json) {
  return _ItemUnit.fromJson(json);
}

/// @nodoc
mixin _$ItemUnit {
  UnitType get type => throw _privateConstructorUsedError;
  @JsonKey(name: 'custom_unit')
  String get customUnit => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $ItemUnitCopyWith<ItemUnit> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ItemUnitCopyWith<$Res> {
  factory $ItemUnitCopyWith(ItemUnit value, $Res Function(ItemUnit) then) =
      _$ItemUnitCopyWithImpl<$Res, ItemUnit>;
  @useResult
  $Res call({UnitType type, @JsonKey(name: 'custom_unit') String customUnit});
}

/// @nodoc
class _$ItemUnitCopyWithImpl<$Res, $Val extends ItemUnit>
    implements $ItemUnitCopyWith<$Res> {
  _$ItemUnitCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? type = null,
    Object? customUnit = null,
  }) {
    return _then(_value.copyWith(
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as UnitType,
      customUnit: null == customUnit
          ? _value.customUnit
          : customUnit // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ItemUnitImplCopyWith<$Res>
    implements $ItemUnitCopyWith<$Res> {
  factory _$$ItemUnitImplCopyWith(
          _$ItemUnitImpl value, $Res Function(_$ItemUnitImpl) then) =
      __$$ItemUnitImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({UnitType type, @JsonKey(name: 'custom_unit') String customUnit});
}

/// @nodoc
class __$$ItemUnitImplCopyWithImpl<$Res>
    extends _$ItemUnitCopyWithImpl<$Res, _$ItemUnitImpl>
    implements _$$ItemUnitImplCopyWith<$Res> {
  __$$ItemUnitImplCopyWithImpl(
      _$ItemUnitImpl _value, $Res Function(_$ItemUnitImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? type = null,
    Object? customUnit = null,
  }) {
    return _then(_$ItemUnitImpl(
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as UnitType,
      customUnit: null == customUnit
          ? _value.customUnit
          : customUnit // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ItemUnitImpl extends _ItemUnit {
  const _$ItemUnitImpl(
      {this.type = UnitType.count,
      @JsonKey(name: 'custom_unit') this.customUnit = ''})
      : super._();

  factory _$ItemUnitImpl.fromJson(Map<String, dynamic> json) =>
      _$$ItemUnitImplFromJson(json);

  @override
  @JsonKey()
  final UnitType type;
  @override
  @JsonKey(name: 'custom_unit')
  final String customUnit;

  @override
  String toString() {
    return 'ItemUnit(type: $type, customUnit: $customUnit)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ItemUnitImpl &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.customUnit, customUnit) ||
                other.customUnit == customUnit));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, type, customUnit);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ItemUnitImplCopyWith<_$ItemUnitImpl> get copyWith =>
      __$$ItemUnitImplCopyWithImpl<_$ItemUnitImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ItemUnitImplToJson(
      this,
    );
  }
}

abstract class _ItemUnit extends ItemUnit {
  const factory _ItemUnit(
      {final UnitType type,
      @JsonKey(name: 'custom_unit') final String customUnit}) = _$ItemUnitImpl;
  const _ItemUnit._() : super._();

  factory _ItemUnit.fromJson(Map<String, dynamic> json) =
      _$ItemUnitImpl.fromJson;

  @override
  UnitType get type;
  @override
  @JsonKey(name: 'custom_unit')
  String get customUnit;
  @override
  @JsonKey(ignore: true)
  _$$ItemUnitImplCopyWith<_$ItemUnitImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
