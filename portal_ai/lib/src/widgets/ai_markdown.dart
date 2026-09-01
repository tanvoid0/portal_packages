import 'package:flutter/material.dart';
import 'package:markdown_widget/markdown_widget.dart';

/// Assistant prose, rendered as markdown.
///
/// Models emit `**bold**` and bullet lists whether or not you ask them to, and
/// as plain text those read as literal asterisks. Sized and coloured from the
/// host's theme so a reply looks like it belongs to the app around it.
class AiMarkdown extends StatelessWidget {
  const AiMarkdown({super.key, required this.text, this.style});

  final String text;

  /// Base style for body text. Defaults to the theme's `bodyMedium`.
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final body = (style ?? theme.textTheme.bodyMedium ?? const TextStyle())
        .copyWith(height: 1.45);
    // Plain text is the common case -- a sentence or two. Skip the block
    // parser for it so the usual reply stays a single Text.
    if (!_looksLikeMarkdown(text)) return Text(text, style: body);
    return MarkdownBlock(
      data: text,
      selectable: false,
      config: MarkdownConfig(
        configs: [
          PConfig(textStyle: body),
          H1Config(
            style: theme.textTheme.titleMedium ?? body,
          ),
          H2Config(style: theme.textTheme.titleSmall ?? body),
          H3Config(style: theme.textTheme.titleSmall ?? body),
          ListConfig(marginLeft: 16),
          CodeConfig(
            style: body.copyWith(
              fontFamily: 'monospace',
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
            ),
          ),
          PreConfig(
            textStyle: body.copyWith(fontFamily: 'monospace'),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          LinkConfig(style: body.copyWith(color: theme.colorScheme.primary)),
          HrConfig(color: theme.colorScheme.outlineVariant),
        ],
      ),
    );
  }

  /// Cheap check for the markers worth running the parser over.
  static bool _looksLikeMarkdown(String text) {
    return text.contains('**') ||
        text.contains('`') ||
        text.contains('](') ||
        RegExp(r'(^|\n)\s*([*\-+]\s|\d+\.\s|#{1,6}\s|>\s)').hasMatch(text);
  }
}
