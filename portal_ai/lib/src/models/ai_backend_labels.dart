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
    this.customModelHint = 'Or type a model name',
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
  final String customModelHint;
  final String assistantTitle;
  final String providerRow;
  final String routingRow;
  final String modelsRow;
  final String cloudNote;
  final String apply;

  String modelsInstalled(int n) => '$n installed';

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
