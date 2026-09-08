import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portal_ai/portal_ai.dart';

/// The face the header and every assistant bubble draw, so counting it counts
/// avatars. A host-supplied avatar is the only handle a test has on them --
/// the avatar widget itself is private to the page.
const _face = Icon(Icons.face, key: ValueKey('face'));

Future<void> _pump(WidgetTester tester, List<AiChatTurn> turns) =>
    tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AiAssistantPage(
            avatar: _face,
            turns: turns,
            onSend: (_) async {},
          ),
        ),
      ),
    );

/// One face in the header, plus one per group of assistant replies.
int _faces() => find.byIcon(Icons.face).evaluate().length;

void main() {
  testWidgets('a run of replies draws one face, against its last bubble', (
    tester,
  ) async {
    await _pump(tester, const [
      AiChatTurn(role: 'user', content: 'plan my week'),
      AiChatTurn(role: 'assistant', content: 'Monday is clear.'),
      AiChatTurn(role: 'assistant', content: 'Tuesday is not.'),
    ]);

    // Header + one for the run of two replies.
    expect(_faces(), 2);
  });

  testWidgets('a question between replies starts a new run', (tester) async {
    await _pump(tester, const [
      AiChatTurn(role: 'user', content: 'plan my week'),
      AiChatTurn(role: 'assistant', content: 'Monday is clear.'),
      AiChatTurn(role: 'user', content: 'and Tuesday?'),
      AiChatTurn(role: 'assistant', content: 'Tuesday is not.'),
    ]);

    // Header + one per run.
    expect(_faces(), 3);
  });

  testWidgets('the face sits on the last reply, not the first', (tester) async {
    await _pump(tester, const [
      AiChatTurn(role: 'user', content: 'plan my week'),
      AiChatTurn(role: 'assistant', content: 'first'),
      AiChatTurn(role: 'assistant', content: 'last'),
    ]);

    // Both bubbles keep the same left edge -- the suppressed face leaves a
    // gutter behind it -- so the face is placed by which bubble shares its
    // row, not by where the text starts.
    final face = tester.getCenter(
      find
          .descendant(
            of: find.byType(Row),
            matching: find.byKey(const ValueKey('face')),
          )
          .last,
    );
    expect(face.dy, greaterThan(tester.getCenter(find.text('first')).dy));
    expect(
      (face.dy - tester.getCenter(find.text('last')).dy).abs(),
      lessThan(24),
    );
  });
}
