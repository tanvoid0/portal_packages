# portal_ai

Platform-aware AI backend discovery and a shared chat runtime for Flutter apps.
Finds what is available on the device (Gemini Nano via AICore, a local Ollama
on the LAN, a cloud key, or a server-side completion endpoint), picks one, and
gives apps a single chat/tool interface on top.

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

Server-backed clients take a `post`/`postStream` callback so the package has no
dependency on any particular HTTP/auth layer.
