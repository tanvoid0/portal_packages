import 'package:flutter_test/flutter_test.dart';
import 'package:portal_platform/portal_platform.dart';

/// The comparison rules decide whether a user is offered a download, so they
/// are the part worth pinning. Everything else in the update path is HTTP and
/// platform calls.
void main() {
  Map<String, Object?> manifest({
    int schema = 1,
    Map<String, Object?>? apps,
  }) =>
      {
        'schema': schema,
        'apps': apps ??
            {
              'portal-gym': {
                'versionCode': 44,
                'versionName': '1.0.0',
                'apk': 'https://example.com/portal_gym.apk',
                'sha256': 'ab12',
                'size': 12 * 1024 * 1024,
              },
            },
      };

  group('PortalUpdateManifest.fromJson', () {
    test('parses a well-formed manifest', () {
      final m = PortalUpdateManifest.fromJson(manifest())!;
      expect(m.releases['portal-gym']!.versionCode, 44);
      expect(m.releases['portal-gym']!.readableSize, '12.0 MB');
    });

    test('rejects an unknown schema rather than guessing at the fields', () {
      expect(PortalUpdateManifest.fromJson(manifest(schema: 2)), isNull);
      expect(PortalUpdateManifest.fromJson(manifest(schema: 0)), isNull);
    });

    test('rejects a non-https apk url', () {
      final m = PortalUpdateManifest.fromJson(manifest(apps: {
        'portal-gym': {
          'versionCode': 44,
          'apk': 'http://example.com/portal_gym.apk',
        },
      }))!;
      expect(m.releases, isEmpty);
    });

    test('drops one malformed app without losing the others', () {
      final m = PortalUpdateManifest.fromJson(manifest(apps: {
        'portal-gym': {'versionCode': 44, 'apk': 'https://e.com/g.apk'},
        'portal-recipe': {'versionCode': 'not a number', 'apk': 'https://e.com/r.apk'},
        'portal-task': {'versionCode': 9},
      }))!;
      expect(m.releases.keys, ['portal-gym']);
    });

    test('returns null for junk instead of throwing at a launch', () {
      expect(PortalUpdateManifest.fromJson(null), isNull);
      expect(PortalUpdateManifest.fromJson('<html>404</html>'), isNull);
      expect(PortalUpdateManifest.fromJson({'schema': 1}), isNull);
    });
  });

  group('updateFor', () {
    final m = PortalUpdateManifest.fromJson(manifest())!;

    test('offers a strictly newer build', () {
      expect(m.updateFor('portal-gym', 43)!.versionCode, 44);
    });

    test('offers nothing when current', () {
      expect(m.updateFor('portal-gym', 44), isNull);
    });

    test('offers nothing when the local build is ahead', () {
      // A dev build carries a higher commit count than the last publish.
      // Android would refuse the downgrade, so this must not be offered.
      expect(m.updateFor('portal-gym', 50), isNull);
    });

    test('offers nothing for an app absent from the manifest', () {
      expect(m.updateFor('portal-finance', 1), isNull);
    });

    test('matches the slug case-insensitively', () {
      expect(m.updateFor('Portal-Gym', 43), isNotNull);
    });
  });

  group('parseVersionCode', () {
    test('reads a numeric build number', () {
      expect(parseVersionCode('44'), 44);
      expect(parseVersionCode(' 44 '), 44);
    });

    test('returns null rather than 0 for an unreadable one', () {
      // 0 would make every manifest entry look newer, so the app would offer
      // an update on every launch forever.
      expect(parseVersionCode(''), isNull);
      expect(parseVersionCode('1.0.0'), isNull);
      expect(parseVersionCode('-1'), isNull);
    });
  });
}
