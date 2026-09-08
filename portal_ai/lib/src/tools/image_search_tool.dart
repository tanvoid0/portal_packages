import 'ai_tool.dart';

/// Photos offered per search -- enough for the model to pick a good fit
/// without flooding the transcript.
const _resultsPerSearch = 5;

/// Finds a real photo to use as a cover image, backed by the Portal server's
/// authenticated, cached Unsplash proxy -- the same endpoint the manual
/// "choose a photo" picker sheets already call.
///
/// Text-only by design, matching `web_search_tool`: it returns descriptions
/// and URLs for the model to reason about, not a tappable gallery. Assigning
/// the chosen URL to an entity is left to an app-specific tool (e.g.
/// `set_recipe_image`), since which entity gets an image is never shared
/// across apps.
AiTool imageSearchTool({
  /// Matches `ApiClient.get` in portal_platform, so apps pass that directly
  /// and the assistant inherits their auth and session handling. Query
  /// params are folded into [path] rather than taken as a separate argument,
  /// since `ApiClient.get`'s own `queryParams` *replaces* rather than merges
  /// with any query string already in the path.
  required Future<dynamic> Function(String path) get,
  required String unsplashBaseUrl,
}) {
  return AiTool(
    name: 'image_search',
    description:
        'Search for a real photo to use as a cover image, e.g. '
        '"chicken alfredo" or "blue denim jacket". Returns a short list of '
        'photos with their URLs -- never invent an image URL yourself, and '
        'never assign one the user has not chosen.',
    parameters: const {'query': 'what the photo should show (required)'},
    run: (call) async {
      final query = call.argString('query');
      if (query == null) throw ArgumentError('query is required');

      final path =
          '$unsplashBaseUrl/search?query='
          '${Uri.encodeQueryComponent(query)}&perPage=$_resultsPerSearch';
      final data = await get(path);
      final photos = data is Map ? data['photos'] : null;
      if (photos is! List || photos.isEmpty) {
        return 'no photos found for "$query"';
      }

      return photos
          .take(_resultsPerSearch)
          .map((raw) {
            final photo = Map<String, dynamic>.from(raw as Map);
            final urls = Map<String, dynamic>.from(photo['urls'] as Map? ?? {});
            final description = (photo['description'] as String?)?.trim();
            return '${description?.isNotEmpty == true ? description : query}: '
                '${urls['regular'] ?? ''}';
          })
          .join('\n');
    },
  );
}
