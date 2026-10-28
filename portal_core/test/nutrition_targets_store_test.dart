import 'package:portal_core/models/nutrition_targets.dart';
import 'package:test/test.dart';

void main() {
  final disk = <String, String>{};
  final store = NutritionTargetsStore(
    legacyKey: 'portal_gym_nutrition_targets',
    get: (k) async => disk[k] ?? '',
    put: (k, v) async => disk[k] = v,
  );

  setUp(disk.clear);

  test('nothing stored reads as unset', () async {
    expect((await store.read()).isSet, isFalse);
  });

  test('a legacy record is read once and moved under the shared key', () async {
    disk['portal_gym_nutrition_targets'] =
        '{"calories":2100,"protein":150.5,"carbs":0,"fat":0}';
    final t = await store.read();
    expect(t.calories, 2100);
    expect(t.protein, 150.5);
    expect(disk[NutritionTargetsStore.key], isNotEmpty);
  });

  test('the shared key wins over the legacy one, and save round-trips', () async {
    disk['portal_gym_nutrition_targets'] = '{"calories":1000}';
    await store.save(const NutritionTargets(calories: 1800, fat: 60));
    final t = await store.read();
    expect(t.calories, 1800);
    expect(t.fat, 60);
  });
}
