/// Normalizes lean Mongo/API maps so models can read `id`.
Map<String, dynamic> normalizeMongoDocumentJson(Map<String, dynamic> json) {
  final normalized = Map<String, dynamic>.from(json);
  normalized['id'] ??= normalized.remove('_id');
  return normalized;
}
