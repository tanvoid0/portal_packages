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
        'Runs LiteRT-LM inside the app. Same engine as Google AI Edge Gallery.',
    this.edgeGalleryTitle = 'Google AI Edge Gallery',
    this.edgeGalleryDescription =
        'Opens the Edge Gallery app for on-device chat (external).',
    this.unavailable = 'Unavailable',
    this.scanning = 'Checking available providers…',
    this.noProviders = 'No AI providers are available on this device.',
    this.selectProvider = 'AI provider',
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
  final String scanning;
  final String noProviders;
  final String selectProvider;

  String titleFor(AiBackendKind kind) => switch (kind) {
        AiBackendKind.cloudGemini => cloudGeminiTitle,
        AiBackendKind.ollama => ollamaTitle,
        AiBackendKind.onDeviceLiteRt => onDeviceTitle,
        AiBackendKind.edgeGalleryDelegate => edgeGalleryTitle,
      };

  String descriptionFor(AiBackendKind kind) => switch (kind) {
        AiBackendKind.cloudGemini => cloudGeminiDescription,
        AiBackendKind.ollama => ollamaDescription,
        AiBackendKind.onDeviceLiteRt => onDeviceDescription,
        AiBackendKind.edgeGalleryDelegate => edgeGalleryDescription,
      };
}
