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
    required this.run,
    this.parameters = const {},
    this.mutates = false,
  });

  final String name;
  final String description;
  final Map<String, String> parameters;

  /// Whether running this tool changes user data (asks for confirmation).
  final bool mutates;

  /// Returns a short human-readable result fed back to the model.
  final Future<String> Function(AiToolCall call) run;

  /// Single line describing this tool in the system prompt.
  String get spec {
    final args = parameters.entries
        .map((e) => '${e.key}: ${e.value}')
        .join('; ');
    return '- $name(${args.isEmpty ? '' : args})'
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
class AiAgentStep {
  const AiAgentStep({required this.call, required this.result, this.failed = false});

  final AiToolCall call;
  final String result;
  final bool failed;
}
