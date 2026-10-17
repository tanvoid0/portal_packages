import 'nutrition_info.dart';

enum FoodLogSource {
  manual,
  vision,
  recipe;

  String get wireName => name;

  /// Unknown or missing values fall back to [manual].
  static FoodLogSource parse(String? value) => FoodLogSource.values
      .firstWhere((s) => s.name == value, orElse: () => FoodLogSource.manual);
}

/// One thing eaten. A plain model: the repository layer supplies the id and
/// updatedAt accessors for sync, so this does not implement `Syncable`.
class FoodLogEntry {
  final String id;
  final DateTime loggedAt;
  final String name;

  /// Per serving; the entry's real intake is `nutrition.scaled(servings)`.
  final NutritionInfo nutrition;
  final double servings;
  final FoodLogSource source;

  /// breakfast | lunch | dinner | snack
  final String? mealType;
  final String? recipeId;
  final String? imageUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const FoodLogEntry({
    required this.id,
    required this.loggedAt,
    required this.name,
    this.nutrition = const NutritionInfo(),
    this.servings = 1.0,
    this.source = FoodLogSource.manual,
    this.mealType,
    this.recipeId,
    this.imageUrl,
    this.createdAt,
    this.updatedAt,
  });

  /// Total intake across [entries], each scaled by its servings.
  static NutritionInfo sumEntries(Iterable<FoodLogEntry> entries) =>
      entries.fold(
        const NutritionInfo(),
        (sum, e) => sum + e.nutrition.scaled(e.servings),
      );

  // Nullable fields cannot be cleared through copyWith (null means "keep").
  FoodLogEntry copyWith({
    String? id,
    DateTime? loggedAt,
    String? name,
    NutritionInfo? nutrition,
    double? servings,
    FoodLogSource? source,
    String? mealType,
    String? recipeId,
    String? imageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      FoodLogEntry(
        id: id ?? this.id,
        loggedAt: loggedAt ?? this.loggedAt,
        name: name ?? this.name,
        nutrition: nutrition ?? this.nutrition,
        servings: servings ?? this.servings,
        source: source ?? this.source,
        mealType: mealType ?? this.mealType,
        recipeId: recipeId ?? this.recipeId,
        imageUrl: imageUrl ?? this.imageUrl,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'loggedAt': loggedAt.toIso8601String(),
        'name': name,
        'nutrition': nutrition.toJson(),
        'servings': servings,
        'source': source.wireName,
        if (mealType != null) 'mealType': mealType,
        if (recipeId != null) 'recipeId': recipeId,
        if (imageUrl != null) 'imageUrl': imageUrl,
        if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
        if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
      };

  factory FoodLogEntry.fromJson(Map<String, dynamic> json) => FoodLogEntry(
        id: json['id'] as String,
        loggedAt: DateTime.parse(json['loggedAt'] as String),
        name: json['name'] as String? ?? '',
        nutrition: json['nutrition'] is Map
            ? NutritionInfo.fromJson(
                Map<String, dynamic>.from(json['nutrition'] as Map))
            : const NutritionInfo(),
        servings: (json['servings'] as num?)?.toDouble() ?? 1.0,
        source: FoodLogSource.parse(json['source'] as String?),
        mealType: json['mealType'] as String?,
        recipeId: json['recipeId'] as String?,
        imageUrl: json['imageUrl'] as String?,
        createdAt: _date(json['createdAt']),
        updatedAt: _date(json['updatedAt']),
      );

  static DateTime? _date(Object? v) => v is String ? DateTime.parse(v) : null;
}
