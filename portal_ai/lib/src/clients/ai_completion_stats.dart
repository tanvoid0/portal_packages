/// What a backend says it used answering one completion.
///
/// Every field is optional: the on-device path reports nothing, Ollama
/// reports counts and a model name, and the Portal server reports whatever
/// its route chose to include. A missing number is shown as missing rather
/// than as zero.
class AiCompletionStats {
  const AiCompletionStats({this.model, this.promptTokens, this.replyTokens});

  final String? model;
  final int? promptTokens;
  final int? replyTokens;

  bool get isEmpty =>
      model == null && promptTokens == null && replyTokens == null;

  int? get totalTokens => promptTokens == null && replyTokens == null
      ? null
      : (promptTokens ?? 0) + (replyTokens ?? 0);

  /// Adds [other]'s counts to these, for a run that took several calls. The
  /// model name is whatever answered last -- a run never switches backend
  /// mid-flight, so they agree in practice.
  AiCompletionStats merge(AiCompletionStats other) => AiCompletionStats(
    model: other.model ?? model,
    promptTokens: _add(promptTokens, other.promptTokens),
    replyTokens: _add(replyTokens, other.replyTokens),
  );

  static int? _add(int? a, int? b) =>
      a == null && b == null ? null : (a ?? 0) + (b ?? 0);
}

/// Mixed into the clients whose backend reports usage.
///
/// Deliberately not part of [AiCompletionClient]: most implementations have
/// nothing to report, and widening the interface would force all of them --
/// plus every test fake -- to carry a field they would leave null. Read it
/// with [aiStatsOf], which asks the question without knowing the answer.
mixin AiCompletionStatsSource {
  /// Usage from the most recent completion, or null before the first one.
  AiCompletionStats? lastStats;
}

/// [AiCompletionStatsSource.lastStats] when [client] keeps any, else null.
AiCompletionStats? aiStatsOf(Object? client) =>
    client is AiCompletionStatsSource ? client.lastStats : null;
