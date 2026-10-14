## Unreleased

- **Breaking:** `AiModelManagerSheet` is removed. `AiModelsPage` (a dedicated
  page, `AiModelsPage.open(context, manager:)` returns true when anything
  changed) replaces it, and `AiSettingsSection` / `AiSettingsGroup` open it from
  their "On-device models" row. A download is its own page,
  `AiModelDownloadPage`, on `PortalResultScreen`: live meter with size and time
  left, Cancel, Done, and the failure with Try again, driven by
  `AiModelManager.install`. New `AiBackendLabels` strings (`cancelDownload`,
  `done`, `tryAgain`, `startingDownload`, `downloadKeepOpen`,
  `downloadReadyBody`, `downloadingTitle`, `downloadReadyTitle`, `timeLeft`),
  all with English defaults.

## Unreleased

- `AiAssistantPage.incognito` (+ `onLeaveIncognito`): a thread that is never
  kept. Nothing is saved to the store and no earlier thread is resumed; the
  page draws the kit's frame (inverse-surface ring and glow), an "Incognito:
  this chat isn't saved" chip over the composer whose dismiss leaves, and an
  empty-state note. New `AiChatLabels.incognitoChip`, `leaveIncognito`,
  `incognitoEmpty`. Additive; off by default.

## Unreleased

- `AiDocumentImportSheet`: optional `autoStart`, `intro`, `emptyTitle`,
  `emptyMessage`, `pickLabel` and `footerBuilder` (`show` takes the text ones).
  Defaults keep today's behaviour.

## 0.4.0

- **Breaking:** `AiAssistantPage.show` and `PortalAiAppKit.openAssistant`
  (deprecated in 0.3.0) are removed. Push the app's own named `/ai` route
  instead (see `PortalAiSegment.ai`) — every in-repo caller moved to this in
  the same change. Not published to pub.dev yet, so this closes out the
  deprecation rather than carrying it through a redesign.

## 0.3.0

- `AiAssistantPage.show` and `PortalAiAppKit.openAssistant` are deprecated:
  push the app's own named `/ai` route instead (see `PortalAiSegment.ai`).
  Both still work exactly as before; nothing calling either breaks.
- `PortalAiSegment.ai` (new): the route segment every app's assistant route
  is named, shared so an app builds its full path from its own root plus
  this rather than retyping `'ai'` itself.

## 0.2.2

- `AiAssistantPage`: the chat reply, redone. The per-reply avatar gutter is
  gone; each reply ends in one foot line -- the mark, Copy, Regenerate (newest
  reply only) and the time / took / steps / model caption -- and says
  "Writing" while it is coming or "Waiting for you" while a proposed change
  needs an answer. Day stamps ("Today", "Yesterday") sit between turns of
  different days. The proposed-change card, the step lines and a
  per-change receipt ("Add item") are the new shared widgets.
- Offline is told apart from a failed reply. A send that fails offline before
  anything came back marks the question "Not sent" with Retry and draws no
  reply; the header reads "Can't reach" until a send gets through. A reply
  that dies mid-flight keeps what it had written and ends in the failure
  sentence with Retry.
- A kept turn now records each step it ran (`payload['tools']`), so receipts
  survive a reload. Threads saved without it read as before.
- `AiChatLabels`: `writing`, `waitingForYou`, `notSent`, `cantReach`,
  `copyReply`, `regenerate`, `typeAChange`, `accept`, `decline`, plus
  `changeModel`, `aiSettings` and `aiProvider` for the three strings that were
  literals. All optional, with the English defaults.
- Your own bubble keeps readable text over the accent gradient.

## 0.2.1

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

