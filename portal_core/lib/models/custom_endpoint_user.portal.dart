// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// ModelGenLibraryGenerator
// **************************************************************************

part of 'custom_endpoint_user.dart';

// If you use the auto() factory, ensure you import:
//   import "package:uuid/uuid.dart";
//   import "dart:math";
extension CustomEndpointUserFactory on CustomEndpointUser {
  static CustomEndpointUser auto({
    String? id,
    required String name,
    required String email,
  }) {
    final generatedId = id ?? const Uuid().v4();
    return CustomEndpointUser(
      id: generatedId,
      name: name,
      email: email,
    );
  }
}

extension CustomEndpointUserIdField on CustomEndpointUser {
  static String get idFieldName => 'id';
}

/// Generated fromJson for CustomEndpointUser
CustomEndpointUser customEndpointUserFromJson(Map<String, dynamic> json) {
  return CustomEndpointUser(
    id: json['id'] as String,
    name: json['name'] as String,
    email: json['email'] as String,
  );
}

extension CustomEndpointUserJsonExtension on CustomEndpointUser {
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
    };
  }

  Object? getId() => id;
  CustomEndpointUser copyWith({
    String? id,
    String? name,
    String? email,
  }) {
    return CustomEndpointUser(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
    );
  }
}
