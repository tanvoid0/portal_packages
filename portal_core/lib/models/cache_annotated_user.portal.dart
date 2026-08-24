// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// ModelGenLibraryGenerator
// **************************************************************************

part of 'cache_annotated_user.dart';

// If you use the auto() factory, ensure you import:
//   import "package:uuid/uuid.dart";
//   import "dart:math";
extension CacheUserDefaultCollectionFactory on CacheUserDefaultCollection {
  static CacheUserDefaultCollection auto({
    String? id,
    required String name,
  }) {
    final generatedId = id ?? const Uuid().v4();
    return CacheUserDefaultCollection(
      id: generatedId,
      name: name,
    );
  }
}

extension CacheUserDefaultCollectionIdField on CacheUserDefaultCollection {
  static String get idFieldName => 'id';
}

/// Generated fromJson for CacheUserDefaultCollection
CacheUserDefaultCollection cacheUserDefaultCollectionFromJson(
    Map<String, dynamic> json) {
  return CacheUserDefaultCollection(
    id: json['id'] as String,
    name: json['name'] as String,
  );
}

extension CacheUserDefaultCollectionJsonExtension
    on CacheUserDefaultCollection {
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }

  Object? getId() => id;
  CacheUserDefaultCollection copyWith({
    String? id,
    String? name,
  }) {
    return CacheUserDefaultCollection(
      id: id ?? this.id,
      name: name ?? this.name,
    );
  }
}

// If you use the auto() factory, ensure you import:
//   import "package:uuid/uuid.dart";
//   import "dart:math";
extension CacheUserSingleFactory on CacheUserSingle {
  static CacheUserSingle auto({
    String? id,
    required String name,
  }) {
    final generatedId = id ?? const Uuid().v4();
    return CacheUserSingle(
      id: generatedId,
      name: name,
    );
  }
}

extension CacheUserSingleIdField on CacheUserSingle {
  static String get idFieldName => 'id';
}

/// Generated fromJson for CacheUserSingle
CacheUserSingle cacheUserSingleFromJson(Map<String, dynamic> json) {
  return CacheUserSingle(
    id: json['id'] as String,
    name: json['name'] as String,
  );
}

extension CacheUserSingleJsonExtension on CacheUserSingle {
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }

  Object? getId() => id;
  CacheUserSingle copyWith({
    String? id,
    String? name,
  }) {
    return CacheUserSingle(
      id: id ?? this.id,
      name: name ?? this.name,
    );
  }
}

// If you use the auto() factory, ensure you import:
//   import "package:uuid/uuid.dart";
//   import "dart:math";
extension CacheUserCustomKeySingleFactory on CacheUserCustomKeySingle {
  static CacheUserCustomKeySingle auto({
    String? id,
    required String name,
  }) {
    final generatedId = id ?? const Uuid().v4();
    return CacheUserCustomKeySingle(
      id: generatedId,
      name: name,
    );
  }
}

extension CacheUserCustomKeySingleIdField on CacheUserCustomKeySingle {
  static String get idFieldName => 'id';
}

/// Generated fromJson for CacheUserCustomKeySingle
CacheUserCustomKeySingle cacheUserCustomKeySingleFromJson(
    Map<String, dynamic> json) {
  return CacheUserCustomKeySingle(
    id: json['id'] as String,
    name: json['name'] as String,
  );
}

extension CacheUserCustomKeySingleJsonExtension on CacheUserCustomKeySingle {
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }

  Object? getId() => id;
  CacheUserCustomKeySingle copyWith({
    String? id,
    String? name,
  }) {
    return CacheUserCustomKeySingle(
      id: id ?? this.id,
      name: name ?? this.name,
    );
  }
}

// If you use the auto() factory, ensure you import:
//   import "package:uuid/uuid.dart";
//   import "dart:math";
extension CacheUserNoCacheFactory on CacheUserNoCache {
  static CacheUserNoCache auto({
    String? id,
    required String name,
  }) {
    final generatedId = id ?? const Uuid().v4();
    return CacheUserNoCache(
      id: generatedId,
      name: name,
    );
  }
}

extension CacheUserNoCacheIdField on CacheUserNoCache {
  static String get idFieldName => 'id';
}

/// Generated fromJson for CacheUserNoCache
CacheUserNoCache cacheUserNoCacheFromJson(Map<String, dynamic> json) {
  return CacheUserNoCache(
    id: json['id'] as String,
    name: json['name'] as String,
  );
}

extension CacheUserNoCacheJsonExtension on CacheUserNoCache {
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }

  Object? getId() => id;
  CacheUserNoCache copyWith({
    String? id,
    String? name,
  }) {
    return CacheUserNoCache(
      id: id ?? this.id,
      name: name ?? this.name,
    );
  }
}
