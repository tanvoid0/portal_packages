import 'package:flutter/material.dart';

import 'ai_backend_kind.dart';
import 'ai_routing_mode.dart';

/// User-visible labels for [AiBackendOption] rows.
class AiBackendLabels {
  const AiBackendLabels({
    this.cloudGeminiTitle = 'Portal Cloud (Gemini)',
    this.cloudGeminiDescription =
        'Uses Structured Cloud. Requires sign-in and AI terms.',
    this.ollamaTitle = 'Ollama',
    this.ollamaDescription =
        'Runs on this device via Ollama. Private and offline-capable.',
    this.onDeviceTitle = 'On-device model',
    this.onDeviceDescription =
        'Runs on this phone using its built-in model. Private and offline.',
    this.edgeGalleryTitle = 'Google AI Edge Gallery',
    this.edgeGalleryDescription =
        'Opens the Edge Gallery app for on-device chat (external).',
    this.localLlmTitle = 'On this device',
    this.localLlmDescription =
        'Runs a model you download here, inside this app. Private, offline, '
        'no server and no other app.',
    this.openAiCompatibleTitle = 'OpenAI-compatible API',
    this.openAiCompatibleDescription =
        'Any provider that speaks the OpenAI chat API — OpenAI, Groq, '
        'OpenRouter, DeepSeek, Mistral, xAI, Together, LM Studio, Ollama — '
        'with your own key.',
    this.openAiPreset = 'Provider preset',
    this.openAiCustomPreset = 'Custom',
    this.openAiBaseUrl = 'Base URL',
    this.openAiApiKey = 'API key',
    this.openAiShowKey = 'Show API key',
    this.openAiHideKey = 'Hide API key',
    this.openAiTest = 'Test',
    this.openAiTestOk = 'Reachable',
    this.openAiTestFail = 'Not reachable',
    this.openAiApiKeySaveFailed = 'Could not save the API key',
    this.routingTitle = 'Routing',
    this.routingServerFirst = 'Server first',
    this.routingServerFirstDescription =
        'Try the server; fall back to your local backend if it is '
        'unreachable.',
    this.routingLocalOnly = 'Local only',
    this.routingLocalOnlyDescription =
        'Always use your local backend, even with a server available.',
    this.routingServerOnly = 'Server only',
    this.routingServerOnlyDescription =
        'Always use the server, even with a local backend configured.',
    this.unavailable = 'Unavailable',
    this.selectedBadge = 'Selected',
    this.scanning = 'Checking available providers…',
    this.noProviders = 'No AI providers are available on this device.',
    this.selectProvider = 'AI provider',
    this.model = 'Model',
    this.noModels = 'This provider reported no models.',
    this.ollamaHost = 'Ollama host',
    this.download = 'Download model',
    this.downloading = 'Downloading…',
    this.rescan = 'Rescan providers',
    this.external = 'External',
    this.findOllama = 'Find on my network',
    this.searchingOllama = 'Looking for Ollama…',
    this.manageModels = 'Models',
    this.manageModelsTitle = 'Models',
    this.installedModels = 'On this device',
    this.availableModels = 'Available to download',
    this.noInstalledModels = 'No models downloaded yet.',
    this.install = 'Download',
    this.installing = 'Downloading…',
    this.installFailed = 'Download failed',
    this.removeModel = 'Delete',
    this.removeModelConfirm =
        'Delete this model from the device? It can be downloaded again.',
    this.cancel = 'Cancel',
    this.cancelDownload = 'Cancel download',
    this.done = 'Done',
    this.tryAgain = 'Try again',
    this.startingDownload = 'Starting download',
    this.downloadKeepOpen =
        'Keep this screen open until the download finishes.',
    this.downloadReadyBody =
        'It now runs on this device, even with no connection.',
    this.customModelHint = 'Or type a model name',
    this.downloadingModels = 'Downloading',
    this.modelsEmptyTitle = 'No models yet',
    this.modelsEmptyMessage =
        'Download one and the assistant can answer on this device, with no connection.',
    this.modelsEmptyAction = 'Download a model',
    this.modelsUnsupportedTitle = 'Not available on this device',
    this.modelsOfflineTitle = 'Offline',
    this.modelsOfflineMessage = 'Connect to download models.',
    this.modelsLoadFailed = "Couldn't load your models.",
    this.retry = 'Retry',
    this.activeBadge = 'Active',
    this.useModel = 'Use this model',
    this.oneDownloadAtATime = 'One download at a time',
    this.oneDownloadAtATimeBody = 'Wait for the one in progress to finish.',
    this.finishingUp = 'Finishing up',
    this.downloadLeaveBody =
        'You can leave this screen. The download keeps going while the app is open.',
    this.ollamaNotFound =
        'No Ollama found on this network. Check it is running and reachable, '
        'then enter its address above.',
    this.assistantTitle = 'Assistant',
    this.providerRow = 'AI provider',
    this.routingRow = 'Routing',
    this.modelsRow = 'On-device models',
    this.cloudNote = 'Sign in to use Portal Cloud',
    this.apply = 'Apply',
  });

