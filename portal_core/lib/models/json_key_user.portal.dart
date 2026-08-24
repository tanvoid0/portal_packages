// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// ModelGenLibraryGenerator
// **************************************************************************

part of 'json_key_user.dart';

// If you use the auto() factory, ensure you import:
//   import "package:uuid/uuid.dart";
//   import "dart:math";
extension JsonKeyUserFactory on JsonKeyUser {
  static JsonKeyUser auto({
    String? id,
    required String firstName,
    required String lastName,
    required bool active,
  }) {
    final generatedId = id ?? const Uuid().v4();
    return JsonKeyUser(
      id: generatedId,
      firstName: firstName,
      lastName: lastName,
      active: active,
    );
  }
}

extension JsonKeyUserIdField on JsonKeyUser {
  static String get idFieldName => 'id';
}

/// Generated fromJson for JsonKeyUser
JsonKeyUser jsonKeyUserFromJson(Map<String, dynamic> json) {
  return JsonKeyUser(
    id: json['user_id'] as String,
    firstName: json['first_name'] as String,
    lastName: json['last_name'] as String,
    active: json['is_active'] as bool,
  );
}

extension JsonKeyUserJsonExtension on JsonKeyUser {
  Map<String, dynamic> toJson() {
    return {
      'user_id': id,
      'first_name': firstName,
      'last_name': lastName,
      'is_active': active,
    };
  }

  Object? getId() => id;
  JsonKeyUser copyWith({
    String? id,
    String? firstName,
    String? lastName,
    bool? active,
  }) {
    return JsonKeyUser(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      active: active ?? this.active,
    );
  }
}
