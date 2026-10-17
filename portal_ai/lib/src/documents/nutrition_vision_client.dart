import '../clients/ai_completion_client.dart';
import 'ai_document_client.dart';

/// Reads a photo of a food label or a plate into nutrition facts, server-side.
///
/// Returns the server's JSON untouched — `{ name, nutrition: { calories,
/// protein, carbs, fat, fiber?, sugar?, sodium? } }` — so portal_ai stays free
/// of any app model; callers map it themselves. Non-2xx replies are thrown by
/// the injected poster, as with [AiDocumentClient].
///
/// Server route: `POST /nutrition/ai/extract` (multipart, field `file`).
class NutritionVisionClient {
  const NutritionVisionClient({
    required this.postMultipart,
    this.path = '/nutrition/ai/extract',
  });

  final AiPostMultipart postMultipart;
  final String path;

  /// The server sniffs the image type from the bytes, so none is sent.
  Future<Map<String, dynamic>> extractNutrition({
    required List<int> bytes,
    String filename = 'food.jpg',
  }) async {
    final dynamic response = await postMultipart(
      path,
      fieldName: 'file',
      fileBytes: bytes,
      filename: filename,
    );
    if (response is! Map) {
      throw const AiCompletionException('No nutrition facts in that photo');
    }
    return Map<String, dynamic>.from(response);
  }
}
