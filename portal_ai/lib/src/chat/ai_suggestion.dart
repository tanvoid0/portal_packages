import 'dart:math';

/// One prompt the assistant offers before the first question.
///
/// A bare [prompt] is enough -- [id] and [title] fall back to it -- so an app
/// with nothing but a list of sentences still gets cards. Give it a [subtitle]
/// and an [iconName] and the card fills out.
///
/// The time-of-day flags are the suggestion's own, not a wrapper's: the
/// previous split (a curated `PooledAiSuggestion` holding an `AiSuggestion`)
/// meant the rotator had to look a suggestion's bias back up in the curated
/// list by id, so anything the model or the server added scored zero forever.
class AiSuggestion {
  const AiSuggestion({
    required this.prompt,
    String? id,
    String? title,
    this.subtitle = '',
    this.iconName = 'sparkles',
    this.morningBias = false,
    this.afternoonBias = false,
    this.eveningBias = false,
    this.weekendBias = false,
  }) // A named parameter cannot be private, so `id` and `title` cannot be
    // initialising formals for the fields their getters fall back on.
    // ignore: prefer_initializing_formals
    : _id = id,
       // ignore: prefer_initializing_formals
       _title = title;

  /// Wraps plain prompt strings, for a host that has no card copy to give.
  static List<AiSuggestion> prompts(List<String> prompts) => [
    for (final p in prompts) AiSuggestion(prompt: p),
  ];

  factory AiSuggestion.fromJson(Map<String, dynamic> json) => AiSuggestion(
    id: json['id'] as String?,
    title: json['title'] as String?,
    subtitle: json['subtitle'] as String? ?? '',
    prompt: json['prompt'] as String? ?? json['title'] as String? ?? '',
    iconName:
        json['icon_name'] as String? ??
        json['iconName'] as String? ??
        'sparkles',
    morningBias: json['morning_bias'] as bool? ?? false,
    afternoonBias: json['afternoon_bias'] as bool? ?? false,
    eveningBias: json['evening_bias'] as bool? ?? false,
    weekendBias: json['weekend_bias'] as bool? ?? false,
  );

  final String? _id;
  final String? _title;

  /// What gets sent when the card is tapped.
  final String prompt;

  final String subtitle;

  /// Looked up by [AiSuggestionCards]; unknown names draw the default spark.
  final String iconName;

  final bool morningBias;
  final bool afternoonBias;
  final bool eveningBias;
  final bool weekendBias;

  /// Stable across a rotation, so the deck can avoid repeating one.
  String get id => _id ?? prompt;

  /// The card's headline. The prompt itself when the host gave no separate one.
  String get title => _title ?? prompt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'subtitle': subtitle,
    'prompt': prompt,
    'icon_name': iconName,
    if (morningBias) 'morning_bias': true,
    if (afternoonBias) 'afternoon_bias': true,
    if (eveningBias) 'evening_bias': true,
    if (weekendBias) 'weekend_bias': true,
  };

  /// How well this fits [now]. Higher wins; a suggestion with no bias at all
  /// still scores on a weekday, so an unflagged pool does not sort at random.
  int relevanceScore(DateTime now) {
    var score = 0;
    final hour = now.hour;
    final isWeekend =
        now.weekday == DateTime.saturday || now.weekday == DateTime.sunday;

    if (morningBias && hour >= 5 && hour < 12) score += 2;
    if (afternoonBias && hour >= 12 && hour < 17) score += 2;
    if (eveningBias && hour >= 17) score += 2;
    if (weekendBias && isWeekend) score += 2;
    if (!weekendBias && !isWeekend && hour >= 8 && hour < 18) score += 1;
    return score;
  }
}

/// Picks which suggestions the deck shows, and swaps one out now and then.
///
/// Scoring is deliberately jittered: two visits at the same hour should not
/// open on the same three cards, but the ones that fit the time of day should
/// still come up more often.
class AiSuggestionRotator {
  AiSuggestionRotator({
    required List<AiSuggestion> pool,
    this.visibleCount = 3,
    Random? random,
  }) : _pool = List.of(pool),
       _random = random ?? Random();

  final int visibleCount;
  final List<AiSuggestion> _pool;
  final Random _random;

  /// Ids shown recently, so a rotation does not bring back what just left.
  final _recentIds = <String>{};
  static const _maxRecent = 12;

  List<AiSuggestion> visible = const [];

  bool get canRotate => _pool.length > visibleCount;

  /// Adds what the server or the model came up with, skipping ids already in.
  void mergePool(List<AiSuggestion> extras) {
    for (final item in extras) {
      if (_pool.any((s) => s.id == item.id)) continue;
      _pool.add(item);
    }
  }

  void refresh({DateTime? now}) {
    _recentIds.clear();
    visible = _pick(
      visibleCount,
      now: now ?? DateTime.now(),
      exclude: const {},
    );
  }

  /// Replaces a single card, so the deck breathes instead of blinking whole.
  void rotateOne({DateTime? now}) {
    if (!canRotate || visible.isEmpty) return;
    final at = now ?? DateTime.now();
    final replacement = _pick(
      1,
      now: at,
      exclude: visible.map((s) => s.id).toSet(),
    );
    if (replacement.isEmpty) return;

    final index = _random.nextInt(visible.length);
    final next = List.of(visible);
    _remember(next[index].id);
    next[index] = replacement.first;
    visible = next;
  }

  List<AiSuggestion> _pick(
    int count, {
    required DateTime now,
    required Set<String> exclude,
  }) {
    if (_pool.isEmpty) return const [];

    final scored = <({AiSuggestion item, int score})>[
      for (final entry in _pool)
        if (!exclude.contains(entry.id) && !_recentIds.contains(entry.id))
          (
            item: entry,
            score: entry.relevanceScore(now) * 2 + _random.nextInt(5),
          ),
    ]..sort((a, b) => b.score.compareTo(a.score));

    final picked = <AiSuggestion>[];
    for (final row in scored) {
      if (picked.length >= count) break;
      picked.add(row.item);
      _remember(row.item.id);
    }

    // Everything left is either on screen or recently shown. A small pool hits
    // this on every rotation, so fall back to it rather than showing nothing.
    for (final entry in _pool) {
      if (picked.length >= count) break;
      if (exclude.contains(entry.id)) continue;
      if (picked.any((s) => s.id == entry.id)) continue;
      picked.add(entry);
      _remember(entry.id);
    }

    return picked;
  }

  void _remember(String id) {
    _recentIds.add(id);
    while (_recentIds.length > _maxRecent) {
      _recentIds.remove(_recentIds.first);
    }
  }
}
