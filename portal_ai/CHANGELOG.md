## Unreleased

- `AiSettingsGroup`: the assistant's settings as a grouped list of rows --
  provider, routing (only with `hasServer`) and on-device models -- each with
  its current value, each opening its own sheet. Takes the same arguments as
  `AiSettingsSection` plus `onModels` for a host with a models screen of its
  own. The provider row reuses `AiSettingsSection` inside a sheet.
- `AiRoutingSheet`: pick a routing mode and Apply it; Apply stays off until the
  pick differs from the stored mode, and "Server only" is disabled with
  `cloudNote` for an account that cannot use the cloud.
- `aiInstalledModelsLabel`: the models row's value -- installed total size when
  the manager's catalog knows every installed model, else a count.
- `AiSettingsSection.showRouting` (default `true`) hides the routing control
  without touching `hasServer`.
- `AiBackendLabels`: `assistantTitle`, `providerRow`, `routingRow`,
  `modelsRow`, `cloudNote`, `apply` and `modelsInstalled(n)`.

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

