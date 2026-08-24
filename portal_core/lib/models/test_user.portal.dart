// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// ModelGenLibraryGenerator
// **************************************************************************

part of 'test_user.dart';

// If you use the auto() factory, ensure you import:
//   import "package:uuid/uuid.dart";
//   import "dart:math";
extension TestUserFactory on TestUser {
  static TestUser auto({
    String? id,
    required String name,
    required int age,
  }) {
    final generatedId = id ?? const Uuid().v4();
    return TestUser(
      id: generatedId,
      name: name,
      age: age,
    );
  }
}

extension TestUserIdField on TestUser {
  static String get idFieldName => 'id';
}

/// Generated fromJson for TestUser
TestUser testUserFromJson(Map<String, dynamic> json) {
  return TestUser(
    id: json['id'] as String,
    name: json['name'] as String,
    age: json['age'] as int,
  );
}

extension TestUserJsonExtension on TestUser {
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'age': age,
    };
  }

  Object? getId() => id;
  TestUser copyWith({
    String? id,
    String? name,
    int? age,
  }) {
    return TestUser(
      id: id ?? this.id,
      name: name ?? this.name,
      age: age ?? this.age,
    );
  }
}
