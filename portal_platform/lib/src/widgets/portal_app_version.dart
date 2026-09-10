import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Loads and caches [PackageInfo] for the host app.
class PortalAppVersion {
  PortalAppVersion._();

  static Future<PackageInfo>? _cache;

  /// Returns cached platform package info for the running app.
  static Future<PackageInfo> load() =>
      _cache ??= PackageInfo.fromPlatform();

  /// Formats [info] as `major.minor.patch (build)` when [includeBuildNumber]
  /// is true and a build number is present.
  static String format(
    PackageInfo info, {
    bool includeBuildNumber = true,
  }) {
    if (includeBuildNumber && info.buildNumber.isNotEmpty) {
      return '${info.version} (${info.buildNumber})';
    }
    return info.version;
  }
}

/// Displays the host app's version string from platform package info.
///
/// Use as a settings trailing label, footer, or anywhere the running app
/// version should appear. Styling follows [style] or the current theme.
class PortalAppVersionText extends StatelessWidget {
  const PortalAppVersionText({
    super.key,
    this.style,
    this.includeBuildNumber = true,
    this.loadingPlaceholder = '…',
  });

  final TextStyle? style;
  final bool includeBuildNumber;
  final String loadingPlaceholder;

  @override
  Widget build(BuildContext context) {
    final resolvedStyle =
        style ?? Theme.of(context).textTheme.bodyMedium;

    return FutureBuilder<PackageInfo>(
      future: PortalAppVersion.load(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Text(loadingPlaceholder, style: resolvedStyle);
        }

        return Text(
          PortalAppVersion.format(
            snapshot.data!,
            includeBuildNumber: includeBuildNumber,
          ),
          style: resolvedStyle,
        );
      },
    );
  }
}
