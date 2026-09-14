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
- `clients/` — Gemini, Ollama, server completion (streaming) and a document/multimodal client.
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

`PortalAiRuntime.create` picks a client from what it is given, in this order.
Nothing here needs a server; the server is one option among four.

| backend | comes from | notes |
|---|---|---|
| **Ollama** (dev override) | `AI_OLLAMA_MODEL` / `AI_OLLAMA_HOST` in the `env` map | wins over everything — point a checkout at a local model, costs nothing |
| **On-device** (Gemini Nano via AICore / ML Kit GenAI) | user picks it in the AI settings section (`AiBackendStore`) | Android devices with AICore; no network at all |
| **Ollama** on the LAN | user picks it in settings and enters the host | same client as the override, user-chosen |
| **Gemini cloud** with the user's own key | user picks it in settings and pastes a key | the key lives in the app's secure prefs, never in the build |
| **Your server** | `post` (and optionally `postStream`) | production default: the key, model choice and per-user quota stay server-side; "cloud" in settings routes here whenever a server exists |

Omit `post` and the runtime works entirely on-device / LAN / with the user's
own key — the settings section (`AiSettingsSection`) lets them choose. Give
it `post` and cloud requests go to your API instead.

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
