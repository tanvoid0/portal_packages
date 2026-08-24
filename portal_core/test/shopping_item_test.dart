import 'package:portal_core/portal_core_models.dart';
import 'package:test/test.dart';

void main() {
  test('ShoppingItem.fromJson accepts Mongo _id', () {
    final item = ShoppingItem.fromJson({
      '_id': 'item-1',
      'name': 'Milk',
      'status': 'pending',
    });

    expect(item.id, 'item-1');
    expect(item.name, 'Milk');
    expect(item.status, ShoppingStatus.pending);
  });

  test('ShoppingItem.fromJson prefers id over _id', () {
    final item = ShoppingItem.fromJson({
      'id': 'canonical',
      '_id': 'legacy',
      'name': 'Bread',
    });

    expect(item.id, 'canonical');
  });

  test('ShoppingItem.fromJson accepts legacy string unit', () {
    final item = ShoppingItem.fromJson({
      'id': 'item-2',
      'name': 'Rice',
      'unit': 'kg',
    });

    expect(item.unit.type, UnitType.kg);
  });

  test('parseShoppingApiList reports item index on failure', () {
    expect(
      () => parseShoppingApiList(
        response: [
          {'id': 'ok', 'name': 'Milk'},
          {'name': 'Bread'},
        ],
        endpoint: '/lifestyle/shopping',
        decode: ShoppingItem.fromJson,
      ),
      throwsA(
        isA<ShoppingParseException>().having(
          (e) => e.itemIndex,
          'itemIndex',
          1,
        ),
      ),
    );
  });

  test('legacy unit aliases normalize to count for shopping', () {
    expect(UnitType.pieces.normalizedForShopping, UnitType.count);
    expect(UnitType.items.normalizedForShopping, UnitType.count);
    expect(UnitType.pairs.normalizedForShopping, UnitType.count);
    expect(UnitType.kg.shoppingFamily, ShoppingUnitFamily.weight);
    expect(UnitType.liters.shoppingFamily, ShoppingUnitFamily.volume);
    expect(UnitType.bottles.shoppingFamily, ShoppingUnitFamily.package);
  });
}
