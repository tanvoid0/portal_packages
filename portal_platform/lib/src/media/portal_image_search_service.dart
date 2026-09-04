import 'package:get/get.dart';

import '../services/api_client.dart';
import '../services/portal_api_paths.dart';

/// One photo returned by the server's Unsplash proxy.
///
/// Only the fields any Portal app actually renders are kept; the proxy returns
/// the full Unsplash payload.
class PortalImageResult {
  final String id;
  final String? description;
  final String fullUrl;
  final String regularUrl;
  final String smallUrl;
  final String thumbUrl;
  final String authorName;
  final String authorUsername;
  final int width;
  final int height;

  /// Unsplash's dominant colour for the photo, as `#rrggbb`. Used as the
  /// placeholder so a loading grid does not flash grey.
  final String? color;

  const PortalImageResult({
    required this.id,
    this.description,
    required this.fullUrl,
    required this.regularUrl,
    required this.smallUrl,
    required this.thumbUrl,
    required this.authorName,
    required this.authorUsername,
    required this.width,
    required this.height,
    this.color,
  });

  factory PortalImageResult.fromJson(Map<String, dynamic> json) {
    final urls = Map<String, dynamic>.from(json['urls'] as Map? ?? {});
    final user = Map<String, dynamic>.from(json['user'] as Map? ?? {});
    return PortalImageResult(
      id: json['id'] as String? ?? '',
      description: json['description'] as String?,
      fullUrl: urls['full'] as String? ?? '',
      regularUrl: urls['regular'] as String? ?? '',
      smallUrl: urls['small'] as String? ?? '',
      thumbUrl: urls['thumb'] as String? ?? '',
      authorName: user['name'] as String? ?? '',
      authorUsername: user['username'] as String? ?? '',
      width: json['width'] as int? ?? 0,
      height: json['height'] as int? ?? 0,
      color: json['color'] as String?,
    );
  }

  /// Unsplash's API terms require a link back to the photographer's profile.
  String get authorProfileUrl =>
      'https://unsplash.com/@$authorUsername?utm_source=portal&utm_medium=referral';
}

/// Client for the server's cached Unsplash proxy.
///
/// Registered lazily rather than in `main()`: it holds no state, so every
/// caller can construct its own.
class PortalImageSearchService {
  PortalImageSearchService({ApiClient? api}) : _api = api ?? Get.find<ApiClient>();

  final ApiClient _api;

  /// The server caps `perPage` at 30 and has no page parameter, so one search
  /// is one screenful — ask for a generous one.
  static const int defaultPerPage = 24;

  Future<List<PortalImageResult>> search(
    String query, {
    int perPage = defaultPerPage,
  }) async {
    final data = await _api.get(
      '${PortalApiPaths.module(_api.baseUrl, 'unsplash')}/search',
      queryParams: {'query': query, 'perPage': perPage.toString()},
    );

    return (data['photos'] as List?)
            ?.map((p) => PortalImageResult.fromJson(Map<String, dynamic>.from(p)))
            .toList() ??
        const [];
  }
}
