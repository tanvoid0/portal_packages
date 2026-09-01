/// Something the assistant suggests, for the user to add, edit or throw away.
///
/// Deliberately shallow: a title, a line under it and a badge. Anything richer
/// -- a task's recurrence, a grocery item's aisle -- belongs in [payload],
/// which portal_ai never reads. The host formats what it wants shown and keeps
/// the real model to itself, so this stays one class for every app.
class AiProposal {
  const AiProposal({
    required this.id,
    required this.title,
    this.subtitle = '',
    this.badge = '',
    this.payload = const {},
  });

  final String id;
  final String title;

  /// One line under the title: dates, durations, whatever the app formats.
  final String subtitle;

  /// Short chip beside the title, e.g. the kind of thing being proposed.
  final String badge;

  /// Host-owned. Handed back verbatim on accept/edit/discard.
  final Map<String, dynamic> payload;
}
