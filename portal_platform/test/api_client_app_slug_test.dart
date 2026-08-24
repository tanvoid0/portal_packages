import 'package:flutter_test/flutter_test.dart';
import 'package:portal_platform/portal_platform.dart';

/// The slug goes out as `X-Portal-App` and is the key the server's email brand
/// registry looks up, so these values are a wire contract: changing one without
/// changing `server/portal_server/src/shared/mail/portal-app-brands.ts` drops
/// that app back to default branding.
void main() {
  test('app titles slugify to the server brand keys', () {
    expect(ApiClient.slugifyAppName('Portal Shopping'), 'portal-shopping');
    expect(ApiClient.slugifyAppName('Portal Task'), 'portal-task');
    expect(ApiClient.slugifyAppName('Portal Gym'), 'portal-gym');
    expect(ApiClient.slugifyAppName('Portal Lifestyle'), 'portal-lifestyle');
    expect(
      ApiClient.slugifyAppName('Portal Productivity'),
      'portal-productivity',
    );
    expect(ApiClient.slugifyAppName('RecipeMaker'), 'recipemaker');
  });

  test('punctuation and padding do not leak into the header', () {
    expect(ApiClient.slugifyAppName('  Portal  Task! '), 'portal-task');
    expect(ApiClient.slugifyAppName(''), '');
  });
}
