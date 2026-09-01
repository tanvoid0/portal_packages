import 'dart:convert';

/// One action the assistant can take inside an app.
///
/// [parameters] maps an argument name to a short description shown to the
/// model. Keep names snake_case and descriptions one line — they are pasted
/// straight into the system prompt.
class AiTool {
  const AiTool({
    required this.name,
    required this.description,
    this.run,
    this.parameters = const {},
    this.mutates = false,
    this.namespace,
    this.runRich,
  }) : assert(
          run != null || runRich != null,
          'a tool needs run or runRich',
        );

  final String name;

  /// Owning app, e.g. `shopping`. Null for app-local tools.
  ///
  /// Bare names collide across apps -- `shopping.add_item` and
  /// `lifestyle.add_item` are different actions -- so anything that puts two
  /// apps' tools in front of one agent must qualify them.
  final String? namespace;

  /// [name] qualified by [namespace]: `shopping.add_item`.
  String get qualifiedName =>
      namespace == null ? name : '$namespace.$name';

  /// A copy of this tool owned by [ns].
  AiTool withNamespace(String ns) => AiTool(
        name: name,
        description: description,
        run: run,
        parameters: parameters,
        mutates: mutates,
        namespace: ns,
        runRich: runRich,
      );
  final String description;
  final Map<String, String> parameters;

  /// Whether running this tool changes user data (asks for confirmation).
  final bool mutates;

  /// Returns a short human-readable result fed back to the model. Null when
  /// [runRich] answers instead.
  final Future<String> Function(AiToolCall call)? run;

  /// Richer form of [run] that also returns blocks to render.
  ///
  /// Separate from [run] so text-only tools stay one-liners; when set it takes
  /// precedence.
  final Future<AiToolResult> Function(AiToolCall call)? runRich;

  /// Runs whichever of [runRich] or [run] this tool has.
  Future<AiToolResult> call(AiToolCall call) async {
    final rich = runRich;
    if (rich != null) return rich(call);
    return AiToolResult(forModel: await run!(call));
  }

  /// Single line describing this tool in the system prompt.
  String get spec {
    final args = parameters.entries
        .map((e) => '${e.key}: ${e.value}')
        .join('; ');
    return '- $qualifiedName(${args.isEmpty ? '' : args})'
        '${mutates ? ' [changes data]' : ''}: $description';
  }
}

/// A tool invocation requested by the model.
class AiToolCall {
  const AiToolCall(this.name, this.args);

  final String name;
  final Map<String, dynamic> args;

  String? argString(String key) {
    final value = args[key];
    if (value == null) return null;
    final text = value is String ? value.trim() : value.toString().trim();
    return text.isEmpty || text == 'null' ? null : text;
  }

  int? argInt(String key) {
    final value = args[key];
    if (value is num) return value.toInt();
    return int.tryParse(argString(key) ?? '');
  }

  double? argDouble(String key) {
    final value = args[key];
    if (value is num) return value.toDouble();
    return double.tryParse(argString(key) ?? '');
  }

  bool? argBool(String key) {
    final value = args[key];
    if (value is bool) return value;
    return switch (argString(key)?.toLowerCase()) {
      'true' || 'yes' || '1' => true,
      'false' || 'no' || '0' => false,
      _ => null,
    };
  }

  List<String> argStringList(String key) {
    final value = args[key];
    if (value is List) {
      return value.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList();
    }
    final raw = argString(key);
    if (raw == null) return const [];
    return raw.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
  }

  @override
  String toString() => '$name(${jsonEncode(args)})';
}

/// One completed step of an agent run.

/// A button on an [AiBlock].
///
/// [tool] is a namespaced name; tapping re-enters the agent at the tool-call
/// step, so a mutating tool still asks for confirmation exactly as it does
/// when the model calls it.
class AiAction {
  const AiAction({
    required this.label,
    required this.tool,
    this.args = const {},
  });

  final String label;
  final String tool;
  final Map<String, dynamic> args;

  Map<String, dynamic> toJson() =>
      {'label': label, 'tool': tool, 'args': args};

  factory AiAction.fromJson(Map<String, dynamic> json) => AiAction(
        label: json['label'] as String? ?? '',
        tool: json['tool'] as String? ?? '',
        args: Map<String, dynamic>.from(
          json['args'] as Map? ?? const <String, dynamic>{},
        ),
      );
}

/// Something the assistant shows the user, rendered by the host app.
///
/// JSON only: blocks are persisted inside a chat turn and must survive a
/// reload, so they hold data and not widgets. The host maps [kind] to a
/// builder; an unknown kind falls back to text rather than throwing, because
/// old threads outlive renderer renames.
class AiBlock {
  const AiBlock({
    required this.kind,
    this.data = const {},
    this.actions = const [],
  });

  /// The one kind the assistant draws itself, so a tool can return something
  /// visual without every app writing a renderer for it.
  static const itemsKind = 'items';

