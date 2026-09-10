import 'dart:convert';
import 'dart:io';

import 'package:cryptography/cryptography.dart';
import 'package:http/http.dart' as http;
import 'package:android_package_installer/android_package_installer.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    final out = file.openWrite();
    var received = 0;

    try {
      await for (final chunk in response.stream) {
        out.add(chunk);
        received += chunk.length;
        onProgress?.call(expectedBytes > 0 ? received / expectedBytes : -1);
      }
      await out.flush();
    } finally {
      await out.close();
    }

    // Hashed by reading the file back, not by digesting the chunks on their
    // way past. Those are not the same check: a short or failed write leaves a
    // truncated APK on disk that a stream digest still calls valid, and the
    // installer then rejects it with nothing more useful than "App not
    // installed". Streamed off disk, so a large APK is never held in memory.
    final onDisk = await file.length();
    if (release.sizeBytes > 0 && onDisk != release.sizeBytes) {
      await file.delete();
      throw PortalUpdateException(
        'The download is $onDisk bytes but should be ${release.sizeBytes}. '
        'It was discarded.',
      );
    }

    final hashSink = Sha256().newHashSink();
    await for (final chunk in file.openRead()) {
      hashSink.add(chunk);
    }
    hashSink.close();
    final digest = await hashSink.hash();
    final actual = _hex(digest.bytes);

    // A release with no usable checksum never survives parsing, so this is a
    // real comparison every time rather than one that quietly skips itself.
    if (actual != release.sha256) {
      await file.delete();
      throw const PortalUpdateException(
        'The download did not match its checksum and was discarded.',
      );
    }
    return file;
  }

  /// Hands [apk] to Android's package installer and waits for its verdict.
  ///
  /// Android shows its own confirmation, and the first time will send the user
  /// to "Install unknown apps" for this app. Nothing installs silently.
  ///
  /// Goes through the PackageInstaller *session* API. An `ACTION_VIEW` intent
  /// with the apk mime type is the older, more obvious route, and on current
  /// Android it opens the installer and then fails the commit with nothing but
  /// "App not installed" — which is indistinguishable from a corrupt download.
  ///
  /// The status arrives on the host activity's `onNewIntent`, so each app's
  /// launcher activity must declare the plugin's intent filter (see the app
  /// manifests). Without it this call never completes.
  Future<void> install(File apk) async {
    final code = await AndroidPackageInstaller.installApk(apkFilePath: apk.path);
    if (code == null) {
      throw const PortalUpdateException('The installer did not respond.');
    }
    final status = PackageInstallerStatus.byCode(code);
    if (status == PackageInstallerStatus.success) return;

    throw PortalUpdateException(switch (status) {
      PackageInstallerStatus.failureAborted =>
        'Installation was cancelled.',
      PackageInstallerStatus.failureBlocked =>
        'Android blocked the install. Check Play Protect and that this app is '
            'allowed to install unknown apps.',
      PackageInstallerStatus.failureConflict =>
        'A conflicting copy of this app is already installed. Uninstall it, '
            'then try again.',
      PackageInstallerStatus.failureIncompatible =>
        'That build is not compatible with this device.',
      PackageInstallerStatus.failureStorage =>
        'Not enough storage to install the update.',
      PackageInstallerStatus.failureInvalid =>
        'The downloaded package was rejected as invalid.',
      _ => 'The install did not complete (${status.name}).',
    });
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
