import 'package:flutter/foundation.dart';

import '../config/gemini_model_catalog.dart';
import '../models/ai_backend_kind.dart';
import '../models/ai_backend_option.dart';
import 'edge_gallery_probe.dart';
import 'ollama_probe.dart';
import 'system_ai_probe.dart';

/// Discovers AI backends available on the current platform.
class AiBackendDiscovery {
  AiBackendDiscovery({
    OllamaProbe? ollamaProbe,
    EdgeGalleryProbe? edgeGalleryProbe,
    SystemAiProbe? systemAiProbe,
    this._geminiCatalog,
  }) : _ollamaProbe = ollamaProbe ?? OllamaProbe(),
       _edgeGalleryProbe = edgeGalleryProbe ?? EdgeGalleryProbe(),
       _systemAiProbe = systemAiProbe ?? SystemAiProbe();

  final OllamaProbe _ollamaProbe;
  final EdgeGalleryProbe _edgeGalleryProbe;
  final SystemAiProbe _systemAiProbe;
  final GeminiModelCatalog? _geminiCatalog;

  Future<List<AiBackendOption>> discover({
    bool includeCloud = true,
    bool cloudEligible = true,
    String ollamaHost = kDefaultOllamaBaseUrl,
    bool includeEdgeGalleryDelegate = true,
  }) async {
    final options = <AiBackendOption>[];

    if (includeCloud) {
      options.add(_cloudOption(cloudEligible));
    }

    final ollamaResult = await _probeOllama(ollamaHost);
    options.add(
      AiBackendOption(
        kind: AiBackendKind.ollama,
        available: ollamaResult.isAvailable,
        unavailableReason: ollamaResult.isAvailable
            ? null
            : ollamaResult.reason,
        models: ollamaResult.models,
        metadata: {'host': ollamaResult.host},
      ),
    );

    final system = await _systemAiProbe.probe();
    options.add(
      AiBackendOption(
        kind: AiBackendKind.systemOnDevice,
        available: system.isAvailable,
        unavailableReason: system.isAvailable ? null : system.reason,
        models: system.models,
        metadata: {
          'status': system.status.name,
          // The settings UI offers a Download button off this, so a model the
          // device could run but has not fetched is one tap away rather than
          // a dead row.
          'downloadable': system.isDownloadable,
        },
      ),
    );

    if (includeEdgeGalleryDelegate) {
      final edgeResult = await _edgeGalleryProbe.probe();
      options.add(
        AiBackendOption(
          kind: AiBackendKind.edgeGalleryDelegate,
          available: edgeResult.isInstalled,
          unavailableReason: edgeResult.isInstalled ? null : edgeResult.reason,
          metadata: {'package': kEdgeGalleryPackageName},
        ),
      );
    }

    return _sortOptions(options);
  }

  AiBackendOption _cloudOption(bool cloudEligible) {
    final catalog = _geminiCatalog;
    final geminiModels = catalog?.availableModels ?? const [];
    final hasDirectGemini = catalog?.isConfigured ?? false;

    final available = cloudEligible || hasDirectGemini;
    String? reason;
    if (!available) {
      reason = 'Sign in, or set GEMINI_API_KEY and GEMINI_MODELS in .env';
    } else if (!cloudEligible && !hasDirectGemini) {
      reason = 'Sign in and accept AI terms to use Portal Cloud';
    }

    return AiBackendOption(
      kind: AiBackendKind.cloudGemini,
      available: available,
      unavailableReason: available ? null : reason,
      models: geminiModels,
      metadata: {
        'source': 'env',
        'directClient': hasDirectGemini,
        'cloudEligible': cloudEligible,
      },
    );
  }

  Future<OllamaProbeResult> _probeOllama(String host) async {
    if (_isLocalHost(host)) {
      if (kIsWeb) {
        return OllamaProbeResult.unavailable(
          host: host,
          reason:
              'Browser cannot reach Ollama on this machine; use Portal Cloud or a LAN URL',
        );
      }
      if (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS) {
        return OllamaProbeResult.unavailable(
          host: host,
          reason:
              'Not reachable from this device. Tap Find on my network, '
              "or enter your computer's address.",
        );
      }
    }
    return _ollamaProbe.probe(baseUrl: host);
  }

  static bool _isLocalHost(String host) {
    final normalized = host.toLowerCase();
    return normalized.contains('127.0.0.1') || normalized.contains('localhost');
  }

  static List<AiBackendOption> _sortOptions(List<AiBackendOption> options) {
    final sorted = List<AiBackendOption>.from(options);
    sorted.sort((a, b) {
      if (a.available != b.available) {
        return a.available ? -1 : 1;
      }
      return a.kind.index.compareTo(b.kind.index);
    });
    return sorted;
  }
}
