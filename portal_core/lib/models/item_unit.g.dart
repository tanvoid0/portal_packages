// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'item_unit.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ItemUnitImpl _$$ItemUnitImplFromJson(Map<String, dynamic> json) =>
    _$ItemUnitImpl(
      type: $enumDecodeNullable(_$UnitTypeEnumMap, json['type']) ??
          UnitType.count,
      customUnit: json['custom_unit'] as String? ?? '',
    );

Map<String, dynamic> _$$ItemUnitImplToJson(_$ItemUnitImpl instance) =>
    <String, dynamic>{
      'type': _$UnitTypeEnumMap[instance.type]!,
      'custom_unit': instance.customUnit,
    };

const _$UnitTypeEnumMap = {
  UnitType.pieces: 'pieces',
  UnitType.pairs: 'pairs',
  UnitType.items: 'items',
  UnitType.kg: 'kg',
  UnitType.grams: 'grams',
  UnitType.liters: 'liters',
  UnitType.milliliters: 'milliliters',
  UnitType.bottles: 'bottles',
  UnitType.cans: 'cans',
  UnitType.boxes: 'boxes',
  UnitType.packs: 'packs',
  UnitType.bags: 'bags',
  UnitType.count: 'count',
  UnitType.custom: 'custom',
};
