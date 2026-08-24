import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/ai_backend_kind.dart';

/// Probes a running Ollama daemon.
class OllamaProbe {
  OllamaProbe({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<OllamaProbeResult> probe({
    String baseUrl = kDefaultOllamaBaseUrl,
    Duration timeout = const Duration(seconds: 2),
  }) async {
    final normalized = _normalizeBaseUrl(baseUrl);
    try {
      final root = await _client
          .get(Uri.parse(normalized))
          .timeout(timeout);
      if (root.statusCode != 200) {
        return OllamaProbeResult.unavailable(
          host: normalized,
          reason: 'Ollama responded with HTTP ${root.statusCode}',
        );
      }

      final tagsResponse = await _client
          .get(Uri.parse('$normalized/api/tags'))
          .timeout(timeout);
      if (tagsResponse.statusCode != 200) {
        return OllamaProbeResult.available(
          host: normalized,
          models: const [],
        );
      }

      final body = jsonDecode(tagsResponse.body) as Map<String, dynamic>;
      final models = _parseModels(body);
      return OllamaProbeResult.available(host: normalized, models: models);
    } catch (e) {
      return OllamaProbeResult.unavailable(
        host: normalized,
        reason: 'Ollama is not running at $normalized',
      );
    }
  }

  static String _normalizeBaseUrl(String baseUrl) {
    var url = baseUrl.trim();
    if (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    return url;
  }

  static List<String> _parseModels(Map<String, dynamic> body) {
    final raw = body['models'];
    if (raw is! List) return const [];
    return raw
        .map((entry) {
          if (entry is Map) {
            return entry['name'] as String? ?? entry['model'] as String?;
          }
          return null;
        })
        .whereType<String>()
        .where((name) => name.isNotEmpty)
        .toList();
  }
}

class OllamaProbeResult {
  const OllamaProbeResult._({
    required this.host,
    required this.isAvailable,
    this.models = const [],
    this.reason,
  });

  factory OllamaProbeResult.available({
    required String host,
    required List<String> models,
  }) {
    return OllamaProbeResult._(
      host: host,
      isAvailable: true,
      models: models,
    );
  }

  factory OllamaProbeResult.unavailable({
    required String host,
    required String reason,
  }) {
    return OllamaProbeResult._(
      host: host,
      isAvailable: false,
      reason: reason,
    );
  }

  final String host;
  final bool isAvailable;
  final List<String> models;
  final String? reason;
}
