import 'mongo_document_json.dart';

/// Coerces legacy API/Mongo id values to strings for json_serializable.
String? coerceDocumentId(dynamic raw) {
  if (raw == null) return null;
  if (raw is String) return raw;
  return raw.toString();
}

/// Normalizes `unit` from API payloads (object, legacy string, or absent).
Object? normalizeShoppingUnitJson(dynamic unit) {
  if (unit == null) return null;
  if (unit is Map<String, dynamic>) return unit;
  if (unit is Map) return Map<String, dynamic>.from(unit);
  if (unit is String && unit.isNotEmpty) {
    return <String, dynamic>{'type': unit, 'custom_unit': ''};
  }
  return null;
}

Map<String, dynamic> prepareShoppingItemJson(Map<String, dynamic> json) {
  final normalized = normalizeMongoDocumentJson(json);
  final id = coerceDocumentId(normalized['id']);
  if (id != null) normalized['id'] = id;
  normalized['unit'] = normalizeShoppingUnitJson(normalized['unit']);
  return normalized;
}

Map<String, dynamic> prepareShoppingListJson(Map<String, dynamic> json) {
  final normalized = normalizeMongoDocumentJson(json);
  final id = coerceDocumentId(normalized['id']);
  if (id != null) normalized['id'] = id;
  return normalized;
}
