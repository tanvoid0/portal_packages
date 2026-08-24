import 'package:freezed_annotation/freezed_annotation.dart';

part 'item_unit.freezed.dart';
part 'item_unit.g.dart';

/// How a shopping (or wardrobe) item is measured.
enum UnitType {
  // Legacy / clothing aliases — still accepted from API JSON.
  pieces,
  pairs,
  items,

  // Grocery count (preferred stored value for "3 apples").
  count,

  // Weight
  kg,
  grams,

  // Volume
  liters,
  milliliters,

  // Sold as a package or container
  bottles,
  cans,
  boxes,
  packs,
  bags,

  // Free-form label (bunches, heads, …)
  custom;

  String get displayName {
    switch (this) {
      case UnitType.pieces:
      case UnitType.items:
        return 'each';
      case UnitType.pairs:
        return 'pairs';
      case UnitType.count:
        return 'each';
      case UnitType.kg:
        return 'kg';
      case UnitType.grams:
        return 'g';
      case UnitType.liters:
        return 'L';
      case UnitType.milliliters:
        return 'ml';
      case UnitType.bottles:
        return 'bottles';
      case UnitType.cans:
        return 'cans';
      case UnitType.boxes:
        return 'boxes';
      case UnitType.packs:
        return 'packs';
      case UnitType.bags:
        return 'bags';
      case UnitType.custom:
        return 'other';
    }
  }

  /// Wardrobe / drawer items (not used on shopping lists).
  static List<UnitType> get clothingUnits => [pieces, pairs, items];

  /// All unit types valid for grocery lists (excludes legacy aliases).
  static List<UnitType> get shoppingUnits => [
        count,
        kg,
        grams,
        liters,
        milliliters,
        bottles,
        cans,
        boxes,
        packs,
        bags,
        custom,
      ];
}

/// High-level unit grouping for shopping item editors.
enum ShoppingUnitFamily {
  count,
  weight,
  volume,
  package,
  custom;

  String get label {
    switch (this) {
      case ShoppingUnitFamily.count:
        return 'Count';
      case ShoppingUnitFamily.weight:
        return 'Weight';
      case ShoppingUnitFamily.volume:
        return 'Volume';
      case ShoppingUnitFamily.package:
        return 'Package';
      case ShoppingUnitFamily.custom:
        return 'Other';
    }
  }

  String get quantityPrompt {
    switch (this) {
      case ShoppingUnitFamily.count:
        return 'How many do you need?';
      case ShoppingUnitFamily.weight:
        return 'How much weight do you need?';
      case ShoppingUnitFamily.volume:
        return 'How much volume do you need?';
      case ShoppingUnitFamily.package:
        return 'How many packages?';
      case ShoppingUnitFamily.custom:
        return 'How much do you need?';
    }
  }

  List<UnitType> get unitTypes {
    switch (this) {
      case ShoppingUnitFamily.count:
        return [UnitType.count];
      case ShoppingUnitFamily.weight:
        return [UnitType.kg, UnitType.grams];
      case ShoppingUnitFamily.volume:
        return [UnitType.liters, UnitType.milliliters];
      case ShoppingUnitFamily.package:
        return [
          UnitType.packs,
          UnitType.bottles,
          UnitType.cans,
          UnitType.boxes,
          UnitType.bags,
        ];
      case ShoppingUnitFamily.custom:
        return [UnitType.custom];
    }
  }
}

extension UnitTypeShoppingX on UnitType {
  /// Maps legacy `pieces` / `items` / `pairs` JSON to grocery-friendly types.
  UnitType get normalizedForShopping {
    switch (this) {
      case UnitType.pieces:
      case UnitType.items:
      case UnitType.pairs:
        return UnitType.count;
      default:
        return this;
    }
  }

  ShoppingUnitFamily get shoppingFamily {
    switch (normalizedForShopping) {
      case UnitType.kg:
      case UnitType.grams:
        return ShoppingUnitFamily.weight;
      case UnitType.liters:
      case UnitType.milliliters:
        return ShoppingUnitFamily.volume;
      case UnitType.bottles:
      case UnitType.cans:
      case UnitType.boxes:
      case UnitType.packs:
      case UnitType.bags:
        return ShoppingUnitFamily.package;
      case UnitType.custom:
        return ShoppingUnitFamily.custom;
      case UnitType.count:
      case UnitType.pieces:
      case UnitType.pairs:
      case UnitType.items:
        return ShoppingUnitFamily.count;
    }
  }
}

@freezed
class ItemUnit with _$ItemUnit {
  const ItemUnit._();

  const factory ItemUnit({
    @Default(UnitType.count) UnitType type,
    @JsonKey(name: 'custom_unit') @Default('') String customUnit,
  }) = _ItemUnit;

  factory ItemUnit.fromJson(Map<String, dynamic> json) =>
      _$ItemUnitFromJson(json);

  String get displayName {
    if (type == UnitType.custom && customUnit.isNotEmpty) {
      return customUnit;
    }
    return type.displayName;
  }

  /// Unit type stored on save and used in shopping UI.
  UnitType get shoppingType => type.normalizedForShopping;

  ShoppingUnitFamily get shoppingFamily => shoppingType.shoppingFamily;
}
