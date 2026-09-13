/// Turns a reply that is still arriving into sentences the voice can start
/// on, and turns markdown into words worth hearing.
///
/// Ported as a design from agent-platform's desktop voice: the first chunk of
/// a reply is the only one anybody waits on, so it closes early and on a
/// comma; every later chunk is synthesized while the previous one plays,
/// where a whole sentence reads better and costs nothing.
class AiSpeechChunker {
  /// Shortest chunk worth sending. Below this the per-utterance overhead
  /// costs more than the sentence saves, and "Hm." alone is a worse listen
  /// than waiting for its clause.
  static const minChunk = 24;

  /// The opening chunk: half the length, and a comma will do.
  static const minFirstChunk = 12;

  final _buffer = StringBuffer();
  bool _first = true;
  bool _inFence = false;

  /// Feeds one streamed delta; returns every sentence it completed, already
  /// stripped for speech.
  List<String> add(String delta) {
    _buffer.write(delta);
    final out = <String>[];
    while (true) {
      final sentence = _takeSentence();
      if (sentence == null) break;
      _emit(sentence, out);
    }
    return out;
  }

  /// End of stream: whatever is left, stripped. Resets for the next reply.
  List<String> flush() {
    final out = <String>[];
    final tail = _buffer.toString();
    _buffer.clear();
    if (tail.trim().isNotEmpty) _emit(tail, out);
    _first = true;
    _inFence = false;
    return out;
  }

  void _emit(String raw, List<String> out) {
    final spoken = _strip(raw);
    if (spoken.isNotEmpty) {
      out.add(spoken);
      _first = false;
    }
  }

  /// Splits off the first closed sentence of usable length, or null while
  /// the buffer has none.
  ///
  /// ponytail: naive terminator scan. Splits "3.5" and "Dr. Chen" only when
  /// whitespace follows the dot, so a decimal survives and an honorific costs
  /// a pause in the wrong place, not a wrong word. Swap in a real segmenter
  /// if numeric answers sound choppy.
  String? _takeSentence() {
    final text = _buffer.toString();
    final min = _first ? minFirstChunk : minChunk;
    for (var i = 0; i < text.length; i++) {
      if (i + 1 < min) continue;
      final c = text[i];
      final terminator =
          c == '.' ||
          c == '!' ||
          c == '?' ||
          c == '\n' ||
          c == ';' ||
          c == ':' ||
          (_first && c == ',');
      if (!terminator) continue;
      final next = i + 1 < text.length ? text[i + 1] : ' ';
      if (next.trim().isNotEmpty) continue;
      final sentence = text.substring(0, i + 1);
      _buffer
        ..clear()
        ..write(text.substring(i + 1).trimLeft());
      return sentence;
    }
    return null;
  }

  /// Markdown read aloud is "asterisk asterisk": the marks go, the words
  /// stay. A code block becomes "Code omitted." once, however many chunks
  /// it spans -- the fence state carries across calls.
  String _strip(String markdown) {
    final out = StringBuffer();
    for (final line in markdown.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.startsWith('```')) {
        if (!_inFence) out.write('Code omitted. ');
        _inFence = !_inFence;
        continue;
      }
      if (_inFence) continue;
      out
        ..write(
          trimmed
              .replaceFirst(RegExp(r'^[#>\-+*\s]+'), '')
              .replaceAllMapped(
                RegExp(r'!?\[([^\]]*)\]\([^)]*\)'),
                (m) => m[1]!,
              )
              .replaceAll(RegExp(r'[*_`~|]+'), ''),
        )
        ..write(' ');
    }
    return out.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}
