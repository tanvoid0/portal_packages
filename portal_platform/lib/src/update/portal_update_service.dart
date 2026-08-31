import 'dart:convert';
import 'dart:io';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_client.dart';
import '../widgets/portal_app_version.dart';
import 'portal_release.dart';

/// Why an update check produced no update. Surfaced so the UI can say
/// "you're up to date" and "couldn't reach the server" differently.
enum PortalUpdateStatus { upToDate, updateAvailable, unsupported, failed }

class PortalUpdateCheck {
  const PortalUpdateCheck(this.status, {this.release, this.message});

  final PortalUpdateStatus status;
  final PortalRelease? release;

  /// Human-readable reason when [status] is [PortalUpdateStatus.failed].
  final String? message;

  bool get hasUpdate => release != null;
}

/// Checks for, downloads and hands off sideloaded APK updates.
///
/// Portal ships outside the Play Store while the apps are finished, so there
/// is no store to notice a new build. A published `updates.json` is the whole
/// mechanism: fetch it, compare `versionCode`, download the APK, hand it to
/// the system installer.
///
/// **The trust anchor is the signing key, not this code.** Android refuses to
/// replace an installed app with an APK signed by a different certificate, so
/// a swapped download cannot become an update to a Portal app — at worst it
/// fails to install. The SHA-256 check here is for integrity: it catches a
/// truncated or corrupted download and reports that plainly, instead of
/// letting Android show its opaque "App not installed".
class PortalUpdateService {
  PortalUpdateService({
    required this.manifestUrl,
    required this.appName,
    http.Client? client,
  }) : _client = client ?? http.Client();

  /// Absolute URL of `updates.json`. Empty disables update checks entirely.
  final String manifestUrl;

  /// [AppConfig.appTitle] — slugified to look this app up in the manifest.
  final String appName;

  final http.Client _client;

  static const Duration _manifestTimeout = Duration(seconds: 15);

  /// True when this build was configured with a manifest URL.
  bool get isEnabled => manifestUrl.trim().isNotEmpty;

  /// Fetches the manifest and compares it with the running build.
  ///
  /// Never throws: a failed update check must not break a launch.
  Future<PortalUpdateCheck> check() async {
    if (!isEnabled) {
      return const PortalUpdateCheck(PortalUpdateStatus.unsupported);
    }
    if (!Platform.isAndroid) {
      // iOS has no sideload path; there is nothing this could do with an APK.
      return const PortalUpdateCheck(PortalUpdateStatus.unsupported);
    }

    try {
      final info = await PortalAppVersion.load();
      final current = parseVersionCode(info.buildNumber);
      if (current == null) {
        return const PortalUpdateCheck(
          PortalUpdateStatus.failed,
          message: 'Could not read this build\'s version.',
        );
      }

      final response = await _client
          .get(Uri.parse(manifestUrl.trim()))
          .timeout(_manifestTimeout);
      if (response.statusCode != 200) {
        return PortalUpdateCheck(
          PortalUpdateStatus.failed,
          message: 'Update server returned ${response.statusCode}.',
        );
      }

      final manifest =
          PortalUpdateManifest.fromJson(jsonDecode(response.body) as Object?);
      if (manifest == null) {
        return const PortalUpdateCheck(
          PortalUpdateStatus.failed,
          message: 'Update manifest is not readable by this build.',
        );
      }

      final slug = ApiClient.slugifyAppName(appName);
      final release = manifest.updateFor(slug, current);
      return release == null
          ? const PortalUpdateCheck(PortalUpdateStatus.upToDate)
          : PortalUpdateCheck(
              PortalUpdateStatus.updateAvailable,
              release: release,
            );
    } catch (e) {
      return PortalUpdateCheck(
        PortalUpdateStatus.failed,
        message: 'Could not check for updates: $e',
      );
    }
  }

  /// Downloads [release] to a temporary file, verifying its SHA-256.
  ///
  /// [onProgress] receives 0.0–1.0, or -1 while the total size is unknown.
  /// Throws [PortalUpdateException] on a bad transfer.
  Future<File> download(
    PortalRelease release, {
    void Function(double progress)? onProgress,
  }) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/${release.slug}-${release.versionCode}.apk');
    // A previous half-finished attempt would otherwise be appended to and
    // then fail its hash for a reason nobody could diagnose.
    if (await file.exists()) await file.delete();

    final request = http.Request('GET', release.apkUrl);
    final response = await _client.send(request);
    if (response.statusCode != 200) {
      throw PortalUpdateException(
        'Download failed with HTTP ${response.statusCode}.',
      );
    }

    final expectedBytes = response.contentLength ?? release.sizeBytes;
    // Hashed chunk by chunk as it arrives, so a 100 MB APK never has to be
    // held in memory to be verified.
    final hashSink = Sha256().newHashSink();
    final out = file.openWrite();
    var received = 0;

    try {
      await for (final chunk in response.stream) {
        out.add(chunk);
        hashSink.add(chunk);
        received += chunk.length;
        onProgress?.call(expectedBytes > 0 ? received / expectedBytes : -1);
      }
      await out.flush();
    } finally {
      await out.close();
    }

    hashSink.close();
    final digest = await hashSink.hash();
    final actual = _hex(digest.bytes);

    if (release.sha256.isNotEmpty && actual != release.sha256) {
      await file.delete();
      throw PortalUpdateException(
        'The download did not match its checksum and was discarded.',
      );
    }
    if (release.sha256.isEmpty) {
      debugPrint(
        'PortalUpdateService: ${release.slug} has no sha256 in the manifest; '
        'download integrity was not verified.',
      );
    }
    return file;
  }

  /// Hands [apk] to the system package installer.
  ///
  /// Android shows its own confirmation, and the first time will send the user
  /// to "Install unknown apps" for this app. Nothing installs silently.
  Future<void> install(File apk) async {
    final result = await OpenFilex.open(
      apk.path,
      type: 'application/vnd.android.package-archive',
    );
    if (result.type != ResultType.done) {
      throw PortalUpdateException(
        'Could not open the installer: ${result.message}. '
        'Allow this app to install unknown apps in Android settings, then '
        'try again.',
      );
    }
  }

  /// Version the user said "Not now" to, so the launch check stays quiet.
  ///
  /// Stored per app (each app is its own package, so its own preferences) and
  /// as a single int rather than a set: only the newest offer matters, and a
  /// newer publish supersedes the refusal automatically.
  static const String _dismissedKey = 'portal_update_dismissed_version_code';

  Future<void> markDismissed(int versionCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_dismissedKey, versionCode);
  }

  Future<bool> wasDismissed(int versionCode) async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getInt(_dismissedKey) ?? -1) >= versionCode;
  }

  static String _hex(List<int> bytes) =>
      bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

  void dispose() => _client.close();
}

class PortalUpdateException implements Exception {
  const PortalUpdateException(this.message);
  final String message;
  @override
  String toString() => message;
}
