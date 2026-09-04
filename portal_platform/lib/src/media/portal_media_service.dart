import 'dart:typed_data';

import 'package:get/get.dart';

import '../services/api_client.dart';
import 'portal_image_search_service.dart';

/// Uploads to the shared media store and hands back the URL to persist.
///
/// Every image an app stores goes through here, so entities only ever hold a
/// URL we control. A raw Unsplash or pasted link would be a permanent
/// dependency on somebody else's CDN — one that can rotate, rate-limit, or
/// disappear, taking the user's recipe photo with it.
class PortalMediaService {
  PortalMediaService({ApiClient? api}) : _api = api ?? Get.find<ApiClient>();

  final ApiClient _api;

  /// Stores bytes picked from the gallery or camera.
  Future<String> uploadBytes(Uint8List bytes, String filename) async {
    final data = await _api.postMultipart(
      '/media',
      fieldName: 'file',
      fileBytes: bytes,
      filename: filename,
    );
    return _urlFrom(data);
  }

  /// Asks the server to fetch a remote image and store its own copy. Used for
  /// both an Unsplash result and a link the user pasted.
  Future<String> importUrl(String url) async {
    final data = await _api.post('/media/from-url', body: {'url': url});
    return _urlFrom(data);
  }

  String _urlFrom(dynamic data) {
    final url = (data is Map ? data['url'] : null) as String?;
    if (url == null || url.isEmpty) {
      throw StateError('Media upload returned no url');
    }
    return url;
  }
}

/// Searches the photo library and stores our own copy of the top hit,
/// returning its URL — or null when nothing matched.
///
/// This exists because every automatic image path (an AI tool setting a cover,
/// a backfill filling in missing thumbnails) had independently written
/// "search, take the first result, save its CDN link". That link is somebody
/// else's URL on our user's data. One helper, so there is one place where the
/// copy happens.
Future<String?> portalImportTopImage(
  String query, {
  bool preferThumb = false,
  PortalImageSearchService? search,
  PortalMediaService? media,
}) async {
  final results =
      await (search ?? PortalImageSearchService()).search(query, perPage: 1);
  if (results.isEmpty) return null;
  final photo = results.first;
  final source = preferThumb ? photo.smallUrl : photo.regularUrl;
  if (source.isEmpty) return null;
  return (media ?? PortalMediaService()).importUrl(source);
}
