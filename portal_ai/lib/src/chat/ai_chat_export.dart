import 'dart:convert';

import 'ai_chat_session.dart';

/// The whole conversation plus the context needed to judge it, as JSON.
///
/// Exists so a transcript can be handed to a person (or another model) who is
/// tuning the prompt: the turns alone say what the assistant answered, but not
/// what it was told to do or what it was allowed to call. [systemPrompt] and
/// [toolSpecs] carry that. Turn payloads (blocks, thinking, model, tokens) come
/// through untouched, which is what makes the previews reviewable.
String aiChatExportJson({
  required String app,
  required List<AiChatTurn> turns,
  required DateTime at,
  String? systemPrompt,
  List<String> toolSpecs = const [],
  String? title,
}) =>
    const JsonEncoder.withIndent('  ').convert({
      'app': app,
      'exported_at': at.toIso8601String(),
      if (title != null && title.isNotEmpty) 'title': title,
      'system_prompt': ?systemPrompt,
      if (toolSpecs.isNotEmpty) 'tools': toolSpecs,
      'turns': [for (final turn in turns) turn.toJson()],
    });

/// The same conversation as something a person reads: the transcript in
/// markdown, ready to paste into a note or an issue.
///
/// The JSON export is for tuning a prompt; this one is for showing someone
/// what the assistant said. No system prompt, no tool specs, no payloads --
/// just who said what, and when the turn knows.
String aiChatExportMarkdown({
  required String app,
  required List<AiChatTurn> turns,
  required DateTime at,
  String? title,
}) {
  final buffer = StringBuffer()
    ..writeln('# ${title == null || title.isEmpty ? app : title}')
    ..writeln()
    ..writeln('_$app - ${at.toIso8601String()}_');
  for (final turn in turns) {
    final content = turn.content.trim();
    if (content.isEmpty) continue;
    buffer
      ..writeln()
      ..writeln('**${turn.isUser ? 'You' : 'Assistant'}**')
      ..writeln()
      ..writeln(content);
  }
  return buffer.toString();
}
