import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:portal_ai/portal_ai.dart';

void main() {
  const morning = AiSuggestion(
    id: 'morning',
    prompt: 'Plan my study day',
    morningBias: true,
  );
  const evening = AiSuggestion(
    id: 'evening',
    prompt: 'Wind down',
    eveningBias: true,
  );

  test('a bare prompt is its own id and title', () {
    const bare = AiSuggestion(prompt: 'What did I spend?');
    expect(bare.id, 'What did I spend?');
    expect(bare.title, 'What did I spend?');
    expect(bare.subtitle, isEmpty);
  });

  test('time of day moves the score', () {
    final at8am = DateTime(2026, 9, 7, 8);
    final at8pm = DateTime(2026, 9, 7, 20);
    expect(
      morning.relevanceScore(at8am),
      greaterThan(evening.relevanceScore(at8am)),
    );
    expect(
      evening.relevanceScore(at8pm),
      greaterThan(morning.relevanceScore(at8pm)),
    );
  });

  test('json survives a round trip, biases included', () {
    final back = AiSuggestion.fromJson(morning.toJson());
    expect(back.id, morning.id);
    expect(back.prompt, morning.prompt);
    expect(back.morningBias, isTrue);
    expect(back.eveningBias, isFalse);
  });

  test('a merged suggestion is scored, not stuck at zero', () {
    // The bug this replaces: the rotator looked bias up in the curated list by
    // id, so a server-sent suggestion could never outrank a curated one.
    final at9pm = DateTime(2026, 9, 7, 21);
    var remoteWon = 0;
    for (var seed = 0; seed < 20; seed++) {
      final rotator =
          AiSuggestionRotator(
              pool: const [AiSuggestion(id: 'flat', prompt: 'Anything')],
              visibleCount: 1,
              random: Random(seed),
            )
            ..mergePool(const [
              AiSuggestion(
                id: 'remote',
                prompt: 'Wind down',
                eveningBias: true,
              ),
            ])
            ..refresh(now: at9pm);
      if (rotator.visible.single.id == 'remote') remoteWon++;
    }
    expect(remoteWon, greaterThan(15));
  });

  test('refresh fills the deck and mergePool ignores duplicate ids', () {
    final rotator =
        AiSuggestionRotator(
            pool: const [morning, evening],
            visibleCount: 2,
            random: Random(7),
          )
          ..mergePool(const [morning])
          ..refresh(now: DateTime(2026, 9, 7, 9));
    expect(rotator.visible, hasLength(2));
    expect(rotator.canRotate, isFalse);
  });

  test('rotateOne swaps exactly one card, for something not on screen', () {
    final pool = [
      for (var i = 0; i < 6; i++) AiSuggestion(id: 'p$i', prompt: 'prompt $i'),
    ];
    final rotator = AiSuggestionRotator(
      pool: pool,
      visibleCount: 3,
      random: Random(3),
    )..refresh(now: DateTime(2026, 9, 7, 9));

    final before = rotator.visible.map((s) => s.id).toList();
    rotator.rotateOne(now: DateTime(2026, 9, 7, 9));
    final after = rotator.visible.map((s) => s.id).toList();

    expect(after, hasLength(3));
    expect(after.toSet(), hasLength(3), reason: 'no duplicate on screen');
    expect(
      after.where(before.contains).length,
      2,
      reason: 'one card changed, two stayed',
    );
  });
}
