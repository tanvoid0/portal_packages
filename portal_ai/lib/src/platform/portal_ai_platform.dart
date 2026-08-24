import 'package:flutter/services.dart';

import '../models/ai_backend_kind.dart';

/// Native helpers for package detection (Android).
abstract final class PortalAiPlatform {
  static const _channel = MethodChannel('portal_ai/platform');

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
}
