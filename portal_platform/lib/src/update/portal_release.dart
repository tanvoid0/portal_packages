/// Parsing and version comparison for the sideload update manifest.
///
/// Portal ships outside the Play Store for now, so nothing tells an installed
/// app that a newer build exists. A single `updates.json`, published alongside
/// the APKs, is that signal. This file is the pure half — no HTTP, no
/// filesystem — so the comparison rules can be tested directly.
library;

/// Manifest schema this client understands.
///
/// A future manifest that changes shape bumps this. An old client then sees a
/// number it does not recognise and reports "no update" rather than
/// misreading fields it half-understands and offering a bad download.
const int kPortalUpdateSchema = 1;

/// One app's published build, as named in the manifest.
class PortalRelease {
  const PortalRelease({
    required this.slug,
    required this.versionCode,
    required this.versionName,
    required this.apkUrl,
    required this.sha256,
    required this.sizeBytes,
    this.notes,
  });

  /// Matches the `X-Portal-App` slug — `Portal Gym` → `portal-gym`.
  final String slug;

  /// Android `versionCode`. The only field compared; `versionName` is display.
  final int versionCode;
  final String versionName;
  final Uri apkUrl;

  /// Lowercase hex SHA-256 of the APK, used to reject a truncated download.
  final String sha256;
  final int sizeBytes;
  final String? notes;

  /// `12.4 MB`, for a download prompt.
  String get readableSize {
    if (sizeBytes <= 0) return '';
    const units = ['B', 'KB', 'MB', 'GB'];
    var value = sizeBytes.toDouble();
    var unit = 0;
    while (value >= 1024 && unit < units.length - 1) {
      value /= 1024;
      unit++;
    }
    final decimals = unit == 0 || value >= 100 ? 0 : 1;
    return '${value.toStringAsFixed(decimals)} ${units[unit]}';
  }

  /// Manifest text is untrusted: it is fetched over the network and its keys
  /// and values are whatever the host served. Anything that fails a check here
  /// is dropped rather than repaired.
  static PortalRelease? _tryParse(
    String slug,
    Object? raw, {
    String? requiredHost,
  }) {
    if (raw is! Map) return null;

    final versionCode = _asInt(raw['versionCode']);
    final apk = _asUri(raw['apk']);
    if (versionCode == null || versionCode <= 0 || apk == null) return null;

    // Only https. A manifest is fetched over TLS, but it names its own
    // download URL — without this an edited manifest could point an installer
    // at plain http and a network attacker could swap the bytes.
    if (apk.scheme != 'https') return null;

    // The APK must come from the same host as the manifest that named it.
    // Defence in depth: it does not stop whoever controls the manifest, but it
    // stops a manifest that is merely *wrong* from sending an installer to an
    // unrelated host.
    if (requiredHost != null && apk.host.toLowerCase() != requiredHost) {
      return null;
    }

    // A missing checksum is refused rather than warned about. Every manifest
    // this project publishes has one, so an entry without it is a malformed or
    // tampered manifest, not a legitimate publish that skipped a field.
    final sha = (raw['sha256'] as String?)?.trim().toLowerCase() ?? '';
    if (!RegExp(r'^[0-9a-f]{64}$').hasMatch(sha)) return null;

    return PortalRelease(
      slug: slug,
      versionCode: versionCode,
      versionName: _clamp(raw['versionName'] as String?, 32) ?? '',
      apkUrl: apk,
      sha256: sha,
      sizeBytes: _asInt(raw['size']) ?? 0,
      // Rendered in a dialog, so it is length-capped: an unbounded string from
      // the network should not be able to push the buttons off the screen.
      notes: _clamp(raw['notes'] as String?, 500),
    );
  }

  static String? _clamp(String? v, int max) {
    final t = v?.trim();
    if (t == null || t.isEmpty) return null;
    return t.length <= max ? t : '${t.substring(0, max)}…';
  }

  static int? _asInt(Object? v) {
    if (v is int) return v;
    if (v is String) return int.tryParse(v.trim());
    return null;
  }

  static Uri? _asUri(Object? v) {
    if (v is! String || v.trim().isEmpty) return null;
    return Uri.tryParse(v.trim());
  }
}

/// The decoded `updates.json`.
class PortalUpdateManifest {
  const PortalUpdateManifest(this.releases);

  /// Keyed by app slug. Entries that fail to parse are dropped, not thrown —
  /// one malformed app must not stop the other six from updating.
  final Map<String, PortalRelease> releases;

  /// Parses a decoded manifest body. Returns null when it is unusable.
  ///
  /// [requiredHost], when given, is the host the manifest itself was fetched
  /// from; releases pointing anywhere else are dropped.
  static PortalUpdateManifest? fromJson(Object? decoded, {String? requiredHost}) {
    if (decoded is! Map) return null;
    if (PortalRelease._asInt(decoded['schema']) != kPortalUpdateSchema) {
      return null;
    }
    final apps = decoded['apps'];
    if (apps is! Map) return null;

    final host = requiredHost?.trim().toLowerCase();
    final releases = <String, PortalRelease>{};
    apps.forEach((key, value) {
      if (key is! String) return;
      final slug = key.trim().toLowerCase();
      // Keys reach a filename on disk. Today a lookup can only ever return the
      // caller's own already-sanitised slug, so a hostile key cannot be
      // selected — but the sanitising belongs where the untrusted value
      // enters, not in an argument about why it cannot escape.
      if (!RegExp(r'^[a-z0-9-]{1,64}$').hasMatch(slug)) return;
      final release = PortalRelease._tryParse(slug, value, requiredHost: host);
      if (release != null) releases[slug] = release;
    });
    return PortalUpdateManifest(releases);
  }

  /// The release for [slug] when it is newer than [currentVersionCode].
  ///
  /// Returns null when the app is absent, current, or *ahead* of the manifest.
  /// Ahead matters: a local build carries a higher commit count than the last
  /// publish, and offering to "update" it would install an older APK — which
  /// Android refuses anyway, so the user would only see a failure.
  PortalRelease? updateFor(String slug, int currentVersionCode) {
    final release = releases[slug.trim().toLowerCase()];
    if (release == null) return null;
    return release.versionCode > currentVersionCode ? release : null;
  }
}

/// Reads the running app's `versionCode` from a [PackageInfo.buildNumber].
///
/// Returns null when it cannot be read as a number. Callers treat that as
/// "cannot tell" and offer no update: guessing 0 would offer an update on
/// every launch and never stop.
int? parseVersionCode(String buildNumber) {
  final n = int.tryParse(buildNumber.trim());
  return (n == null || n < 0) ? null : n;
}
