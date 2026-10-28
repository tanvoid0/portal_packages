import 'dart:convert';

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

/// Where every app keeps its daily goals: one [key], so the gym and recipe
/// diaries read and write the same record.
///
/// Storage is injected because this package sits below `portal_platform`
/// (which owns the on-device database and cannot see these models); apps pass
/// `PortalDatabase.kvGetOrImportFromPrefs` and `PortalDatabase.kvPut`.
///
/// ponytail: still one record per app sandbox -- each APK has its own
/// database, and the server has no goals route, so goals do not cross apps
/// yet. A server field plus a sync in [read]/[save] is what shares them.
class NutritionTargetsStore {
  const NutritionTargetsStore({
    required this.legacyKey,
    required this.get,
    required this.put,
  });

  static const key = 'portal_nutrition_targets';

  /// The app's key before [key] existed; read once, when [key] holds nothing.
  final String legacyKey;

  /// The stored text under a key; '' when there is none.
  final Future<String> Function(String key) get;
  final Future<void> Function(String key, String value) put;

  Future<NutritionTargets> read() async {
    var raw = await get(key);
    if (raw.isEmpty) {
      raw = await get(legacyKey);
      if (raw.isNotEmpty) await put(key, raw);
    }
    if (raw.isEmpty) return NutritionTargets.empty;
    try {
      return NutritionTargets.fromJson(
        Map<String, dynamic>.from(jsonDecode(raw) as Map),
      );
    } catch (_) {
      // A corrupt blob is not worth failing the screen over; unset goals are a
      // state the UI already renders.
      return NutritionTargets.empty;
    }
  }

  Future<void> save(NutritionTargets targets) =>
      put(key, jsonEncode(targets.toJson()));
}
