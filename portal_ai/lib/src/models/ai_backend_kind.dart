/// Supported AI inference backends.
enum AiBackendKind {
  /// Portal cloud pipeline (e.g. server-side Gemini).
  cloudGemini,

  /// Local [Ollama](https://ollama.com) daemon.
  ollama,

  /// On-device LiteRT-LM (same stack as Google AI Edge Gallery).
  onDeviceLiteRt,

  /// Opens Google AI Edge Gallery when installed (delegation, not in-app).
  edgeGalleryDelegate,
}

extension AiBackendKindIds on AiBackendKind {
  String get id => switch (this) {
        AiBackendKind.cloudGemini => 'cloud_gemini',
        AiBackendKind.ollama => 'ollama',
        AiBackendKind.onDeviceLiteRt => 'on_device_litert',
        AiBackendKind.edgeGalleryDelegate => 'edge_gallery',
      };

  static AiBackendKind? fromId(String? id) {
    if (id == null || id.isEmpty) return null;
    for (final kind in AiBackendKind.values) {
      if (kind.id == id) return kind;
    }
    return null;
  }
}

/// Play Store package id for Google AI Edge Gallery.
const kEdgeGalleryPackageName = 'com.google.ai.edge.gallery';

/// Default Ollama HTTP base URL on desktop.
const kDefaultOllamaBaseUrl = 'http://127.0.0.1:11434';
