import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:portal_platform/portal_platform.dart';

/// The panel is one tile in four states, and the one that ships in every app
/// without an update service is the one nothing else exercises.
void main() {
  setUp(() {
    PackageInfo.setMockInitialValues(
      appName: 'Portal Gym',
      packageName: 'uk.aipairs.portal.gym',
      version: '1.3.0',
      buildNumber: '412',
      buildSignature: '',
    );
  });

  testWidgets('without a service it shows the build and stays inert',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: PortalUpdateTile(title: 'App version')),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('App version'), findsOneWidget);
    expect(find.text('1.3.0 (build 412)'), findsOneWidget);
    expect(
      find.text('Updates are not available in this build'),
      findsOneWidget,
    );
    // No check to run, so nothing offers one.
    expect(find.byIcon(Icons.refresh), findsNothing);
    expect(tester.widget<ListTile>(find.byType(ListTile)).onTap, isNull);
  });
}
