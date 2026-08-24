// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// ModelGenLibraryGenerator
// **************************************************************************

part of 'repo_user_default.dart';

// If you use the auto() factory, ensure you import:
//   import "package:uuid/uuid.dart";
//   import "dart:math";
extension RepoUserDefaultFactory on RepoUserDefault {
  static RepoUserDefault auto({
    String? id,
    required String name,
  }) {
    final generatedId = id ?? const Uuid().v4();
    return RepoUserDefault(
      id: generatedId,
      name: name,
    );
  }
}

extension RepoUserDefaultIdField on RepoUserDefault {
  static String get idFieldName => 'id';
}

/// Generated fromJson for RepoUserDefault
RepoUserDefault repoUserDefaultFromJson(Map<String, dynamic> json) {
  return RepoUserDefault(
    id: json['id'] as String,
    name: json['name'] as String,
  );
}

extension RepoUserDefaultJsonExtension on RepoUserDefault {
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }

  Object? getId() => id;
  RepoUserDefault copyWith({
    String? id,
    String? name,
  }) {
    return RepoUserDefault(
      id: id ?? this.id,
      name: name ?? this.name,
    );
  }
}
