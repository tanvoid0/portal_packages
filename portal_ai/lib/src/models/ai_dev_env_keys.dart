/// Env keys that point the assistant at a local model during development,
/// bypassing the server.
///
/// For the OpenAI-compatible backend these are a *developer default*, not an
/// override: [AiCompletionClientFactory.create] reads AI settings first and
/// only falls back to `.env` for whichever of base URL / model / key the
/// store has none of. A user who enters their own key in AI settings always
/// wins over whatever `.env` ships with the build.
///
/// A key in a bundled `.env` is extractable from the built APK -- fine for
/// local dev and a private/sideloaded build, never for anything offered
/// through a store listing. A store app talks to a provider through the
/// server, which holds the key instead.
abstract final class AiDevEnvKeys {
  /// Set to an Ollama model (e.g. `gemma4`) to bypass the server while testing.
  static const ollamaModel = 'AI_OLLAMA_MODEL';

  /// Optional Ollama host override.
  static const ollamaHost = 'AI_OLLAMA_HOST';

  /// Base URL for the OpenAI-compatible backend, used when AI settings has
  /// none stored.
  static const openAiBaseUrl = 'AI_OPENAI_BASE_URL';

  /// Model id for the OpenAI-compatible backend.
  static const openAiModel = 'AI_OPENAI_MODEL';

  /// API key for the OpenAI-compatible backend.
  static const openAiApiKey = 'AI_OPENAI_API_KEY';
}
