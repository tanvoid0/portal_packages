/// Macro and micro nutrients for one serving (or a summed total).
///
/// [sodium] is in milligrams; the rest of the optionals are grams. A null
/// optional means "unknown", which is not the same as zero.
class NutritionInfo {
  final int calories;
  final double protein;
  final double carbs;
  final double fat;
  final double? fiber;
  final double? sugar;
  final double? sodium;

  const NutritionInfo({
    this.calories = 0,
    this.protein = 0,
    this.carbs = 0,
    this.fat = 0,
    this.fiber,
    this.sugar,
    this.sodium,
  });

  NutritionInfo scaled(double factor) => NutritionInfo(
        calories: (calories * factor).round(),
        protein: protein * factor,
        carbs: carbs * factor,
        fat: fat * factor,
        fiber: fiber == null ? null : fiber! * factor,
        sugar: sugar == null ? null : sugar! * factor,
        sodium: sodium == null ? null : sodium! * factor,
      );

  /// Element-wise sum. An optional stays null only when both sides are null.
  NutritionInfo operator +(NutritionInfo other) => NutritionInfo(
        calories: calories + other.calories,
        protein: protein + other.protein,
        carbs: carbs + other.carbs,
        fat: fat + other.fat,
        fiber: _add(fiber, other.fiber),
        sugar: _add(sugar, other.sugar),
        sodium: _add(sodium, other.sodium),
      );

  static double? _add(double? a, double? b) =>
      a == null && b == null ? null : (a ?? 0) + (b ?? 0);

  Map<String, dynamic> toJson() => {
        'calories': calories,
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
        if (fiber != null) 'fiber': fiber,
        if (sugar != null) 'sugar': sugar,
        if (sodium != null) 'sodium': sodium,
      };

  factory NutritionInfo.fromJson(Map<String, dynamic> json) => NutritionInfo(
        calories: (json['calories'] as num?)?.round() ?? 0,
        protein: (json['protein'] as num?)?.toDouble() ?? 0,
        carbs: (json['carbs'] as num?)?.toDouble() ?? 0,
        fat: (json['fat'] as num?)?.toDouble() ?? 0,
        fiber: (json['fiber'] as num?)?.toDouble(),
        sugar: (json['sugar'] as num?)?.toDouble(),
        sodium: (json['sodium'] as num?)?.toDouble(),
      );
}
