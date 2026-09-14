import 'ai_backend_kind.dart';

/// A discovered or configured AI backend the user can select.
class AiBackendOption {
  const AiBackendOption({
    required this.kind,
    required this.available,
    this.unavailableReason,
    this.models = const [],
    this.metadata = const {},
  });

  final AiBackendKind kind;
  final bool available;

  /// Shown when [available] is false.
  final String? unavailableReason;

  /// Model ids reported by the backend (e.g. Ollama tags).
  final List<String> models;

  /// Extra probe data (host URL, package version, etc.).
  final Map<String, Object?> metadata;

  String get id => kind.id;

  bool get supportsInAppInference =>
      kind == AiBackendKind.cloudGemini ||
      kind == AiBackendKind.ollama ||
      kind == AiBackendKind.systemOnDevice ||
      kind == AiBackendKind.openAiCompatible;

  AiBackendOption copyWith({
    bool? available,
    String? unavailableReason,
    List<String>? models,
    Map<String, Object?>? metadata,
  }) {
    return AiBackendOption(
      kind: kind,
      available: available ?? this.available,
      unavailableReason: unavailableReason ?? this.unavailableReason,
      models: models ?? this.models,
      metadata: metadata ?? this.metadata,
    );
  }
}
