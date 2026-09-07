/// One turn in an assistant conversation.
///
/// [payload] is opaque to this package: the host app owns whatever it means
/// (portal_task puts its plan proposals there). Keeping it opaque is what lets
/// one session model serve every app without portal_ai knowing about tasks,
/// groceries or workouts.
class AiChatTurn {
  const AiChatTurn({
    required this.role,
    required this.content,
    this.summary,
    this.payload,
    this.at,
    this.took,
  });

  final String role;
  final String content;
  final String? summary;
  final Map<String, dynamic>? payload;

  /// When the turn was written. Null on threads saved before turns were
  /// stamped -- the UI just shows no time for those.
  final DateTime? at;

  /// How long the assistant took to produce this turn. Null on user turns.
  final Duration? took;

  bool get isUser => role == 'user';
  bool get isAssistant => role == 'assistant';

  AiChatTurn copyWith({
    String? content,
    String? summary,
    Map<String, dynamic>? payload,
    DateTime? at,
    Duration? took,
  }) {
    return AiChatTurn(
      role: role,
      content: content ?? this.content,
      summary: summary ?? this.summary,
      payload: payload ?? this.payload,
      at: at ?? this.at,
      took: took ?? this.took,
    );
  }
}

/// A persisted assistant thread.
///
/// App-specific fields live in [payload] rather than on the class, so adding a
/// new app does not widen this model. See [AiChatTurn] on why it is opaque.
class AiChatSession {
  const AiChatSession({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    required this.turns,
    this.summary = '',
    this.pinned = false,
    this.payload = const {},
  });

  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<AiChatTurn> turns;
  final String summary;

  /// Kept above the day groups in the history list.
  final bool pinned;

  final Map<String, dynamic> payload;

  AiChatSession copyWith({
    String? title,
    DateTime? updatedAt,
    List<AiChatTurn>? turns,
    String? summary,
    bool? pinned,
    Map<String, dynamic>? payload,
  }) {
    return AiChatSession(
      id: id,
      title: title ?? this.title,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      turns: turns ?? this.turns,
      summary: summary ?? this.summary,
      pinned: pinned ?? this.pinned,
      payload: payload ?? this.payload,
    );
  }
}

/// Lightweight row for a history sidebar.
class AiChatSessionSummary {
  const AiChatSessionSummary({
    required this.id,
    required this.title,
    required this.updatedAt,
    required this.turnCount,
    this.itemCount = 0,
    this.preview = '',
    this.pinned = false,
    this.searchText = '',
    this.payload = const {},
  });

  final String id;
  final String title;
  final DateTime updatedAt;
  final int turnCount;

  /// Host-defined count shown beside the title (proposals, items, ...).
  final int itemCount;

  /// The last thing said in the thread, for the list's second line. Empty
  /// falls back to the turn count, which is what a store written before this
  /// existed will keep reporting.
  final String preview;

  /// Sorted above everything else, in its own group.
  final bool pinned;

  /// Everything said in the thread, so search finds a thread by a line buried
  /// in it rather than only by its title and its last message. A store that
  /// leaves this empty still gets title-and-preview search.
  final String searchText;

  final Map<String, dynamic> payload;
}

/// Where assistant threads are persisted.
///
/// portal_ai deliberately ships no implementation: storage differs per app and
/// per platform, and taking a `get_storage` dependency here would force it on
/// every consumer. Apps supply their own.
abstract interface class AiChatStore {
  List<AiChatSessionSummary> listSummaries();

  AiChatSession? load(String id);

  Future<void> save(AiChatSession session);

  Future<void> delete(String id);
}

/// JSON for the shared session model.
///
/// Lives here rather than in each app: portal_task already had a codec for its
/// own copy, and the five apps that gain sessions should not each write another
/// one. Unknown keys in [AiChatTurn.payload] pass through untouched, which is
/// what lets a host keep its own data in a thread portal_ai persists.
extension AiChatTurnJson on AiChatTurn {
  Map<String, dynamic> toJson() => {
    'role': role,
    'content': content,
    if (summary != null) 'summary': summary,
    if (payload != null) 'payload': payload,
    if (at != null) 'at': at!.toIso8601String(),
    if (took != null) 'took_ms': took!.inMilliseconds,
  };
}

AiChatTurn aiChatTurnFromJson(Map<String, dynamic> json) => AiChatTurn(
  role: json['role'] as String? ?? 'assistant',
  content: json['content'] as String? ?? '',
  summary: json['summary'] as String?,
  payload: json['payload'] == null
      ? null
      : Map<String, dynamic>.from(json['payload'] as Map),
  at: DateTime.tryParse(json['at'] as String? ?? ''),
  took: json['took_ms'] == null
      ? null
      : Duration(milliseconds: json['took_ms'] as int),
);

extension AiChatSessionJson on AiChatSession {
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    'summary': summary,
    if (pinned) 'pinned': true,
    'payload': payload,
    'turns': turns.map((t) => t.toJson()).toList(),
  };
}

AiChatSession aiChatSessionFromJson(Map<String, dynamic> json) => AiChatSession(
  id: json['id'] as String,
  title: json['title'] as String? ?? '',
  createdAt: DateTime.parse(json['created_at'] as String),
  updatedAt: DateTime.parse(json['updated_at'] as String),
  summary: json['summary'] as String? ?? '',
  pinned: json['pinned'] as bool? ?? false,
  payload: Map<String, dynamic>.from(
    json['payload'] as Map? ?? const <String, dynamic>{},
  ),
  turns: (json['turns'] as List<dynamic>? ?? const [])
      .map((e) => aiChatTurnFromJson(Map<String, dynamic>.from(e as Map)))
      .toList(),
);
