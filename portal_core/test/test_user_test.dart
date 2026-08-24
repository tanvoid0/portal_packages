import 'package:test/test.dart';
import 'package:portal_core/models/test_user.dart';

void main() {
  test('TestUser toJson/fromJson roundtrip', () {
    final user = TestUser(id: '2', name: 'Bob', age: 25);
    final json = user.toJson();
    final user2 = testUserFromJson(json);
    expect(user2.id, equals(user.id));
    expect(user2.name, equals(user.name));
    expect(user2.age, equals(user.age));
  });

  test('TestUser getId returns id', () {
    final user = TestUser(id: '2', name: 'Bob', age: 25);
    expect(user.getId(), equals('2'));
  });
}
