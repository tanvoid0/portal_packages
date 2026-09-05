import 'package:flutter/material.dart';

import '../chat/ai_suggestion.dart';

/// The deck of prompts shown before the first question.
///
/// Lifted from portal_task's AI home, which had the better answer than the
/// wrap of chips this replaces: a card can carry a headline, a line of context
/// and an icon, so a suggestion reads as an offer rather than as a leftover
/// search term. A suggestion with nothing but a prompt still renders -- the
/// card just closes up around the headline.
class AiSuggestionCards extends StatelessWidget {
  const AiSuggestionCards({
    super.key,
    required this.suggestions,
    required this.onTap,
    this.enabled = true,
    this.onShuffle,
    this.onRefresh,
    this.refreshing = false,
    this.shuffleLabel = 'Shuffle',
    this.refreshLabel = 'More ideas',
  });

  final List<AiSuggestion> suggestions;
  final ValueChanged<AiSuggestion> onTap;

  /// Greys the deck out and swallows taps, for a page behind a consent gate.
  final bool enabled;

  /// Re-picks from the pool already loaded. Free and instant, unlike
  /// [onRefresh]; null hides the card.
  final VoidCallback? onShuffle;

  /// Asks the model for new ones. Null when there is no model to ask.
  final Future<void> Function()? onRefresh;
  final bool refreshing;

  final String shuffleLabel;
  final String refreshLabel;

  static const _cardWidth = 200.0;
  static const _cardHeight = 108.0;

  @override
  Widget build(BuildContext context) {
    if (suggestions.isEmpty && onShuffle == null && onRefresh == null) {
      return const SizedBox.shrink();
    }
    final actions = <Widget>[
      if (onShuffle case final shuffle?)
        _ActionCard(
          icon: Icons.shuffle_rounded,
          label: shuffleLabel,
          onTap: enabled ? shuffle : null,
        ),
      if (onRefresh case final refresh?)
        _ActionCard(
          icon: Icons.auto_awesome_outlined,
          label: refreshLabel,
          busy: refreshing,
          onTap: enabled && !refreshing ? refresh : null,
        ),
    ];

    return SizedBox(
      height: _cardHeight,
      child: Opacity(
        opacity: enabled ? 1 : 0.45,
        child: ListView.separated(
          primary: false,
          scrollDirection: Axis.horizontal,
          itemCount: suggestions.length + actions.length,
          separatorBuilder: (_, _) => const SizedBox(width: 12),
          itemBuilder: (context, index) {
            if (index >= suggestions.length) {
              return actions[index - suggestions.length];
            }
            final suggestion = suggestions[index];
            return _SuggestionCard(
              suggestion: suggestion,
              width: _cardWidth,
              height: _cardHeight,
              onTap: enabled ? () => onTap(suggestion) : null,
            );
          },
        ),
      ),
    );
  }
}

class _SuggestionCard extends StatelessWidget {
  const _SuggestionCard({
    required this.suggestion,
    required this.width,
    required this.height,
    this.onTap,
  });

  final AiSuggestion suggestion;
  final double width;
  final double height;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final hasSubtitle = suggestion.subtitle.isNotEmpty;
    return Material(
      color: scheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        // A rotation swaps one card in place; without this it would pop.
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 280),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          child: Container(
            key: ValueKey(suggestion.id),
            width: width,
            height: height,
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  aiSuggestionIcon(suggestion.iconName),
                  color: scheme.primary,
                  size: 20,
                ),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Flexible(
                        child: Text(
                          suggestion.title,
                          // A bare prompt has no subtitle to make room for, so
                          // it gets the whole card to wrap into.
                          maxLines: hasSubtitle ? 2 : 3,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: scheme.onSurface,
                          ),
                        ),
                      ),
                      if (hasSubtitle) ...[
                        const SizedBox(height: 4),
                        Flexible(
                          child: Text(
                            suggestion.subtitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.label,
    this.busy = false,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final bool busy;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Material(
      color: scheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 76,
          height: AiSuggestionCards._cardHeight,
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (busy)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Icon(icon, color: scheme.primary, size: 18),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Maps [AiSuggestion.iconName] onto a Material icon.
///
/// A name rather than an `IconData` so a suggestion can arrive as JSON from the
/// server, which is where the personalised ones come from. Unknown names draw
/// the spark, so a server that learns a new one does not ship a blank card.
IconData aiSuggestionIcon(String name) => switch (name) {
  'graduation' => Icons.school_outlined,
  'book' => Icons.menu_book_outlined,
  'briefcase' => Icons.work_outline,
  'calendar' => Icons.event_outlined,
  'workout' || 'dumbbell' => Icons.fitness_center_outlined,
  'moon' => Icons.bedtime_outlined,
  'sun' => Icons.wb_sunny_outlined,
  'leaf' => Icons.eco_outlined,
  'heart' => Icons.favorite_outline,
  'utensils' => Icons.restaurant_outlined,
  'plane' => Icons.flight_outlined,
  'coffee' => Icons.coffee_outlined,
  'home' => Icons.home_outlined,
  'cart' => Icons.shopping_cart_outlined,
  'money' => Icons.payments_outlined,
  'chart' => Icons.insights_outlined,
  'clock' => Icons.schedule_outlined,
  'list' => Icons.checklist_outlined,
  _ => Icons.auto_awesome_outlined,
};
