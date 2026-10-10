import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portal_ai/src/chat/ai_chat_session.dart';
import 'package:portal_ai/src/widgets/ai_turn_bubble.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

const _turn = AiChatTurn(role: 'user', content: 'Add milk to the list');

Widget _host(Widget child) => MaterialApp(
  theme: buildPortalTheme(brightness: Brightness.light),
  home: Scaffold(body: child),
);

void main() {
  testWidgets('renders its content', (tester) async {
    await tester.pumpWidget(_host(const AiUserTurn(turn: _turn)));

    expect(find.text('Add milk to the list'), findsOneWidget);
    expect(find.text('Not sent'), findsNothing);
  });

  testWidgets('long-press opens Copy / Edit / Delete and wires them', (
    tester,
  ) async {
    var deleted = 0;
    await tester.pumpWidget(
      _host(
        AiUserTurn(
          turn: _turn,
          onCopy: () {},
          onEdit: () {},
          onDelete: () => deleted++,
        ),
      ),
    );

    await tester.longPress(find.text('Add milk to the list'));
    await tester.pumpAndSettle();

    expect(find.text('Copy'), findsOneWidget);
    expect(find.text('Edit'), findsOneWidget);
    expect(find.text('Delete'), findsOneWidget);

    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(deleted, 1);
    expect(find.text('Copy'), findsNothing);
  });

  testWidgets('notSent shows the prompt and Retry fires onRetry', (
    tester,
  ) async {
    var retried = 0;
    await tester.pumpWidget(
      _host(AiUserTurn(turn: _turn, notSent: true, onRetry: () => retried++)),
    );

    // The inline prompt pads its message with spaces before the action.
    expect(find.textContaining('Not sent'), findsOneWidget);

    await tester.tap(find.text('Retry'));
    expect(retried, 1);
  });

  testWidgets('day stamp reads Today for now', (tester) async {
    late String stamp;
    await tester.pumpWidget(
      _host(
        Builder(
          builder: (context) {
            stamp = aiDayStamp(context, DateTime.now());
            return AiDayStamp(label: stamp);
          },
        ),
      ),
    );

    expect(stamp, 'Today');
    expect(find.text('Today'), findsOneWidget);
  });
}
