/// Builds module URLs from [ApiClient.baseUrl] (`http://host:3000/api`).
abstract final class PortalApiPaths {
  static String module(String apiBaseUrl, String segment) {
    final base = apiBaseUrl.trim().replaceAll(RegExp(r'/+$'), '');
    final path = segment.replaceAll(RegExp(r'^/+'), '');
    return '$base/$path';
  }
}