  final String cloudGeminiTitle;
  final String cloudGeminiDescription;
  final String ollamaTitle;
  final String ollamaDescription;
  final String onDeviceTitle;
  final String onDeviceDescription;
  final String edgeGalleryTitle;
  final String edgeGalleryDescription;
  final String localLlmTitle;
  final String localLlmDescription;
  final String openAiCompatibleTitle;
  final String openAiCompatibleDescription;
  final String openAiPreset;
  final String openAiCustomPreset;
  final String openAiBaseUrl;
  final String openAiApiKey;
  final String openAiShowKey;
  final String openAiHideKey;
  final String openAiTest;
  final String openAiTestOk;
  final String openAiTestFail;
  final String openAiApiKeySaveFailed;
  final String routingTitle;
  final String routingServerFirst;
  final String routingServerFirstDescription;
  final String routingLocalOnly;
  final String routingLocalOnlyDescription;
  final String routingServerOnly;
  final String routingServerOnlyDescription;
  final String unavailable;
  final String selectedBadge;
  final String scanning;
  final String noProviders;
  final String selectProvider;
  final String model;
  final String noModels;
  final String ollamaHost;
  final String download;
  final String downloading;
  final String rescan;
  final String external;
  final String findOllama;
  final String searchingOllama;
  final String ollamaNotFound;
  final String manageModels;
  final String manageModelsTitle;
  final String installedModels;
  final String availableModels;
  final String noInstalledModels;
  final String install;
  final String installing;
  final String installFailed;
  final String removeModel;
  final String removeModelConfirm;
  final String cancel;
  final String cancelDownload;
  final String done;
  final String tryAgain;
  final String startingDownload;
  final String downloadKeepOpen;
  final String downloadReadyBody;
  final String customModelHint;
  final String downloadingModels;
  final String modelsEmptyTitle;
  final String modelsEmptyMessage;
  final String modelsEmptyAction;
  final String modelsUnsupportedTitle;
  final String modelsOfflineTitle;
  final String modelsOfflineMessage;
  final String modelsLoadFailed;
  final String retry;
  final String activeBadge;
  final String useModel;
  final String oneDownloadAtATime;
  final String oneDownloadAtATimeBody;
  final String finishingUp;
  final String downloadLeaveBody;
  final String assistantTitle;
  final String providerRow;
  final String routingRow;
  final String modelsRow;
  final String cloudNote;
  final String apply;

  String modelsInstalled(int n) => '$n installed';

  String downloadingTitle(String model) => 'Downloading $model';

  String downloadReadyTitle(String model) => '$model is ready';

  String timeLeft(String duration) => 'About $duration left';

  String modelsUsing(String size) => 'Using $size';

  String modelOptions(String model) => 'Options for $model';

  String modelDownloadFailed(String size) => 'Download failed · $size';

  String modelDownloadAction(String model, String size) =>
      'Download $model, $size';

  String modelRetryAction(String model) => 'Retry downloading $model';

  String removeModelTitle(String model) => 'Remove $model?';

  /// What the remove dialog says; [freed] is the size it gives back, null
  /// when the catalogue does not know it. [active] is the model in use.
  String removeModelMessage(
    String model, {
    String? freed,
    bool active = false,
  }) => '${freed == null ? '' : 'Frees $freed. '}$removeModelConfirm';

  String downloadProgressOf(String done, String total) => '$done of $total';

  String downloadFailedTitle(String model) => "Couldn't download $model";

  String downloadFailedBody(String total) =>
      'Check your connection and that there is room for $total, then try '
      'again.';

  String downloadStoppedTitle(int percent) => 'Download stopped at $percent%';

  String downloadNoSpaceBody(String total) =>
      'The device ran out of space. Free up room for $total, then try again.';

  String get downloadOfflineBody =>
      "You're offline. Connect to the internet, then try again.";

  String downloadReadyBodyFor(String total) => '$downloadReadyBody $total';

  String titleFor(AiBackendKind kind) => switch (kind) {
    AiBackendKind.cloudGemini => cloudGeminiTitle,
    AiBackendKind.ollama => ollamaTitle,
    AiBackendKind.systemOnDevice => onDeviceTitle,
    AiBackendKind.edgeGalleryDelegate => edgeGalleryTitle,
    AiBackendKind.localLlm => localLlmTitle,
    AiBackendKind.openAiCompatible => openAiCompatibleTitle,
  };

  String descriptionFor(AiBackendKind kind) => switch (kind) {
    AiBackendKind.cloudGemini => cloudGeminiDescription,
    AiBackendKind.ollama => ollamaDescription,
    AiBackendKind.systemOnDevice => onDeviceDescription,
    AiBackendKind.edgeGalleryDelegate => edgeGalleryDescription,
    AiBackendKind.localLlm => localLlmDescription,
    AiBackendKind.openAiCompatible => openAiCompatibleDescription,
  };

  /// One glyph per provider, so a row reads at a glance before the label
  /// does — cloud vs. this device vs. a separate app.
  IconData iconFor(AiBackendKind kind) => switch (kind) {
    AiBackendKind.cloudGemini => Icons.cloud_outlined,
    AiBackendKind.ollama => Icons.dns_outlined,
    AiBackendKind.systemOnDevice => Icons.phone_iphone_outlined,
    AiBackendKind.edgeGalleryDelegate => Icons.open_in_new_rounded,
    AiBackendKind.localLlm => Icons.memory_outlined,
    AiBackendKind.openAiCompatible => Icons.api_outlined,
  };

  /// One-line description for a routing [mode], next to its control.
  String routingDescriptionFor(AiRoutingMode mode) => switch (mode) {
    AiRoutingMode.serverFirst => routingServerFirstDescription,
    AiRoutingMode.localOnly => routingLocalOnlyDescription,
    AiRoutingMode.serverOnly => routingServerOnlyDescription,
  };

  String routingLabelFor(AiRoutingMode mode) => switch (mode) {
    AiRoutingMode.serverFirst => routingServerFirst,
    AiRoutingMode.localOnly => routingLocalOnly,
    AiRoutingMode.serverOnly => routingServerOnly,
  };
}
