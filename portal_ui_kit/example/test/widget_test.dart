import 'package:flutter_test/flutter_test.dart';

import 'package:portal_ui_kit_example/portal_docs_app.dart';

void main() {
  testWidgets('docs app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const PortalDocsApp());
    await tester.pumpAndSettle();

    expect(find.text('Portal UI Kit'), findsWidgets);
    expect(find.text('Overview'), findsOneWidget);
  });
}
