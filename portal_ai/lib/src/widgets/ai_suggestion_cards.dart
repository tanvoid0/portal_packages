import 'package:flutter/material.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

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
    this.wrap = false,
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

  /// Lays the cards out two-up and wrapping instead of in one horizontal
  /// scroller.
  ///
  /// The scroller is right where the deck sits above a transcript: it is a
  /// strip, it is obviously scrollable next to the conversation under it,
  /// and it costs one row of height. It is wrong as the opening screen of a
  /// full-page assistant, which is the only thing on screen: there it hides
  /// half the suggestions off the right edge with nothing to say they are
  /// there, and a suggestion nobody sees is a suggestion that does not
  /// exist. Wrapped, every one of them is readable at a glance.
  final bool wrap;

  @override
  Widget build(BuildContext context) {
    if (suggestions.isEmpty && onShuffle == null && onRefresh == null) {
      return const SizedBox.shrink();
    }
    final scheme = Theme.of(context).colorScheme;
    final cards = [
      for (final suggestion in suggestions)
        PortalPromptCard(
          icon: aiSuggestionIcon(suggestion.iconName),
          title: suggestion.title,
          subtitle: suggestion.subtitle.isEmpty ? null : suggestion.subtitle,
          onTap: enabled ? () => onTap(suggestion) : null,
        ),
      if (onShuffle case final shuffle?)
        PortalPromptCard(
          icon: Icons.shuffle_rounded,
          title: shuffleLabel,
          onTap: enabled ? shuffle : null,
          tileColor: scheme.surfaceContainerHighest,
        ),
      if (onRefresh case final refresh?)
        // ponytail: PortalPromptCard takes an IconData, not a widget, so
        // there's no slot to swap in a spinner while refreshing the way the
        // old _ActionCard did -- disabling the tap is what's left of that.
        // Upgrade path: a `leading` widget override on PortalPromptCard if
        // the busy state is worth showing again.
        PortalPromptCard(
          icon: Icons.auto_awesome_rounded,
          title: refreshLabel,
          onTap: enabled && !refreshing ? refresh : null,
          tileColor: scheme.surfaceContainerHighest,
        ),
    ];

    // Both hosts (the assistant page's own column, portal_task's AI home)
    // already inset the page horizontally -- a second edge padding here
    // would double it.
    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: PortalPromptCardRow(
        wrapped: wrap,
        padding: EdgeInsets.zero,
        children: cards,
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
  _ => Icons.auto_awesome_rounded,
};
