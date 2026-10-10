import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portal_ai/src/widgets/ai_reply_foot.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

Widget _host(Widget child) => MaterialApp(
  theme: buildPortalTheme(brightness: Brightness.light),
  home: Scaffold(body: child),
);

void main() {
  testWidgets('writing names itself, waiting hands the turn back', (
    tester,
  ) async {
    // The shimmer repeats forever, so pump a frame rather than settle.
    await tester.pumpWidget(
      _host(const AiReplyFoot(status: AiReplyStatus.writing)),
    );
    await tester.pump();
    expect(find.text('Writing'), findsOneWidget);

    await tester.pumpWidget(
      _host(const AiReplyFoot(status: AiReplyStatus.waiting)),
    );
    await tester.pump();
    expect(find.text('Waiting for you'), findsOneWidget);
  });

  testWidgets('done offers copy, and regenerate only when it can', (
    tester,
  ) async {
    var copied = 0;
    await tester.pumpWidget(
      _host(
        AiReplyFoot(
          status: AiReplyStatus.done,
          onCopy: () => copied++,
          meta: '10:42',
        ),
      ),
    );
    expect(find.byTooltip('Regenerate reply'), findsNothing);
    expect(find.text('10:42'), findsOneWidget);
    await tester.tap(find.byTooltip('Copy reply'));
    expect(copied, 1);

    var regenerated = 0;
    await tester.pumpWidget(
      _host(
        AiReplyFoot(
          status: AiReplyStatus.done,
          onCopy: () {},
          onRegenerate: () => regenerated++,
        ),
      ),
    );
    await tester.tap(find.byTooltip('Regenerate reply'));
    expect(regenerated, 1);
  });

  testWidgets('failed shows the failure and Retry fires', (tester) async {
    var retried = 0;
    await tester.pumpWidget(
      _host(
        AiReplyFoot(
          status: AiReplyStatus.failed,
          failure: 'The model timed out.',
          onRetry: () => retried++,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('The model timed out.'), findsOneWidget);
    await tester.tap(find.text('Retry'));
    expect(retried, 1);
  });
}
