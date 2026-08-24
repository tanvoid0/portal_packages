// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// ModelGenLibraryGenerator
// **************************************************************************

part of 'cache_user.dart';

// If you use the auto() factory, ensure you import:
//   import "package:uuid/uuid.dart";
//   import "dart:math";
extension CacheUserFactory on CacheUser {
  static CacheUser auto({
    String? id,
    required String name,
  }) {
    final generatedId = id ?? const Uuid().v4();
    return CacheUser(
      id: generatedId,
      name: name,
    );
  }
}

extension CacheUserIdField on CacheUser {
  static String get idFieldName => 'id';
}

/// Generated fromJson for CacheUser
CacheUser cacheUserFromJson(Map<String, dynamic> json) {
  return CacheUser(
    id: json['id'] as String,
    name: json['name'] as String,
  );
}

extension CacheUserJsonExtension on CacheUser {
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }

  Object? getId() => id;
  CacheUser copyWith({
    String? id,
    String? name,
  }) {
    return CacheUser(
      id: id ?? this.id,
      name: name ?? this.name,
    );
  }
}
