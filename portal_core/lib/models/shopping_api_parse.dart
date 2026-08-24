import 'dart:developer' as developer;

/// Thrown when a shopping API response cannot be decoded for the UI.
class ShoppingParseException implements Exception {
  ShoppingParseException(
    this.message, {
    this.cause,
    this.endpoint,
    this.itemIndex,
    this.rawSnippet,
  });

  final String message;
  final Object? cause;
  final String? endpoint;
  final int? itemIndex;
  final String? rawSnippet;

  @override
  String toString() {
    final buf = StringBuffer(message);
    if (endpoint != null) buf.write(' [$endpoint]');
    if (itemIndex != null) buf.write(' item=$itemIndex');
    if (cause != null) buf.write(': $cause');
    return buf.toString();
  }
}

/// Decodes a JSON array from shopping endpoints with per-row error context.
List<T> parseShoppingApiList<T>({
  required dynamic response,
  required String endpoint,
  required T Function(Map<String, dynamic> json) decode,
}) {
  if (response is! List) {
    final type = response.runtimeType;
    final snippet = _snippet(response);
    _logParseFailure(
      'Expected JSON array from $endpoint, got $type',
      endpoint: endpoint,
      snippet: snippet,
    );
    throw ShoppingParseException(
      'Expected JSON array, got $type',
      endpoint: endpoint,
      rawSnippet: snippet,
    );
  }

  final out = <T>[];
  for (var i = 0; i < response.length; i++) {
    final raw = response[i];
    if (raw is! Map) {
      final type = raw.runtimeType;
      final snippet = _snippet(raw);
      _logParseFailure(
        'Item $i: expected object, got $type',
        endpoint: endpoint,
        itemIndex: i,
        snippet: snippet,
      );
      throw ShoppingParseException(
        'Item $i: expected object, got $type',
        endpoint: endpoint,
        itemIndex: i,
        rawSnippet: snippet,
      );
    }
    final map = Map<String, dynamic>.from(raw);
    try {
      out.add(decode(map));
    } catch (e, st) {
      final id = map['id'] ?? map['_id'];
      final name = map['name'];
      _logParseFailure(
        'Item $i parse failed (id=$id, name=$name)',
        endpoint: endpoint,
        itemIndex: i,
        cause: e,
        stack: st,
        snippet: map.toString(),
      );
      throw ShoppingParseException(
        'Item $i parse failed (id=$id, name=$name)',
        endpoint: endpoint,
        itemIndex: i,
        cause: e,
        rawSnippet: _snippet(map),
      );
    }
  }
  return out;
}

String _snippet(Object? value, {int maxLen = 240}) {
  final text = value?.toString() ?? 'null';
  if (text.length <= maxLen) return text;
  return '${text.substring(0, maxLen)}…';
}

void _logParseFailure(
  String message, {
  required String endpoint,
  int? itemIndex,
  Object? cause,
  StackTrace? stack,
  String? snippet,
}) {
  developer.log(
    message,
    name: 'ShoppingApi',
    error: cause,
    stackTrace: stack,
  );
  assert(() {
    // ignore: avoid_print
    print('[ShoppingApi] $message');
    if (endpoint.isNotEmpty) {
      // ignore: avoid_print
      print('[ShoppingApi] endpoint=$endpoint');
    }
    if (itemIndex != null) {
      // ignore: avoid_print
      print('[ShoppingApi] itemIndex=$itemIndex');
    }
    if (snippet != null) {
      // ignore: avoid_print
      print('[ShoppingApi] raw=$snippet');
    }
    if (cause != null) {
      // ignore: avoid_print
      print('[ShoppingApi] cause=$cause');
    }
    if (stack != null) {
      // ignore: avoid_print
      print('[ShoppingApi] $stack');
    }
    return true;
  }());
}
