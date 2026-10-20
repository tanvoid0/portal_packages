/// Distribute [total] minor units across non-negative integer [weights] using
/// the largest-remainder method, so the returned parts sum to [total] exactly
/// (no cent lost or invented). Ties go to the earlier index, so the result is
/// deterministic.
///
/// Works for a negative [total] (a refund/credit): the magnitude is distributed
/// and each part negated. Throws if any weight is negative, or if the weights
/// sum to zero while [total] is non-zero.
List<int> allocateByWeights(int total, List<int> weights) {
  if (weights.isEmpty) return const [];
  if (weights.any((w) => w < 0)) {
    throw ArgumentError('weights must be non-negative');
  }
  final sumW = weights.fold<int>(0, (a, b) => a + b);
  if (sumW == 0) {
    if (total != 0) {
      throw ArgumentError('cannot split a non-zero total across zero total weight');
    }
    return List<int>.filled(weights.length, 0);
  }
  if (total < 0) {
    return _allocateNonNegative(-total, weights, sumW).map((x) => -x).toList();
  }
  return _allocateNonNegative(total, weights, sumW);
}

List<int> _allocateNonNegative(int total, List<int> weights, int sumW) {
  final base = List<int>.filled(weights.length, 0);
  final remainder = List<int>.filled(weights.length, 0);
  var allocated = 0;
  for (var i = 0; i < weights.length; i++) {
    final numerator = total * weights[i];
    base[i] = numerator ~/ sumW;
    remainder[i] = numerator % sumW; // >= 0 since all operands >= 0
    allocated += base[i];
  }
  var leftover = total - allocated; // 0 <= leftover < count of positive weights
  final order = List<int>.generate(weights.length, (i) => i)
    ..sort((a, b) {
      final byRemainder = remainder[b].compareTo(remainder[a]);
      return byRemainder != 0 ? byRemainder : a.compareTo(b);
    });
  for (var k = 0; k < leftover; k++) {
    base[order[k]] += 1;
  }
  return base;
}
