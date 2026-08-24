import 'package:test/test.dart';
import 'package:portal_core/models/json_key_user.dart';

void main() {
  test('JsonKeyUser toJson uses custom keys and snake_case', () {
    final user = JsonKeyUser(
      id: 'abc',
      firstName: 'John',
      lastName: 'Doe',
      active: true,
    );
    final json = user.toJson();
    expect(json, containsPair('user_id', 'abc'));
    expect(json, containsPair('first_name', 'John'));
    expect(json, containsPair('last_name', 'Doe'));
    expect(json, containsPair('is_active', true));
  });

  test('JsonKeyUser fromJson uses custom keys and snake_case', () {
    final json = {
      'user_id': 'xyz',
      'first_name': 'Jane',
      'last_name': 'Smith',
      'is_active': false,
    };
    final user = jsonKeyUserFromJson(json);
    expect(user.id, equals('xyz'));
    expect(user.firstName, equals('Jane'));
    expect(user.lastName, equals('Smith'));
    expect(user.active, isFalse);
  });
}
