import 'package:flutter/foundation.dart';

/// Supported AI inference backends.
enum AiBackendKind {
  /// Portal cloud pipeline (e.g. server-side Gemini).
  cloudGemini,

  /// Local [Ollama](https://ollama.com) daemon.
  ollama,

  /// The device's own built-in model, reached through the platform channel
  /// (Android: ML Kit GenAI / AICore, i.e. Gemini Nano).
  systemOnDevice,

  /// Opens Google AI Edge Gallery when installed (delegation, not in-app).
  edgeGalleryDelegate,
}

extension AiBackendKindIds on AiBackendKind {
  String get id => switch (this) {
        AiBackendKind.cloudGemini => 'cloud_gemini',
        AiBackendKind.ollama => 'ollama',
        AiBackendKind.systemOnDevice => 'system_on_device',
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

/// Where to look for Ollama when the user has not set a host.
///
/// On Android `127.0.0.1` is the phone itself, so the desktop default can
/// never find a daemon. `10.0.2.2` is the emulator's alias for the host
/// machine; on a physical device the user still has to enter their LAN
/// address in AI settings, but the emulator then works out of the box.
const kAndroidEmulatorOllamaBaseUrl = 'http://10.0.2.2:11434';

String get defaultOllamaBaseUrl {
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    return kAndroidEmulatorOllamaBaseUrl;
  }
  return kDefaultOllamaBaseUrl;
}
