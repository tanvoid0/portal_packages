/// Daily nutrition goals.
///
/// A target of 0 means "not set" rather than "eat nothing" — the screens read
/// [isSet] before drawing any progress, so an unset goal shows the day's real
/// figures and an invitation to set one, never a meter at an invented ratio.
class NutritionTargets {
  final int calories;
  final double protein;
  final double carbs;
  final double fat;

  const NutritionTargets({
    this.calories = 0,
    this.protein = 0,
    this.carbs = 0,
    this.fat = 0,
  });

  static const empty = NutritionTargets();

  bool get isSet => calories > 0 || protein > 0 || carbs > 0 || fat > 0;

  NutritionTargets copyWith({
    int? calories,
    double? protein,
    double? carbs,
    double? fat,
  }) =>
      NutritionTargets(
        calories: calories ?? this.calories,
        protein: protein ?? this.protein,
        carbs: carbs ?? this.carbs,
        fat: fat ?? this.fat,
      );

  Map<String, dynamic> toJson() => {
        'calories': calories,
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
      };

  factory NutritionTargets.fromJson(Map<String, dynamic> json) =>
      NutritionTargets(
        calories: (json['calories'] as num?)?.round() ?? 0,
        protein: (json['protein'] as num?)?.toDouble() ?? 0,
        carbs: (json['carbs'] as num?)?.toDouble() ?? 0,
        fat: (json['fat'] as num?)?.toDouble() ?? 0,
      );
}
