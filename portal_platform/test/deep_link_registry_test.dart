import 'package:flutter_test/flutter_test.dart';
import 'package:portal_platform/portal_platform.dart';

/// A resolver written the way every app writes one. If [DeepLinkPathResolver]
/// changes shape, this stops compiling — which is the point: the apps live in
/// separate pub workspaces, so nothing else catches a signature break here.
DeepLinkResolution? _appResolver(
  String normalizedPath, {
  Map<String, String> queryParameters = const {},
}) {
  if (normalizedPath == '/home') {
    return DeepLinkResolution(
      routePath: '/home',
      extra: queryParameters.isEmpty ? null : queryParameters,
    );
  }
  return null;
}

void main() {
  tearDown(DeepLinkRegistry.clear);

  test('resolves through a registered app resolver', () {
    DeepLinkRegistry.register(_appResolver);

    expect(DeepLinkRegistry.resolve('/home')?.routePath, '/home');
    expect(DeepLinkRegistry.resolve('/nope'), isNull);
  });

  test('forwards query parameters to the resolver', () {
    DeepLinkRegistry.register(_appResolver);

    final resolution = DeepLinkRegistry.resolve(
      '/home',
      queryParameters: const {'tab': 'today'},
    );

    expect(resolution?.extra, const {'tab': 'today'});
  });

  test('returns null with no resolver registered', () {
    expect(DeepLinkRegistry.resolve('/home'), isNull);
  });
}
