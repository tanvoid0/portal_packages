import 'dart:io';

import 'package:flutter/services.dart';

/// What a sibling Portal app's installed build is, when it is installed.
class PortalInstalledApp {
  const PortalInstalledApp({required this.versionCode, required this.versionName});

  final int versionCode;
  final String versionName;
}

/// The PackageManager questions the app list asks: what is installed, and
/// please uninstall this.
///
/// Android only, and only for the packages named in this package's own
/// `<queries>` block — anything else is indistinguishable from not installed.
/// Every call swallows its platform errors: a desktop build has no plugin
/// registered at all, and "cannot tell" and "not installed" lead to the same
/// offer.
class PortalInstalledApps {
  const PortalInstalledApps._();

  static const MethodChannel _channel = MethodChannel('portal_platform/packages');

  /// Apps whose applicationId is not the slug with dashes as underscores.
  ///
  /// `portal_launcher` predates the convention and is its own repo, so its
  /// Gradle `applicationId` has no separator at all. Renaming it would orphan
  /// every installed copy, so the exception lives here instead.
  static const _packageOverrides = <String, String>{
    'portal-launcher': 'com.tanvoid0.portallauncher',
  };

  /// `portal-gym` -> `com.tanvoid0.portal_gym`.
  ///
  /// Convention, not a manifest field: every Portal app's applicationId is the
  /// slug with dashes as underscores, except the ones in [_packageOverrides].
  /// A future app that breaks that has to say so here and in the `<queries>`
  /// block, which is the same edit either way.
  static String packageNameFor(String slug) {
    final key = slug.trim().toLowerCase();
    return _packageOverrides[key] ?? 'com.tanvoid0.${key.replaceAll('-', '_')}';
  }

  static Future<PortalInstalledApp?> version(String slug) async {
    if (!Platform.isAndroid) return null;
    try {
      final info = await _channel.invokeMapMethod<String, Object?>(
        'installedVersion',
        {'package': packageNameFor(slug)},
      );
      if (info == null) return null;
      final code = info['versionCode'];
      return PortalInstalledApp(
        versionCode: code is int ? code : int.tryParse('$code') ?? 0,
        versionName: (info['versionName'] as String?) ?? '',
      );
    } catch (_) {
      return null;
    }
  }

  /// Starts an installed sibling app by its launch activity, bypassing the
  /// `portal-x://` scheme. False means there was nothing to start.
  static Future<bool> launch(String slug) async {
    if (!Platform.isAndroid) return false;
    try {
      return await _channel.invokeMethod<bool>(
            'launch',
            {'package': packageNameFor(slug)},
          ) ??
          false;
    } catch (_) {
      return false;
    }
  }

  /// Opens Android's uninstall confirmation. True means it opened, not that
  /// the app is gone — the caller re-probes on resume to find that out.
  static Future<bool> uninstall(String slug) async {
    if (!Platform.isAndroid) return false;
    try {
      return await _channel.invokeMethod<bool>(
            'uninstall',
            {'package': packageNameFor(slug)},
          ) ??
          false;
    } catch (_) {
      return false;
    }
  }
}
