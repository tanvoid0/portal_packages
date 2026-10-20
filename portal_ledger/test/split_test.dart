import 'package:portal_ledger/portal_ledger.dart';
import 'package:test/test.dart';

void main() {
  group('allocateByWeights', () {
    test('equal split hands the odd cent to the earliest party', () {
      expect(allocateByWeights(100, [1, 1, 1]), [34, 33, 33]);
      expect(allocateByWeights(10, [1, 1, 1, 1]), [3, 3, 2, 2]);
    });

    test('weighted split distributes by weight', () {
      expect(allocateByWeights(100, [1, 2, 1]), [25, 50, 25]);
    });

    test('always sums to the total', () {
      for (final c in [
        [100, [1, 1, 1]],
        [9999, [1, 2, 3, 4]],
        [1, [1, 1, 1, 1, 1]],
        [7, [3, 3, 3]],
      ]) {
        final total = c[0] as int;
        final weights = c[1] as List<int>;
        expect(allocateByWeights(total, weights).fold<int>(0, (a, b) => a + b), total);
      }
    });

    test('negative total (refund) distributes the magnitude and negates', () {
      expect(allocateByWeights(-100, [1, 1, 1]), [-34, -33, -33]);
    });

    test('zero weights: zero total is fine, non-zero throws', () {
      expect(allocateByWeights(0, [0, 0]), [0, 0]);
      expect(() => allocateByWeights(100, [0, 0]), throwsArgumentError);
    });

    test('negative weight throws', () {
      expect(() => allocateByWeights(100, [1, -1]), throwsArgumentError);
    });
  });
}
