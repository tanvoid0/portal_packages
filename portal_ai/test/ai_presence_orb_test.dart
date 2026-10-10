import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portal_ai/portal_ai.dart';

void main() {
  testWidgets('reduced motion renders a still frame with no ticker running', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: MediaQuery(
              data: const MediaQueryData(disableAnimations: true),
              child: const AiPresenceOrb(size: 48),
            ),
          ),
        ),
      ),
    );

    // pumpAndSettle hangs forever if any ticker is still running, so this
    // completing at all is the proof the orb never started one.
    await tester.pumpAndSettle();

    expect(find.byType(AiPresenceOrb), findsOneWidget);
  });
}
