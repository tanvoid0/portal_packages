import '../chat/ai_suggestion.dart';
import '../tools/ai_tool.dart';

/// One role the assistant can take: a named expert with its own system-prompt
/// voice and its own tool subset.
///
/// A persona is exactly the two things [AiAgent] already runs on —
/// [description] (which becomes the agent's `appDescription`, i.e. the line
/// that opens the system prompt) and [tools] — plus a label and the hints a
/// router needs to pick it.
///
/// That is deliberate: it is the whole seam between phases. Phase one fills
/// [tools] with advice-and-handoff tools (open the sibling app that can act);
/// a later phase drops real cross-app executors into the same list. Nothing in
/// this class or in the runtime changes between the two — only what each
/// persona's [tools] contains.
class AiPersona {
  const AiPersona({
    required this.id,
    required this.label,
    required this.description,
    this.tools = const [],
    this.keywords = const [],
    this.suggestions = const [],
    this.icon,
  });

  /// Stable identifier the router returns and a thread pins. snake_case.
  final String id;

  /// What the user sees on the selector chip and the answered-turn badge.
  final String label;

  /// The persona's voice: replaces the runtime's `appDescription` in the
  /// system prompt, so it is what tells the model who it is acting as.
  final String description;

  /// What this persona may do. May be empty (a pure-advice role).
  final List<AiTool> tools;

  /// Lower-case words that, if present in the prompt, pick this persona
  /// without an LLM call. A cheap deterministic fast path before the router
  /// spends a completion. Empty means "always ask the router".
  final List<String> keywords;

  /// Starter chips to show when this persona is the active one. Optional.
  final List<AiSuggestion> suggestions;

  /// A monochrome SVG string drawn as the persona's mark on its selector chip.
  /// Recoloured to the chip ink via [PortalGlyph], so the drawing's own fills
  /// are irrelevant. Null means no mark (label only).
  final String? icon;

  /// `- Label (id=shopping): description`, the one-line form the router prompt
  /// lists a persona as. Mirrors how the reference planner renders its roster.
  String get rosterLine => '- $label (id=$id): $description';
}
