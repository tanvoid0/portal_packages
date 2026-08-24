// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// ModelGenLibraryGenerator
// **************************************************************************

part of 'repo_user.dart';

// If you use the auto() factory, ensure you import:
//   import "package:uuid/uuid.dart";
//   import "dart:math";
extension RepoUserFactory on RepoUser {
  static RepoUser auto({
    String? id,
    required String name,
  }) {
    final generatedId = id ?? const Uuid().v4();
    return RepoUser(
      id: generatedId,
      name: name,
    );
  }
}

extension RepoUserIdField on RepoUser {
  static String get idFieldName => 'id';
}

/// Generated fromJson for RepoUser
RepoUser repoUserFromJson(Map<String, dynamic> json) {
  return RepoUser(
    id: json['id'] as String,
    name: json['name'] as String,
  );
}

extension RepoUserJsonExtension on RepoUser {
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }

  Object? getId() => id;
  RepoUser copyWith({
    String? id,
    String? name,
  }) {
    return RepoUser(
      id: id ?? this.id,
      name: name ?? this.name,
    );
  }
}
