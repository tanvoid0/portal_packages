import 'package:flutter/services.dart';

import '../models/ai_backend_kind.dart';

/// What the device's built-in model can do right now.
enum SystemAiStatus {
  /// Ready to generate.
  available,

  /// Supported, but the weights still have to be fetched.
  downloadable,

  /// Weights are being fetched.
  downloading,

  /// This device or OS build cannot run it.
  unavailable,
}

/// Reply to [PortalAiPlatform.describeSystemAi].
///
/// [models] is what the platform reports it will actually run — never a name
/// hardcoded here. Android answers with `getBaseModelName()`; a device that
/// ships a different base model reports that instead, with no app change.
class SystemAiDescription {
  const SystemAiDescription({
    required this.status,
    this.models = const [],
    this.reason,
  });

  const SystemAiDescription.unavailable(this.reason)
      : status = SystemAiStatus.unavailable,
        models = const [];

  final SystemAiStatus status;
  final List<String> models;
  final String? reason;

  bool get isAvailable => status == SystemAiStatus.available;

  /// Present on the device but needing a download before first use.
  bool get isDownloadable => status == SystemAiStatus.downloadable;

  factory SystemAiDescription.fromMap(Map<Object?, Object?> map) {
    final raw = (map['status'] as String?)?.trim().toLowerCase();
    final status = switch (raw) {
      'available' => SystemAiStatus.available,
      'downloadable' => SystemAiStatus.downloadable,
      'downloading' => SystemAiStatus.downloading,
      _ => SystemAiStatus.unavailable,
    };
    final models = (map['models'] as List?)
            ?.whereType<String>()
            .where((m) => m.trim().isNotEmpty)
            .toList() ??
        const <String>[];
    return SystemAiDescription(
      status: status,
      models: models,
      reason: (map['reason'] as String?)?.trim(),
    );
  }
}

/// Native helpers: package detection and the device's built-in model.
abstract final class PortalAiPlatform {
  static const _channel = MethodChannel('portal_ai/platform');
  static const _generateStream = EventChannel('portal_ai/generate_stream');

  static Future<bool> isPackageInstalled(String packageName) async {
    try {
      final result = await _channel.invokeMethod<bool>(
        'isPackageInstalled',
        packageName,
      );
      return result ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  static Future<bool> isEdgeGalleryInstalled() =>
      isPackageInstalled(kEdgeGalleryPackageName);

  /// Asks the platform what its built-in model can do, and what it is called.
  static Future<SystemAiDescription> describeSystemAi() async {
    try {
      final result =
          await _channel.invokeMapMethod<Object?, Object?>('describeSystemAi');
      if (result == null) {
        return const SystemAiDescription.unavailable(
          'The platform reported no on-device model',
        );
      }
      return SystemAiDescription.fromMap(result);
    } on MissingPluginException {
      return const SystemAiDescription.unavailable(
        'On-device AI is not supported on this platform',
      );
    } on PlatformException catch (e) {
      return SystemAiDescription.unavailable(e.message ?? 'On-device AI failed');
    }
  }

  /// Fetches the weights. Completes when the download finishes or fails; the
  /// caller re-runs [describeSystemAi] to see the new status.
  static Future<bool> downloadSystemAi() async {
    try {
      final result = await _channel.invokeMethod<bool>('downloadSystemAi');
      return result ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  static Future<String> generate({
    required String prompt,
    double? temperature,
    int? topK,
  }) async {
    final result = await _channel.invokeMethod<String>('generate', {
      'prompt': prompt,
      'temperature': ?temperature,
      'topK': ?topK,
    });
    return result ?? '';
  }

  static Stream<String> generateStream({
    required String prompt,
    double? temperature,
    int? topK,
  }) {
    return _generateStream
        .receiveBroadcastStream({
          'prompt': prompt,
          'temperature': ?temperature,
          'topK': ?topK,
        })
        .map((event) => event as String? ?? '')
        .where((chunk) => chunk.isNotEmpty);
  }
}
