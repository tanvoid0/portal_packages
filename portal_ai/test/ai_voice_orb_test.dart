import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portal_ai/portal_ai.dart';

void main() {
  testWidgets('orb paints through every phase and types its label', (
    tester,
  ) async {
    final level = ValueNotifier<double>(0.7);
    for (final phase in AiVoicePhase.values) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AiVoiceOrb(phase: phase, level: level, label: 'Listening'),
          ),
        ),
      );
      // A few frames of animation: any NaN, empty gradient rect or bad path
      // throws here rather than on the phone.
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(tester.takeException(), isNull);
    }
    // Half a second at 18 chars a second is nine characters.
    expect(find.text('Listening'), findsNothing);
    expect(find.textContaining('Listen'), findsOneWidget);
    level.dispose();
  });
}
