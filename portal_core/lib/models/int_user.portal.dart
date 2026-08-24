// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// ModelGenLibraryGenerator
// **************************************************************************

part of 'int_user.dart';

// If you use the auto() factory, ensure you import:
//   import "package:uuid/uuid.dart";
//   import "dart:math";
extension IntUserFactory on IntUser {
  static IntUser auto({
    int? id,
    required String name,
    int? age,
  }) {
    final generatedId = id ?? Random().nextInt(1 << 31);
    return IntUser(
      id: generatedId,
      name: name,
      age: age ??
          21, // If you change the default, update the constructor default too
    );
  }
}

extension IntUserIdField on IntUser {
  static String get idFieldName => 'id';
}

/// Generated fromJson for IntUser
IntUser intUserFromJson(Map<String, dynamic> json) {
  return IntUser(
    id: json['id'] as int,
    name: json['name'] as String,
    age: json['age'] as int,
  );
}

extension IntUserJsonExtension on IntUser {
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'age': age,
    };
  }

  Object? getId() => id;
  IntUser copyWith({
    int? id,
    String? name,
    int? age,
  }) {
    return IntUser(
      id: id ?? this.id,
      name: name ?? this.name,
      age: age ?? this.age,
    );
  }
}
