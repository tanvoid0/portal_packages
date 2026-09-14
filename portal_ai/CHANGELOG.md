## 0.2.0

- `OpenAiCompatibleCompletionClient`: one client for any provider that speaks
  the OpenAI chat-completions API -- OpenAI, Groq, OpenRouter, DeepSeek,
  Mistral, xAI, Together, LM Studio, or Ollama's `/v1` endpoint -- with a
  user- or developer-supplied key, plus a `openAiCompatiblePresets` list for
  the settings dropdown.
- `FallbackCompletionClient` and `AiRoutingMode`: try the server first, fall
  back to a local backend only on a transport failure (never on a 4xx), with
  a user-selectable routing mode (`serverFirst`, `localOnly`, `serverOnly`)
  wired into `PortalAiRuntime`.
- AI settings gained an OpenAI-compatible backend row (preset, base URL,
  model, API key, Test) and a routing control, shown once the host passes
  `hasServer: true`. The API key is stored via `flutter_secure_storage`.

## 0.1.3

- README: backend selection order and the server contract, with an llmwire example.

