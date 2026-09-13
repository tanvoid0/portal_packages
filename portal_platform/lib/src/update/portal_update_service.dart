import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/api_client.dart';
import '../widgets/portal_app_version.dart';
import 'portal_release.dart';

/// Why an update check produced no update. Surfaced so the UI can say
/// "you're up to date" and "couldn't reach the server" differently.
enum PortalUpdateStatus { upToDate, updateAvailable, unsupported, failed }

class PortalUpdateCheck {
  const PortalUpdateCheck(
    this.status, {
    this.release,
    this.latest,
    this.checkedAt,
    this.message,
  });

  final PortalUpdateStatus status;

  /// Set only when [status] is [PortalUpdateStatus.updateAvailable].
  final PortalRelease? release;

  /// What the manifest publishes for this app, newer than the running build
  /// or not. A version panel shows it either way; [release] answers the
  /// narrower "is there something to install".
  final PortalRelease? latest;

  /// When this check read the manifest. Null when it never got that far.
  final DateTime? checkedAt;

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

  /// True when this build was configured with a usable manifest URL.
  ///
  /// https only. The manifest decides which bytes get handed to the package
  /// installer, so fetching it over plain http would let anyone on the network
  /// choose them — and `UPDATE_MANIFEST_URL` is a config string that is easy
  /// to paste in without a scheme.
  bool get isEnabled {
    final uri = Uri.tryParse(manifestUrl.trim());
    return uri != null && uri.scheme == 'https' && uri.host.isNotEmpty;
  }

  /// This app's manifest key — `Portal Gym` becomes `portal-gym`.
  String get slug => ApiClient.slugifyAppName(appName);

  /// Fetches and validates `updates.json`.
  ///
  /// Throws [PortalUpdateException] rather than returning a status, because
  /// both callers — the update check and the app list — want to say something
  /// different about a failure. [check] swallows it; the list shows it.
  Future<PortalUpdateManifest> fetchManifest() async {
    if (!isEnabled) {
      throw const PortalUpdateException(
        'UPDATE_MANIFEST_URL is not set to an https:// URL in this build.',
      );
    }
    final manifestUri = Uri.parse(manifestUrl.trim());
    final response = await _client.get(manifestUri).timeout(_manifestTimeout);
    if (response.statusCode != 200) {
      throw PortalUpdateException(
        'Update server returned ${response.statusCode}.',
      );
    }
    final manifest = PortalUpdateManifest.fromJson(
      jsonDecode(response.body) as Object?,
      requiredHost: manifestUri.host,
    );
    if (manifest == null) {
      throw const PortalUpdateException(
        'Update manifest is not readable by this build.',
      );
    }
    return manifest;
  }

  /// Fetches the manifest and compares it with the running build.
  ///
  /// Never throws: a failed update check must not break a launch.
  Future<PortalUpdateCheck> check() async {
    if (manifestUrl.trim().isNotEmpty && !isEnabled) {
      // Configured, but not with something safe to fetch. Say so rather than
      // reporting "updates unavailable", which reads as intentional.
      return const PortalUpdateCheck(
        PortalUpdateStatus.failed,
        message: 'UPDATE_MANIFEST_URL must be an https:// URL.',
      );
    }
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

      final manifest = await fetchManifest();
      final checkedAt = await _recordChecked();
      final latest = manifest.latestFor(slug);
      final release = manifest.updateFor(slug, current);
      return PortalUpdateCheck(
        release == null
            ? PortalUpdateStatus.upToDate
            : PortalUpdateStatus.updateAvailable,
        release: release,
        latest: latest,
        checkedAt: checkedAt,
      );
    } catch (e) {
      return PortalUpdateCheck(
        PortalUpdateStatus.failed,
        message: 'Could not check for updates: $e',
      );
    }
  }

  /// Hands [release] to the browser, which downloads the APK and, once the
  /// user taps the finished download, opens Android's install sheet.
  ///
  /// The app used to download and install the APK itself through the
  /// PackageInstaller session API. That needs REQUEST_INSTALL_PACKAGES, and
  /// on 2026-09-13 Play Protect began rejecting every sideloaded Portal build
  /// that held it -- "this app can install potentially harmful apps" -- with
  /// no way to allow it. Without the permission no in-app route works, so
  /// the browser (which has it) does the installing. The in-app SHA-256 check
  /// went with the download; the release host is https and the manifest
  /// still carries the digest for anyone who wants to check by hand.
  Future<void> install(PortalRelease release) async {
    final opened = await launchUrl(
      release.apkUrl,
      mode: LaunchMode.externalApplication,
    );
    if (!opened) {
      throw const PortalUpdateException('No browser could open the download.');
    }
  }

  /// Version the user said "Not now" to, so the launch check stays quiet.
  ///
  /// Stored per app (each app is its own package, so its own preferences) and
  /// as a single int rather than a set: only the newest offer matters, and a
  /// newer publish supersedes the refusal automatically.
  static const String _dismissedKey = 'portal_update_dismissed_version_code';

  /// When the manifest was last read successfully, so the version panel can
  /// say how fresh what it is showing is. Only a completed read counts — a
  /// failed one checked nothing.
  static const String _lastCheckedKey = 'portal_update_last_checked_ms';

  Future<DateTime> _recordChecked() async {
    final now = DateTime.now();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastCheckedKey, now.millisecondsSinceEpoch);
    return now;
  }

  /// The last successful check, across launches. Null when there has not been
  /// one on this install.
  Future<DateTime?> lastCheckedAt() async {
    final prefs = await SharedPreferences.getInstance();
    final ms = prefs.getInt(_lastCheckedKey);
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  Future<void> markDismissed(int versionCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_dismissedKey, versionCode);
  }

  Future<bool> wasDismissed(int versionCode) async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getInt(_dismissedKey) ?? -1) >= versionCode;
  }

  void dispose() => _client.close();
}

class PortalUpdateException implements Exception {
  const PortalUpdateException(this.message);
  final String message;
  @override
  String toString() => message;
}
