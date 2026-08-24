import 'dart:io';

import 'package:flutter/services.dart';

import '../models/ai_backend_kind.dart';

/// Opens the installed Google AI Edge Gallery app.
abstract final class EdgeGalleryLauncher {
  static const _channel = MethodChannel('portal_ai/platform');

  static Future<bool> launch() async {
    if (!Platform.isAndroid) {
      return false;
    }
    try {
      final result = await _channel.invokeMethod<bool>(
        'launchPackage',
        kEdgeGalleryPackageName,
      );
      return result ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }
}
