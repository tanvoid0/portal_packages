import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

void main() {
  testWidgets(
    'a toast with an action renders in a host mounted outside the Overlay',
    (tester) async {
      // The app-shell placement: the host is a sibling of the Navigator in
      // MaterialApp.builder, so nothing above it provides an Overlay.
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => Stack(
            children: [child!, const PortalToastHost()],
          ),
          home: const Scaffold(body: SizedBox.expand()),
        ),
      );

      AppToast.show(
        'Removed Broccolini',
        actionLabel: 'Undo',
        onAction: () {},
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(tester.takeException(), isNull);
      expect(find.text('Undo'), findsOneWidget);

      AppToast.dismiss();
      await tester.pump(const Duration(milliseconds: 300));
    },
  );
}
