/// Pulls the answer out of a JSON reply while it is still arriving.
///
/// The agent loop talks JSON (`{"tool": ...}` or `{"final": "..."}`), so a
/// streaming client hands back JSON syntax, not prose. Waiting for the closing
/// brace to show anything is what makes the assistant feel dead on a long
/// answer, so this reads the value of `"final"` out of the partial text as the
/// chunks land and reports what is new since the last chunk.
///
/// A reply that turns out to be a tool call simply never emits: there is no
/// `"final"` key to find, and the step list is what the UI shows instead.
class StreamedFinalText {
  final _raw = StringBuffer();
  int _emitted = 0;

  /// Feeds one chunk in, returning the text that has appeared since the last
  /// call. Empty when this chunk added nothing showable.
  String add(String chunk) {
    _raw.write(chunk);
    // ponytail: re-decodes the whole value per chunk, O(n^2) over a reply.
    // A reply is a few KB; switch to an incremental scanner if that changes.
    final text = _decode(_raw.toString());
    if (text.length <= _emitted) return '';
    final delta = text.substring(_emitted);
    _emitted = text.length;
    return delta;
  }

  /// Everything shown so far.
  String get text => _raw.isEmpty ? '' : _decode(_raw.toString());

  /// The value of the first `"final"` string in [raw], decoded as far as it
  /// goes. Returns empty until the key and its opening quote have arrived.
  static String _decode(String raw) {
    final key = RegExp(r'"final"\s*:\s*"').firstMatch(raw);
    if (key == null) return '';
    final out = StringBuffer();
    for (var i = key.end; i < raw.length; i++) {
      final char = raw[i];
      if (char == '"') break;
      if (char != r'\') {
        out.write(char);
        continue;
      }
      // An escape split across two chunks: stop here and pick it up whole
      // next time rather than printing a stray backslash.
      if (i + 1 >= raw.length) break;
      final escape = raw[i + 1];
      i++;
      switch (escape) {
        case 'n':
          out.write('\n');
        case 't':
          out.write('\t');
        case 'r':
          out.write('\r');
        case 'b':
          out.write('\b');
        case 'f':
          out.write('\f');
        case 'u':
          if (i + 4 >= raw.length) return out.toString();
          final code = int.tryParse(raw.substring(i + 1, i + 5), radix: 16);
          if (code == null) return out.toString();
          out.writeCharCode(code);
          i += 4;
        default:
          // \" \\ \/ and anything else: the character itself.
          out.write(escape);
      }
    }
    return out.toString();
  }
}
