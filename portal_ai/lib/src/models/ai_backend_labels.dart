import 'package:flutter/material.dart';

import 'ai_backend_kind.dart';

/// User-visible labels for [AiBackendOption] rows.
class AiBackendLabels {
  const AiBackendLabels({
    this.cloudGeminiTitle = 'Portal Cloud (Gemini)',
    this.cloudGeminiDescription =
        'Uses Structured Cloud. Requires sign-in and AI terms.',
    this.ollamaTitle = 'Ollama (local)',
    this.ollamaDescription =
        'Runs on this device via Ollama. Private and offline-capable.',
    this.onDeviceTitle = 'On-device model',
    this.onDeviceDescription =
        'Runs on this phone using its built-in model. Private and offline.',
    this.edgeGalleryTitle = 'Google AI Edge Gallery',
    this.edgeGalleryDescription =
        'Opens the Edge Gallery app for on-device chat (external).',
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
    this.ollamaNotFound =
        'No Ollama found on this network. Check it is running and reachable, '
        'then enter its address above.',
  });

  final String cloudGeminiTitle;
  final String cloudGeminiDescription;
  final String ollamaTitle;
  final String ollamaDescription;
  final String onDeviceTitle;
  final String onDeviceDescription;
  final String edgeGalleryTitle;
  final String edgeGalleryDescription;
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

  String titleFor(AiBackendKind kind) => switch (kind) {
    AiBackendKind.cloudGemini => cloudGeminiTitle,
    AiBackendKind.ollama => ollamaTitle,
    AiBackendKind.systemOnDevice => onDeviceTitle,
    AiBackendKind.edgeGalleryDelegate => edgeGalleryTitle,
  };

  String descriptionFor(AiBackendKind kind) => switch (kind) {
    AiBackendKind.cloudGemini => cloudGeminiDescription,
    AiBackendKind.ollama => ollamaDescription,
    AiBackendKind.systemOnDevice => onDeviceDescription,
    AiBackendKind.edgeGalleryDelegate => edgeGalleryDescription,
  };

  /// One glyph per provider, so a row reads at a glance before the label
  /// does — cloud vs. this device vs. a separate app.
  IconData iconFor(AiBackendKind kind) => switch (kind) {
    AiBackendKind.cloudGemini => Icons.cloud_outlined,
    AiBackendKind.ollama => Icons.dns_outlined,
    AiBackendKind.systemOnDevice => Icons.phone_iphone_outlined,
    AiBackendKind.edgeGalleryDelegate => Icons.open_in_new_rounded,
  };
}
