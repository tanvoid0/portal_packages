# portal_ai

Platform-aware AI backend discovery and a shared chat runtime for Flutter apps.
Finds what is available on the device (Gemini Nano via AICore, a local Ollama
on the LAN, a cloud key, or a server-side completion endpoint), picks one, and
gives apps a single chat/tool interface on top.

<p>
<img src="https://raw.githubusercontent.com/tanvoid0/portal_packages/main/portal_ai/doc/screenshots/assistant.png" width="220" alt="Assistant page: markdown reply with a table, a proposal card and the composer">
<img src="https://raw.githubusercontent.com/tanvoid0/portal_packages/main/portal_ai/doc/screenshots/assistant_thinking.png" width="220" alt="Same reply with the thought process expanded">
</p>

`example/` drives the page with a canned conversation — no model needed to
see the widgets.

- `AiBackendDiscovery` — probe backends, ranked by preference and availability.
- `PortalAiRuntime` — one entry point; apps supply prompts/tools, runtime picks the client.
- `AiChatSession` / `AiChatStore` — persisted multi-turn threads.
- `AiProposal` — structured "model proposes, user confirms" edits.
- `clients/` — OpenAI-compatible (any provider), Ollama, Gemini, server completion, a server-first `FallbackCompletionClient`, and a document/multimodal client.
- `widgets/` — chat deck, composer, gate and thread inbox.

```dart
final ai = PortalAiRuntime.create(
  post: apiClient.post,            // Future<Map> Function(String path, Map body)
  env: dotenv.env,
  feature: 'gym-assistant',
  appDescription: 'Portal Gym - workouts, routines and exercise logs.',
  tools: gymAiTools(),
);
final result = await ai.ask('Summarise this week', onReply: (delta) => print(delta));
```

## Backends — with or without a server

`PortalAiRuntime.create` picks a client from what it is given. Nothing here
needs a server; the server is one option among five.

| backend | configured by | notes |
|---|---|---|
| **Ollama** (dev override) | `AI_OLLAMA_MODEL` / `AI_OLLAMA_HOST` in the `env` map | wins over everything — point a checkout at a local model, costs nothing |
| **On-device** — Gemini Nano via AICore / ML Kit GenAI | user picks it in AI settings | Android devices with AICore; no network at all |
| **Ollama** on the LAN | user picks it in settings, enters the host | the phone talks to a machine on the same network |
| **Any OpenAI-compatible API** | user pastes base URL + model + key in settings, or the app ships defaults in `.env` | OpenAI, Groq, OpenRouter, DeepSeek, Mistral, xAI, Together, LM Studio, Ollama `/v1`, Gemini's OpenAI endpoint — one client, `openAiCompatiblePresets` has the URLs |
| **Your server** | `post` (and optionally `postStream`) | the key, model choice and per-user quota stay server-side; "cloud" in settings routes here |

### Keys: bring your own, or ship one

Two ways to get a key into the OpenAI-compatible backend; the user's always
wins:

- **BYOK.** The AI settings section (`AiSettingsSection`) has base URL,
  model and key fields with a *Test* button. The key goes to
  `flutter_secure_storage`, never to shared preferences or the server.
- **Developer default.** `AI_OPENAI_BASE_URL`, `AI_OPENAI_MODEL`,
  `AI_OPENAI_API_KEY` in the app's `.env` (the `env` map you pass to
  `create`). The app works out of the box without the user entering
  anything.

  A key in a bundled `.env` is inside the APK and extractable in minutes —
  this is fine for a private or sideloaded build and for development, and
  the wrong choice for a store app, where anyone can run up your bill. For
  a store app, use the server transport: the key never leaves your backend.

### Routing: server first, local when it can't

When a server transport is present, `AiRoutingMode` (a control in the
settings section, persisted per app) decides:

| mode | behaviour |
|---|---|
| `serverFirst` (default) | try the server; on a transport failure — offline, DNS, timeout, 5xx — answer with the local backend the user configured, and mark the reply as answered locally. A 4xx (auth, quota) is surfaced, never hidden behind a fallback. |
| `localOnly` | never touch the server. Privacy, airplane mode, or a user who just prefers their own model. |
| `serverOnly` | the pre-0.2 behaviour. |

Without a server transport the mode is moot: whatever local backend is
configured answers, or the runtime tells you nothing is.

`FallbackCompletionClient` is exported on its own if you want the same
primary-then-fallback shape between any two clients.

### The server contract

`ServerCompletionClient` speaks two routes. Any stack can serve them; the
callbacks are plain functions so the package never sees your auth or HTTP
client.

```
POST {path}            default path: /ai/complete
  body     { systemPrompt, prompt, jsonMode, temperature, feature }
  response { text, model?, usage?: { promptTokens, completionTokens } }

POST {path}/stream     server-sent events, one JSON object per `data:` line
  frames   { "text": "delta" }   { "error": "message" }   [DONE]
```

`feature` is a lowercase slug the app passes so the server can meter usage
per feature (`gym-assistant`, `recipe-import`).

### A server in twenty lines with llmwire

[llmwire](https://www.npmjs.com/package/llmwire) is the same author's
zero-dependency TypeScript client for OpenAI, Anthropic, Gemini, Ollama and
any OpenAI-compatible API — one request shape, real streaming. It makes the
two routes above a few lines each; the provider is chosen by env var or
`modelId`, so the app never changes.

```ts
import { aiFactory } from 'llmwire';

// POST /ai/complete
app.post('/ai/complete', async (req, res) => {
  const { systemPrompt, prompt, jsonMode, temperature } = req.body;
  const out = await aiFactory.process({ systemPrompt, prompt, jsonMode, temperature });
  res.json({ text: out.data, model: out.modelUsed, usage: out.usage });
});

// POST /ai/complete/stream
app.post('/ai/complete/stream', async (req, res) => {
  const { systemPrompt, prompt, temperature } = req.body;
  res.setHeader('Content-Type', 'text/event-stream');
  try {
    for await (const chunk of aiFactory.processStream({ systemPrompt, prompt, temperature })) {
      if (chunk.type === 'text') res.write(`data: ${JSON.stringify({ text: chunk.text })}

`);
    }
  } catch (e) {
    res.write(`data: ${JSON.stringify({ error: String(e) })}

`);
  }
  res.write('data: [DONE]

');
  res.end();
});
```

Add auth and a quota check in front of both and that is the whole AI side of
a Portal-style server. `post` in the app is then `apiClient.post` from
[portal_platform](https://pub.dev/packages/portal_platform), which brings the
session token along.
