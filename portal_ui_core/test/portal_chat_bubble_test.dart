import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

const _tokens = DesignTokens.defaults;

Widget _host(Widget child, {TextDirection direction = TextDirection.ltr}) {
  return MaterialApp(
    theme: buildPortalTheme(brightness: Brightness.light),
    home: Directionality(
      textDirection: direction,
      child: Scaffold(body: child),
    ),
  );
}

BorderRadius _bubbleRadius(WidgetTester t, TextDirection direction) {
  final box = t
      .widgetList<DecoratedBox>(
        find.descendant(
          of: find.byType(PortalChatBubble),
          matching: find.byType(DecoratedBox),
        ),
      )
      .first;
  final decoration = box.decoration as BoxDecoration;
  return decoration.borderRadius!.resolve(direction);
}

void main() {
  testWidgets('assistant bubble tails on the start corner, LTR', (t) async {
    await t.pumpWidget(_host(const PortalChatBubble(
      author: PortalChatAuthor.assistant,
      child: Text('hi'),
    )));
    final radius = _bubbleRadius(t, TextDirection.ltr);
    expect(radius.topLeft, Radius.circular(_tokens.radii.sm));
    expect(radius.topRight, Radius.circular(_tokens.radii.lg));
    expect(radius.bottomLeft, Radius.circular(_tokens.radii.lg));
    expect(radius.bottomRight, Radius.circular(_tokens.radii.lg));
  });

  testWidgets('user bubble tails on the end corner, LTR', (t) async {
    await t.pumpWidget(_host(const PortalChatBubble(
      author: PortalChatAuthor.user,
      child: Text('hi'),
    )));
    final radius = _bubbleRadius(t, TextDirection.ltr);
    expect(radius.bottomRight, Radius.circular(_tokens.radii.sm));
    expect(radius.topLeft, Radius.circular(_tokens.radii.lg));
    expect(radius.topRight, Radius.circular(_tokens.radii.lg));
    expect(radius.bottomLeft, Radius.circular(_tokens.radii.lg));
  });

  testWidgets('assistant tail follows the start edge under RTL too', (t) async {
    await t.pumpWidget(_host(
      const PortalChatBubble(
        author: PortalChatAuthor.assistant,
        child: Text('hi'),
      ),
      direction: TextDirection.rtl,
    ));
    // Start is the physical right under RTL -- the tail must follow it
    // rather than staying pinned to the left.
    final radius = _bubbleRadius(t, TextDirection.rtl);
    expect(radius.topRight, Radius.circular(_tokens.radii.sm));
    expect(radius.topLeft, Radius.circular(_tokens.radii.lg));
  });

  testWidgets('leading avatar only draws for the assistant turn', (t) async {
    await t.pumpWidget(_host(const PortalChatBubble(
      author: PortalChatAuthor.user,
      leading: Icon(Icons.smart_toy),
      child: Text('hi'),
    )));
    expect(find.byIcon(Icons.smart_toy), findsNothing);
  });

  testWidgets('footer renders under the bubble', (t) async {
    await t.pumpWidget(_host(const PortalChatBubble(
      author: PortalChatAuthor.assistant,
      footer: Text('09:14'),
      child: Text('hi'),
    )));
    expect(find.text('09:14'), findsOneWidget);
    expect(find.text('hi'), findsOneWidget);
  });
}
