import 'package:flutter/foundation.dart';

import '../config/gemini_model_catalog.dart';
import '../models/ai_backend_kind.dart';
import '../models/ai_backend_option.dart';
import 'edge_gallery_probe.dart';
import 'litert_probe.dart';
import 'ollama_probe.dart';

/// Discovers AI backends available on the current platform.
class AiBackendDiscovery {
  AiBackendDiscovery({
    OllamaProbe? ollamaProbe,
    EdgeGalleryProbe? edgeGalleryProbe,
    LiteRtProbe? liteRtProbe,
    GeminiModelCatalog? geminiCatalog,
    List<String> onDeviceModels = const [],
  })  : _ollamaProbe = ollamaProbe ?? OllamaProbe(),
        _edgeGalleryProbe = edgeGalleryProbe ?? EdgeGalleryProbe(),
        _liteRtProbe = liteRtProbe ?? LiteRtProbe(),
        _geminiCatalog = geminiCatalog,
        _onDeviceModels = onDeviceModels;

  final OllamaProbe _ollamaProbe;
  final EdgeGalleryProbe _edgeGalleryProbe;
  final LiteRtProbe _liteRtProbe;
  final GeminiModelCatalog? _geminiCatalog;
  final List<String> _onDeviceModels;

  Future<List<AiBackendOption>> discover({
    bool includeCloud = true,
    bool cloudEligible = true,
    String ollamaHost = kDefaultOllamaBaseUrl,
    String? onDeviceModelPath,
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
        unavailableReason: ollamaResult.isAvailable ? null : ollamaResult.reason,
        models: ollamaResult.models,
        metadata: {'host': ollamaResult.host},
      ),
    );

    final liteRtResult = await _liteRtProbe.probe(modelPath: onDeviceModelPath);
    final onDeviceModels = _onDeviceModels;
    options.add(
      AiBackendOption(
        kind: AiBackendKind.onDeviceLiteRt,
        available: liteRtResult.isAvailable,
        unavailableReason:
            liteRtResult.isAvailable ? null : liteRtResult.reason,
        models: liteRtResult.isAvailable ? onDeviceModels : onDeviceModels,
        metadata: {
          'capable': liteRtResult.isCapable,
          'configured': liteRtResult.isConfigured,
          if (onDeviceModelPath != null) 'modelPath': onDeviceModelPath,
        },
      ),
    );

    if (includeEdgeGalleryDelegate) {
      final edgeResult = await _edgeGalleryProbe.probe();
      options.add(
        AiBackendOption(
          kind: AiBackendKind.edgeGalleryDelegate,
          available: edgeResult.isInstalled,
          unavailableReason:
              edgeResult.isInstalled ? null : edgeResult.reason,
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
          reason: 'Enter a LAN Ollama host in advanced settings',
        );
      }
    }
    return _ollamaProbe.probe(baseUrl: host);
  }

  static bool _isLocalHost(String host) {
    final normalized = host.toLowerCase();
    return normalized.contains('127.0.0.1') ||
        normalized.contains('localhost');
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
