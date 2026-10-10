import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/ai_model_manager.dart';

/// Pulls, lists and deletes models on an Ollama daemon.
///
/// The daemon does the downloading; this only drives `/api/pull` and reports
/// what it streams back.
class OllamaModelManager implements AiModelManager {
  OllamaModelManager({required String baseUrl, http.Client? client})
    : baseUrl = _normalize(baseUrl),
      _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;

  /// Small instruct models that fit a laptop, as a starting point.
  ///
  /// Ollama's registry has no list endpoint, so this cannot be discovered --
  /// it is a hint, not a limit. Anything else is pulled by typing its tag.
  static const suggestions = <AiModelDownload>[
    AiModelDownload(
      id: 'qwen3:1.7b',
      label: 'Qwen 3 1.7B',
      sizeBytes: 1400 * 1024 * 1024,
      note: 'Fast, general purpose. Apache 2.0.',
    ),
    AiModelDownload(
      id: 'llama3.2:3b',
      label: 'Llama 3.2 3B',
      sizeBytes: 2000 * 1024 * 1024,
      note: 'Stronger reasoning, slower. Llama licence.',
    ),
    AiModelDownload(
      id: 'gemma3:4b',
      label: 'Gemma 3 4B',
      sizeBytes: 3300 * 1024 * 1024,
      note: 'Vision capable. Gemma licence.',
    ),
    AiModelDownload(
      id: 'qwen2.5-coder:1.5b',
      label: 'Qwen 2.5 Coder 1.5B',
      sizeBytes: 1000 * 1024 * 1024,
      note: 'Code completion and review.',
    ),
  ];

  @override
  Future<List<String>> installed() async {
    final response = await _client.get(Uri.parse('$baseUrl/api/tags'));
    if (response.statusCode != 200) {
      throw AiModelManagerException(
        'Ollama responded with HTTP ${response.statusCode}',
      );
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final models = body['models'];
    if (models is! List) return const [];
    return [
      for (final entry in models)
        if (entry is Map && entry['name'] is String) entry['name'] as String,
    ];
  }

  @override
  Future<List<AiModelDownload>> catalog() async {
    final have = (await installed()).toSet();
    return [
      for (final model in suggestions)
        if (!have.contains(model.id)) model,
    ];
  }

  /// `/api/pull` streams one JSON object per line. Layers are reported one at
  /// a time, so the fraction restarts per layer rather than running 0..1 once
  /// across the whole pull -- the bar moves, but it is not a total.
  @override
  Stream<double> install(String id) async* {
    final request = http.Request('POST', Uri.parse('$baseUrl/api/pull'))
      ..headers['Content-Type'] = 'application/json'
      ..body = jsonEncode({'model': id, 'stream': true});

    final response = await _client.send(request);
    if (response.statusCode != 200) {
      throw AiModelManagerException(
        _reason(
          await response.stream.bytesToString(),
          'Ollama refused to pull $id (HTTP ${response.statusCode})',
        ),
      );
    }

    final lines = response.stream
        .transform(utf8.decoder)
        .transform(const LineSplitter());

    await for (final line in lines) {
      if (line.trim().isEmpty) continue;
      final Map<String, dynamic> event;
      try {
        event = jsonDecode(line) as Map<String, dynamic>;
      } catch (_) {
        continue;
      }
      final error = event['error'];
      if (error is String && error.isNotEmpty) {
        throw AiModelManagerException(error);
      }
      final completed = event['completed'];
      final total = event['total'];
      if (completed is num && total is num && total > 0) {
        yield (completed / total).clamp(0.0, 1.0);
      }
    }
  }

  @override
  Future<void> remove(String id) async {
    final response = await _client.delete(
      Uri.parse('$baseUrl/api/delete'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'model': id}),
    );
    if (response.statusCode != 200) {
      throw AiModelManagerException(
        _reason(
          response.body,
          'Could not delete $id (HTTP ${response.statusCode})',
        ),
      );
    }
  }

  /// Ollama explains itself in an `error` field -- "model 'x' not found" beats
  /// "HTTP 404" on a sheet the user is reading.
  static String _reason(String body, String fallback) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map && decoded['error'] is String) {
        return decoded['error'] as String;
      }
    } catch (_) {}
    return fallback;
  }

  static String _normalize(String baseUrl) {
    var url = baseUrl.trim();
    while (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    return url;
  }
}
