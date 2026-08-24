import 'package:test/test.dart';
import 'package:portal_core/models/int_user.dart';

void main() {
  test('IntUser toJson/fromJson roundtrip', () {
    final user = IntUser(id: 42, name: 'Carol', age: 28);
    final json = user.toJson();
    final user2 = intUserFromJson(json);
    expect(user2.id, equals(user.id));
    expect(user2.name, equals(user.name));
    expect(user2.age, equals(user.age));
  });

  test('IntUser getId returns id', () {
    final user = IntUser(id: 99, name: 'Dave', age: 35);
    expect(user.getId(), equals(99));
  });

  test('IntUserFactory.auto generates a random int if id is not provided', () {
    final user = IntUserFactory.auto(name: 'Eve', age: 22);
    expect(user.id, isNotNull);
    expect(user.id, isA<int>());
  });

  test('IntUserFactory.auto uses provided id if given', () {
    final customId = 12345;
    final user = IntUserFactory.auto(id: customId, name: 'Frank', age: 40);
    expect(user.id, equals(customId));
  });

  test('IntUserFactory.auto uses @Default value for age if not provided', () {
    final user = IntUserFactory.auto(name: 'Carol');
    expect(user.age, equals(21));
  });

  test('IntUserFactory.auto allows overriding @Default value for age', () {
    final user = IntUserFactory.auto(name: 'Carol', age: 77);
    expect(user.age, equals(77));
  });

  test('IntUser copyWith updates fields correctly', () {
    final user = IntUser(id: 1, name: 'Alice', age: 20);
    final updatedId = user.copyWith(id: 2);
    final updatedName = user.copyWith(name: 'Bob');
    final updatedAge = user.copyWith(age: 30);
    expect(updatedId.id, equals(2));
    expect(updatedId.name, equals('Alice'));
    expect(updatedName.name, equals('Bob'));
    expect(updatedName.id, equals(1));
    expect(updatedAge.age, equals(30));
    expect(updatedAge.id, equals(1));
  });
}