  /// Rows of image, title and subtitle: what a list-shaped tool result looks
  /// like in every app here.
  ///
  /// [entity] names what these rows are -- `recipe`, `grocery_item` -- so a
  /// host handling a tap knows which editor to open. The package never
  /// interprets it.
  factory AiBlock.items(
    List<AiItem> items, {
    String entity = '',
    List<AiAction> actions = const [],
  }) =>
      AiBlock(
        kind: itemsKind,
        data: {
          'items': [for (final item in items) item.toJson()],
          if (entity.isNotEmpty) 'entity': entity,
        },
        actions: actions,
      );

  /// What [items] are, for an [AiBlock.items] block. Empty when unset.
  String get entity => data['entity'] as String? ?? '';

  /// The rows of an [AiBlock.items], empty for any other kind.
  List<AiItem> get items {
    final raw = data['items'];
    if (raw is! List) return const [];
    return [
      for (final entry in raw)
        if (entry is Map) AiItem.fromJson(Map<String, dynamic>.from(entry)),
    ];
  }

  final String kind;
  final Map<String, dynamic> data;
  final List<AiAction> actions;

  Map<String, dynamic> toJson() => {
        'kind': kind,
        'data': data,
        'actions': actions.map((a) => a.toJson()).toList(),
      };

  factory AiBlock.fromJson(Map<String, dynamic> json) => AiBlock(
        kind: json['kind'] as String? ?? '',
        data: Map<String, dynamic>.from(
          json['data'] as Map? ?? const <String, dynamic>{},
        ),
        actions: (json['actions'] as List<dynamic>? ?? const [])
            .map((e) => AiAction.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
      );
}

/// One row of an [AiBlock.items].
///
/// [imageUrl] must be fetchable without an auth header — the renderer uses a
/// plain network image. Leave it null when the picture lives behind the app's
/// API and let the row fall back to its icon.
class AiItem {
  const AiItem({
    required this.title,
    this.id,
    this.subtitle = '',
    this.trailing = '',
    this.imageUrl,
    this.data = const {},
  });

  /// The record this row stands for. Null means the assistant is proposing
  /// something that does not exist yet, so a host opens its create form
  /// instead of its editor.
  final String? id;

  final String title;
  final String subtitle;

  /// Fields a host needs to prefill a create form for a row with no [id].
  /// Ignored for saved records, which the host loads by [id].
  final Map<String, dynamic> data;

  /// Right-aligned value: a price, a count, a date.
  final String trailing;
  final String? imageUrl;

  Map<String, dynamic> toJson() => {
        'title': title,
        if (id != null) 'id': id,
        if (subtitle.isNotEmpty) 'subtitle': subtitle,
        if (trailing.isNotEmpty) 'trailing': trailing,
        if (imageUrl != null && imageUrl!.isNotEmpty) 'image': imageUrl,
        if (data.isNotEmpty) 'data': data,
      };

  factory AiItem.fromJson(Map<String, dynamic> json) => AiItem(
        title: json['title'] as String? ?? '',
        id: json['id'] as String?,
        subtitle: json['subtitle'] as String? ?? '',
        trailing: json['trailing'] as String? ?? '',
        imageUrl: json['image'] as String?,
        data: Map<String, dynamic>.from(
          json['data'] as Map? ?? const <String, dynamic>{},
        ),
      );
}

/// What a tool hands back when it has something to show.
///
/// [forModel] is the short text fed into the next turn; [blocks] are for the
/// user. Blocks come from here and never from model output -- rendering
/// model-authored blocks would let injected text draw buttons wired to
/// mutating tools.
class AiToolResult {
  const AiToolResult({required this.forModel, this.blocks = const []});

  final String forModel;
  final List<AiBlock> blocks;
}

class AiAgentStep {
  const AiAgentStep({
    required this.call,
    required this.result,
    this.failed = false,
    this.blocks = const [],
  });

  final AiToolCall call;
  final String result;
  final bool failed;

  /// What the host should render for this step, if anything.
  final List<AiBlock> blocks;
}


/// Qualifies every tool in [tools] with [namespace].
///
/// Use at the point tools are handed to a runtime, so each app keeps writing
/// plain names and only the assembled set carries app ownership.
List<AiTool> namespacedTools(String namespace, List<AiTool> tools) =>
    tools.map((t) => t.withNamespace(namespace)).toList();

/// Resolves [name] against [tools].
///
/// Qualified names win. A bare name resolves only when exactly one tool has
/// it -- an ambiguous bare name returns null rather than a coin flip, because
/// shopping.add_item and lifestyle.add_item are different actions. Shared by
/// the agent and by action buttons so the two cannot drift apart.
AiTool? resolveTool(List<AiTool> tools, String name) {
  for (final tool in tools) {
    if (tool.qualifiedName == name) return tool;
  }
  final bare = tools.where((t) => t.name == name).toList();
  return bare.length == 1 ? bare.first : null;
}
