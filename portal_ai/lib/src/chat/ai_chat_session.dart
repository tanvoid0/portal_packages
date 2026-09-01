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
  });

  final String role;
  final String content;
  final String? summary;
  final Map<String, dynamic>? payload;

  bool get isUser => role == 'user';
  bool get isAssistant => role == 'assistant';

  AiChatTurn copyWith({
    String? content,
    String? summary,
    Map<String, dynamic>? payload,
  }) {
    return AiChatTurn(
      role: role,
      content: content ?? this.content,
      summary: summary ?? this.summary,
      payload: payload ?? this.payload,
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
    this.payload = const {},
  });

  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<AiChatTurn> turns;
  final String summary;
  final Map<String, dynamic> payload;

  AiChatSession copyWith({
    String? title,
    DateTime? updatedAt,
    List<AiChatTurn>? turns,
    String? summary,
    Map<String, dynamic>? payload,
  }) {
    return AiChatSession(
      id: id,
      title: title ?? this.title,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      turns: turns ?? this.turns,
      summary: summary ?? this.summary,
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
    this.payload = const {},
  });

  final String id;
  final String title;
  final DateTime updatedAt;
  final int turnCount;

  /// Host-defined count shown beside the title (proposals, items, ...).
  final int itemCount;

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
      };
}

AiChatTurn aiChatTurnFromJson(Map<String, dynamic> json) => AiChatTurn(
      role: json['role'] as String? ?? 'assistant',
      content: json['content'] as String? ?? '',
      summary: json['summary'] as String?,
      payload: json['payload'] == null
          ? null
          : Map<String, dynamic>.from(json['payload'] as Map),
    );

extension AiChatSessionJson on AiChatSession {
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
        'summary': summary,
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
      payload: Map<String, dynamic>.from(
        json['payload'] as Map? ?? const <String, dynamic>{},
      ),
      turns: (json['turns'] as List<dynamic>? ?? const [])
          .map((e) => aiChatTurnFromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
