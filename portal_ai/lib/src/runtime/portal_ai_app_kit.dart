import 'dart:async';

import 'package:flutter/material.dart';

import '../chat/ai_suggestion.dart';
import '../chat/prefs_ai_chat_store.dart';
import '../clients/ai_completion_client_factory.dart';
import '../clients/server_completion_client.dart';
import '../local/local_llm_engine.dart';
import '../prefs/ai_backend_store.dart';
import '../prefs/ai_prefs_sync_service.dart';
import '../tools/ai_tool.dart';
import '../widgets/ai_assistant_page.dart';
import '../widgets/ai_settings_group.dart';
import '../widgets/ai_settings_section.dart';
import 'portal_ai_runtime.dart';

/// The wiring every Portal app repeats to stand up its assistant: open the
/// backend-choice store, start the account-wide prefs sync, build
/// [PortalAiRuntime], open this app's own chat-thread store — then a
/// settings-page widget and an assistant-page widget built from the same
/// store.
///
/// Six apps (gym, journey, lifestyle, shopping, recipe, finance) hand-built
/// this identically under `init<X>Ai`/`<x>AiSettings`/`<x>AssistantPage`/
/// `open<X>Assistant`; this is that shape, once. Each app keeps its own
/// top-level functions — its tools, `appDescription`, title and suggestions
/// never moved — they delegate to one `PortalAiAppKit` instance instead of
/// repeating the store/sync/chat-store plumbing by hand.
///
/// This package has no GetX dependency of its own, so [init] *builds and
/// returns* the runtime rather than registering it — the caller still does
/// `Get.put(runtime, permanent: true)` itself, exactly as before, because
/// other call sites in the app (`Get.find<PortalAiRuntime>()` from a view or
/// an import service) depend on that registration too. [settingsGroup],
/// [assistantPage] and [openAssistant] likewise take the runtime as a
/// parameter rather than looking it up. [init]'s `get`/`put`/`post`/
/// `postStream` are `ApiClient`'s methods passed straight through (see
/// [AiGetJson]/[AiPutJson]/[AiPostJson]/[AiPostStream]) for the same reason:
/// so this package never needs to depend on `portal_platform`.
class PortalAiAppKit {
  PortalAiAppKit({required this.storeKey, this.feature = 'assistant'})
    : chatStoreKey = '${storeKey}_chat';

  /// Prefix for [AiSettingsSection.openStore] and the chat store beneath it
  /// (e.g. `portal_gym_ai` / `portal_gym_ai_chat`).
  final String storeKey;
  final String chatStoreKey;
  final String feature;

  AiBackendStore? _backendStore;
  AiPrefsSyncService? _aiPrefsSync;
  PrefsAiChatStore? _chatStore;

  /// The thread store [init] opened. Null before it has run.
  PrefsAiChatStore? get chatStore => _chatStore;

  /// The backend-choice store [init] opened. Null before it has run.
  ///
  /// Exposed for the one app (the dedicated assistant) that changes it
  /// directly from an on-device-model picker rather than through
  /// [settingsGroup]'s `onChanged`; call [markPrefsChanged] after.
  AiBackendStore? get backendStore => _backendStore;

  /// Marks the account-wide prefs dirty and re-syncs — the step
  /// [settingsGroup]'s `onChanged` takes automatically, for a caller that
  /// changed [backendStore] some other way.
  Future<void> markPrefsChanged() async {
    final sync = _aiPrefsSync;
    if (sync != null) await sync.markChanged();
  }

  /// Opens the backend store, starts the account-wide prefs sync, opens this
  /// app's chat-thread store, and returns the [PortalAiRuntime] built from
  /// [tools]/[appDescription]/[post]/[postStream]. The caller registers the
  /// result (see the class doc).
  Future<PortalAiRuntime> init({
    required AiGetJson get,
    required AiPutJson put,
    AiPostJson? post,
    AiPostStream? postStream,
    Map<String, String> env = const {},
    String appDescription = '',
    List<AiTool> tools = const [],
    AiCompletionClientFactory? clientFactory,
  }) async {
    final store = await AiSettingsSection.openStore(storeKey);
    _backendStore = store;
    final sync = AiPrefsSyncService(store: store, get: get, put: put);
    _aiPrefsSync = sync;
    unawaited(sync.sync());
    _chatStore = await PrefsAiChatStore.open(chatStoreKey);
    return PortalAiRuntime.create(
      store: store,
      post: post,
      postStream: postStream,
      env: env,
      feature: feature,
      appDescription: appDescription,
      tools: tools,
      clientFactory: clientFactory,
    );
  }

  /// The AI group for this app's settings page. `onChanged` re-points
  /// [runtime] and marks the account-wide prefs dirty — the two steps every
  /// app's settings page took by hand. Blank until [runtime] exists: before
  /// [init] resolves, or if it threw and the app never registered one.
  ///
  /// [localLlm]/[onModels] pass straight to [AiSettingsGroup], for the one
  /// app (the dedicated assistant) that bundles an on-device engine.
  Widget settingsGroup({
    required PortalAiRuntime? runtime,
    required bool cloudEligible,
    LocalLlmEngine? localLlm,
    VoidCallback? onModels,
  }) {
    final store = _backendStore;
    if (store == null || runtime == null) return const SizedBox.shrink();
    return AiSettingsGroup(
      store: store,
      // Every app wires PortalAiRuntime.create with `post:` in [init], so a
      // server transport exists -- the routing control has something to
      // route between.
      hasServer: true,
      cloudEligible: cloudEligible,
      localLlm: localLlm,
      onModels: onModels,
      onChanged: (option) {
        runtime.applyBackend(option);
        final sync = _aiPrefsSync;
        if (sync != null) unawaited(sync.markChanged());
      },
    );
  }

  /// The assistant as a page body — a tab/shell route builds it directly,
  /// and a deep link (nothing behind it to push over) builds it the same way
  /// with whatever the link carried as [initialPrompt].
  Widget assistantPage({
    required PortalAiRuntime runtime,
    required String title,
    List<AiSuggestion> suggestions = const [],
    void Function(String entity, AiItem item)? onItemTap,
    Future<bool> Function(AiToolCall call)? onEditToolCall,
    bool Function(AiToolCall call)? canEditToolCall,
    String? initialPrompt,
    bool autoSend = false,
  }) => AiAssistantPage(
    runtime: runtime,
    store: _chatStore,
    onItemTap: onItemTap,
    onEditToolCall: onEditToolCall,
    canEditToolCall: canEditToolCall,
    title: title,
    suggestions: suggestions,
    initialPrompt: initialPrompt,
    autoSend: autoSend,
    fill: true,
  );

  /// Pushes the assistant as a sheet/dialog over whatever is already
  /// showing — the form every app's "ask the assistant" entry point opens
  /// from.
  void openAssistant(
    BuildContext context, {
    required PortalAiRuntime runtime,
    required String title,
    List<AiSuggestion> suggestions = const [],
    void Function(String entity, AiItem item)? onItemTap,
    Future<bool> Function(AiToolCall call)? onEditToolCall,
    bool Function(AiToolCall call)? canEditToolCall,
  }) => AiAssistantPage.show(
    context,
    runtime: runtime,
    store: _chatStore,
    onItemTap: onItemTap,
    onEditToolCall: onEditToolCall,
    canEditToolCall: canEditToolCall,
    title: title,
    suggestions: suggestions,
  );
}
