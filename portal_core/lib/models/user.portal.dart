// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// ModelGenLibraryGenerator
// **************************************************************************

part of 'user.dart';

// If you use the auto() factory, ensure you import:
//   import "package:uuid/uuid.dart";
//   import "dart:math";
extension UserFactory on User {
  static User auto({
    String? id,
    required String name,
    int? age,
    List<String>? tags,
    required Set<int> scores,
    Map<String, String>? metadata,
    Set<String>? tagsSet,
    Map<String, int>? stats,
  }) {
    final generatedId = id ?? const Uuid().v4();
    return User(
      id: generatedId,
      name: name,
      age: age ??
          18, // If you change the default, update the constructor default too
      tags: tags ??
          const [], // If you change the default, update the constructor default too
      scores: scores,
      metadata: metadata ??
          const {
            'role': 'user'
          }, // If you change the default, update the constructor default too
      tagsSet: tagsSet ??
          const {
            'a',
            'b'
          }, // If you change the default, update the constructor default too
      stats: stats ??
          const {
            'count': 1
          }, // If you change the default, update the constructor default too
    );
  }
}

extension UserIdField on User {
  static String get idFieldName => 'id';
}

/// Generated fromJson for User
User userFromJson(Map<String, dynamic> json) {
  return User(
    id: json['id'] as String,
    name: json['name'] as String,
    age: json['age'] as int,
    tags: json['tags'] as List<String>,
    scores: json['scores'] as Set<int>,
    metadata: json['metadata'] as Map<String, String>,
    tagsSet: json['tagsSet'] as Set<String>,
    stats: json['stats'] as Map<String, int>,
  );
}

extension UserJsonExtension on User {
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'age': age,
      'tags': tags,
      'scores': scores,
      'metadata': metadata,
      'tagsSet': tagsSet,
      'stats': stats,
    };
  }

  Object? getId() => id;
  User copyWith({
    String? id,
    String? name,
    int? age,
    List<String>? tags,
    Set<int>? scores,
    Map<String, String>? metadata,
    Set<String>? tagsSet,
    Map<String, int>? stats,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      age: age ?? this.age,
      tags: tags ?? this.tags,
      scores: scores ?? this.scores,
      metadata: metadata ?? this.metadata,
      tagsSet: tagsSet ?? this.tagsSet,
      stats: stats ?? this.stats,
    );
  }
}
