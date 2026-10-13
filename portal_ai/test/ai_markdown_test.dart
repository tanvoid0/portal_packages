import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portal_ai/src/widgets/ai_markdown.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

Widget _host(Widget child) => MaterialApp(
  theme: buildPortalTheme(brightness: Brightness.light),
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

void main() {
  testWidgets('code block shows its language and a Copy code button', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(const AiMarkdown(text: '```dart\nvar a = 1;\n```')),
    );
    expect(find.text('dart'), findsOneWidget);
    expect(find.byTooltip('Copy code'), findsOneWidget);
  });

  testWidgets('a markdown table renders as a Table', (tester) async {
    await tester.pumpWidget(
      _host(const AiMarkdown(text: '| a | b |\n|---|---|\n| 1 | 2 |')),
    );
    expect(find.byType(Table), findsOneWidget);
  });

}
