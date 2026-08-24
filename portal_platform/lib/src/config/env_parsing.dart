/// Parses common truthy/falsey strings from dotenv values.
bool envFlag(String? value, {bool defaultValue = false}) {
  if (value == null) return defaultValue;
  final v = value.trim().toLowerCase();
  if (v.isEmpty) return defaultValue;
  return v == 'true' || v == '1' || v == 'yes';
}
