import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portal_platform/src/auth/device_security/portal_pin_code_field.dart';

void main() {
  Widget host(TextEditingController controller, {int maxLength = 8}) =>
      MaterialApp(
        home: Scaffold(
          body: PortalPinCodeField(controller: controller, maxLength: maxLength),
        ),
      );

  testWidgets('renders one empty box per maxLength digit', (tester) async {
    final controller = TextEditingController();
    await tester.pumpWidget(host(controller, maxLength: 6));

    expect(find.byType(Container), findsNWidgets(6));
    expect(find.byIcon(Icons.circle), findsNothing);
  });

  testWidgets('typing fills boxes left to right, one icon per digit',
      (tester) async {
    final controller = TextEditingController();
    await tester.pumpWidget(host(controller, maxLength: 6));

    await tester.enterText(find.byType(TextField), '123');
    await tester.pump();

    expect(controller.text, '123');
    expect(find.byIcon(Icons.circle), findsNWidgets(3));
  });

  testWidgets('never accepts more digits than maxLength', (tester) async {
    final controller = TextEditingController();
    await tester.pumpWidget(host(controller, maxLength: 4));

    await tester.enterText(find.byType(TextField), '123456789');
    await tester.pump();

    expect(controller.text, '1234');
    expect(find.byIcon(Icons.circle), findsNWidgets(4));
  });

  testWidgets('non-digit input is filtered out', (tester) async {
    final controller = TextEditingController();
    await tester.pumpWidget(host(controller, maxLength: 6));

    await tester.enterText(find.byType(TextField), 'a1b2c3');
    await tester.pump();

    expect(controller.text, '123');
  });
}
