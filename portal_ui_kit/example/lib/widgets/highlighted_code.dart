import 'package:flutter/material.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/atom-one-dark.dart';
import 'package:flutter_highlight/themes/github.dart';
import 'package:highlight/highlight.dart' show highlight;
import 'package:highlight/languages/bash.dart';
import 'package:highlight/languages/dart.dart';

bool _languagesRegistered = false;

void _ensureLanguagesRegistered() {
  if (_languagesRegistered) return;
  highlight.registerLanguage('dart', dart);
  highlight.registerLanguage('bash', bash);
  _languagesRegistered = true;
}

/// Read-only code block with syntax highlighting.
class HighlightedCode extends StatelessWidget {
  const HighlightedCode({
    super.key,
    required this.code,
    this.language = 'dart',
    this.textStyle,
    this.scrollVertically = false,
  });

  final String code;
  final String language;
  final TextStyle? textStyle;
  final bool scrollVertically;

  @override
  Widget build(BuildContext context) {
    _ensureLanguagesRegistered();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Map<String, TextStyle>.from(
      isDark ? atomOneDarkTheme : githubTheme,
    );
    final root = theme['root'];
    if (root != null) {
      theme['root'] = root.copyWith(backgroundColor: Colors.transparent);
    }
    final baseStyle = textStyle ??
        Theme.of(context).textTheme.bodySmall?.copyWith(
              fontFamily: 'monospace',
              height: 1.45,
            ) ??
        const TextStyle(fontFamily: 'monospace', fontSize: 13, height: 1.45);

    Widget view = HighlightView(
      code,
      language: language,
      theme: theme,
      padding: EdgeInsets.zero,
      textStyle: baseStyle,
    );

    if (scrollVertically) {
      view = SingleChildScrollView(child: view);
    }

    return SelectionArea(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: view,
      ),
    );
  }
}
