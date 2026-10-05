import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

void main() {
  testWidgets('error: headline, fix, retry in the dock, Close in the bar',
      (t) async {
    var retried = false, closed = false;
    await t.pumpWidget(MaterialApp(
      theme: buildPortalTheme(brightness: Brightness.light),
      home: PortalResultScreen(
        state: PortalResultState.error,
        title: 'Payment not sent',
        body: 'Check your connection, then try again.',
        onClose: () => closed = true,
        dock: PortalButtonDock(
          primary: PortalButton(label: 'Retry', onPressed: () => retried = true),
        ),
      ),
    ));
    expect(find.text('Payment not sent'), findsOneWidget);
    await t.tap(find.text('Retry'));
    await t.tap(find.byTooltip('Close'));
    expect(retried && closed, isTrue);
  });
}
