import 'package:flutter_test/flutter_test.dart';
import 'package:portal_platform/portal_platform.dart';

void main() {
  group('portalSlugFromUri', () {
    test('reads the slug from a portal-<slug> scheme', () {
      expect(portalSlugFromUri(Uri.parse('portal-gym://workout')), 'gym');
      expect(portalSlugFromUri(Uri.parse('portal-journey://library')), 'journey');
    });

    test('is case-insensitive on the scheme', () {
      // Uri lowercases the scheme itself, but guard the intent explicitly.
      expect(portalSlugFromUri(Uri.parse('PORTAL-GYM://x')), 'gym');
    });

    test('path-less links still carry a slug (host is the route, not the slug)',
        () {
      // portal-gym://gym → host 'gym', empty path; the slug is the scheme.
      expect(portalSlugFromUri(Uri.parse('portal-gym://gym')), 'gym');
    });

    test('non-per-app schemes return null', () {
      expect(portalSlugFromUri(Uri.parse('portalwarp://gym')), isNull);
      expect(portalSlugFromUri(Uri.parse('https://example.com/gym')), isNull);
      expect(portalSlugFromUri(Uri.parse('portal-://x')), isNull); // empty slug
    });
  });
}
