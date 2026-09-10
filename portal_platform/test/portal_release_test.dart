import 'package:flutter_test/flutter_test.dart';
import 'package:portal_platform/portal_platform.dart';

/// The comparison rules decide whether a user is offered a download, so they
/// are the part worth pinning. Everything else in the update path is HTTP and
/// platform calls.
const _sha =
    '670455155fb04174d7d47f57e5af2745e2c316293ca1ed94f04e7f9e07df163d';

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
                'sha256': _sha,
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
          'sha256': _sha,
        },
      }))!;
      expect(m.releases, isEmpty);
    });

    test('drops one malformed app without losing the others', () {
      final m = PortalUpdateManifest.fromJson(manifest(apps: {
        'portal-gym': {
          'versionCode': 44,
          'apk': 'https://e.com/g.apk',
          'sha256': _sha,
        },
        'portal-recipe': {
          'versionCode': 'not a number',
          'apk': 'https://e.com/r.apk',
          'sha256': _sha,
        },
        'portal-task': {'versionCode': 9},
      }))!;
      expect(m.releases.keys, ['portal-gym']);
    });

    test('rejects a release with no usable sha256', () {
      // The manifest picks the bytes handed to the package installer. Every
      // real publish carries a checksum, so a missing or malformed one is a
      // tampered or broken manifest, not a publish that skipped a field.
      for (final sha in [null, '', 'ab12', 'z' * 64]) {
        final m = PortalUpdateManifest.fromJson(manifest(apps: {
          'portal-gym': {
            'versionCode': 44,
            'apk': 'https://example.com/g.apk',
            if (sha != null) 'sha256': sha,
          },
        }))!;
        expect(m.releases, isEmpty, reason: 'sha256=$sha');
      }
    });

    test('drops an apk hosted somewhere other than the manifest', () {
      final m = PortalUpdateManifest.fromJson(
        manifest(apps: {
          'portal-gym': {
            'versionCode': 44,
            'apk': 'https://elsewhere.example/g.apk',
            'sha256': _sha,
          },
        }),
        requiredHost: 'github.com',
      )!;
      expect(m.releases, isEmpty);
    });

    test('keeps an apk on the manifest host', () {
      final m = PortalUpdateManifest.fromJson(
        manifest(apps: {
          'portal-gym': {
            'versionCode': 44,
            'apk': 'https://github.com/o/r/releases/download/v1/g.apk',
            'sha256': _sha,
          },
        }),
        requiredHost: 'github.com',
      )!;
      expect(m.releases.keys, ['portal-gym']);
    });

    test('drops a slug that could escape a file path', () {
      // The slug reaches a filename in the temp directory.
      final m = PortalUpdateManifest.fromJson(manifest(apps: {
        '../../evil': {
          'versionCode': 99,
          'apk': 'https://example.com/e.apk',
          'sha256': _sha,
        },
      }))!;
      expect(m.releases, isEmpty);
    });

    test('caps notes so a dialog cannot be pushed off screen', () {
      final m = PortalUpdateManifest.fromJson(manifest(apps: {
        'portal-gym': {
          'versionCode': 44,
          'apk': 'https://example.com/g.apk',
          'sha256': _sha,
          'notes': 'x' * 5000,
        },
      }))!;
      expect(m.releases['portal-gym']!.notes!.length, lessThanOrEqualTo(501));
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

  group('the app list', () {
    Map<String, Object?> entry(int code) => {
          'versionCode': code,
          'versionName': '1.0.0',
          'apk': 'https://example.com/app.apk',
          'sha256': _sha,
          'size': 1024,
        };

    final m = PortalUpdateManifest.fromJson(manifest(apps: {
      'portal-shopping': entry(44),
      'portal-gym': entry(44),
      'portal-meal-plan': entry(44),
    }))!;

    test('lists every app except the one asking, in display order', () {
      expect(
        m.others('portal-gym').map((r) => r.displayName),
        ['Meal Plan', 'Shopping'],
      );
    });

    test('excludes the host app case-insensitively', () {
      expect(m.others('Portal-Gym ').length, 2);
    });

    test('lists everything when the host is not in the manifest', () {
      expect(m.others('portal-finance').length, 3);
    });

    test('titles a slug it does not recognise rather than dropping it', () {
      final other = PortalUpdateManifest.fromJson(manifest(apps: {
        'someapp': entry(1),
      }))!;
      expect(other.others('portal-gym').single.displayName, 'Someapp');
    });
  });

  group('portalAppUri', () {
    test('is the slug as a scheme, matching the manifests', () {
      // The <data android:scheme> in each app manifest and the <queries>
      // entries in every other one are written from this same slug. If this
      // shape changes, canLaunchUrl silently answers false for every app and
      // the list quietly says Install for things that are installed.
      expect(portalAppUri('portal-gym').toString(), 'portal-gym://open');
      expect(portalAppUri('portal-recipe').scheme, 'portal-recipe');
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

  group('publish metadata', () {
    test('reads a per-app published stamp', () {
      final parsed = PortalUpdateManifest.fromJson(manifest(apps: {
        'portal-gym': {
          'versionCode': 44,
          'versionName': '1.0.0',
          'apk': 'https://example.com/portal_gym.apk',
          'sha256': _sha,
          'size': 1,
          'published': '2026-09-08T09:30:00Z',
        },
      }))!;
      expect(
        parsed.releases['portal-gym']!.publishedAt,
        DateTime.utc(2026, 9, 8, 9, 30).toLocal(),
      );
    });

    test('falls back to the manifest stamp, and is null without either', () {
      // An entry published before the field existed still has a date worth
      // showing; one with neither shows no date rather than a wrong one.
      final withGenerated = PortalUpdateManifest.fromJson({
        ...manifest(),
        'generated': '2026-09-01T00:00:00Z',
      })!;
      expect(
        withGenerated.releases['portal-gym']!.publishedAt,
        DateTime.utc(2026, 9, 1).toLocal(),
      );
      expect(withGenerated.generatedAt, DateTime.utc(2026, 9, 1).toLocal());

      final bare = PortalUpdateManifest.fromJson(manifest())!;
      expect(bare.releases['portal-gym']!.publishedAt, isNull);
      expect(bare.generatedAt, isNull);
    });

    test('latestFor answers even when the running build is current', () {
      // The version panel shows what is published next to what is installed;
      // updateFor deliberately says nothing once they match.
      final parsed = PortalUpdateManifest.fromJson(manifest())!;
      expect(parsed.updateFor('portal-gym', 44), isNull);
      expect(parsed.latestFor(' Portal-Gym ')!.versionCode, 44);
      expect(parsed.latestFor('portal-nope'), isNull);
    });
  });

  group('portalFormatSince', () {
    final now = DateTime(2026, 9, 10, 12);

    test('reads a null stamp as never, not as blank', () {
      expect(portalFormatSince(null), 'Never');
    });

    test('counts up through the units, then gives the date', () {
      expect(portalFormatSince(now, now: now), 'Just now');
      expect(
        portalFormatSince(now.subtract(const Duration(minutes: 1)), now: now),
        '1 minute ago',
      );
      expect(
        portalFormatSince(now.subtract(const Duration(minutes: 90)), now: now),
        '1 hour ago',
      );
      expect(
        portalFormatSince(now.subtract(const Duration(days: 3)), now: now),
        '3 days ago',
      );
      expect(
        portalFormatSince(now.subtract(const Duration(days: 30)), now: now),
        contains('2026'),
      );
    });

    test('a clock that went backwards reads as just now, not a negative gap',
        () {
      expect(
        portalFormatSince(now.add(const Duration(hours: 2)), now: now),
        'Just now',
      );
    });
  });
}
