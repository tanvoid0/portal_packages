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

  Future<double> right(WidgetTester t, String md, String cell) async {
    await t.pumpWidget(_host(AiMarkdown(text: md)));
    return t.getTopRight(find.text(cell)).dx;
  }

  Future<double> left(WidgetTester t, String md, String cell) async {
    await t.pumpWidget(_host(AiMarkdown(text: md)));
    return t.getTopLeft(find.text(cell)).dx;
  }

  testWidgets('numeric columns right-align, text columns left-align', (
    tester,
  ) async {
    const md =
        '| item | cost |\n|---|---|\n| tea | \$5 |\n| cake | \$1,200.50 |';
    expect(
      await right(tester, md, r'$5'),
      await right(tester, md, r'$1,200.50'),
    );
    expect(await left(tester, md, 'tea'), await left(tester, md, 'cake'));
  });

  testWidgets('a mixed column stays left-aligned', (tester) async {
    const md = '| a | b |\n|---|---|\n| x | 1 |\n| y | n/a long |';
    expect(await left(tester, md, '1'), await left(tester, md, 'n/a long'));
  });

  testWidgets('delimiter alignment wins, header included', (tester) async {
    const md = '| name | qty |\n|:---|---:|\n| a | 1 |\n| bbbbbb | 2 |';
    expect(await right(tester, md, 'qty'), await right(tester, md, '2'));
    const forced = '| name | qty |\n|---:|:---|\n| a | 1 |\n| bbbbbb | 2 |';
    expect(
      await right(tester, forced, 'a'),
      await right(tester, forced, 'bbbbbb'),
    );
    expect(await left(tester, forced, '1'), await left(tester, forced, '2'));
  });
}
