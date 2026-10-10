import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

void main() {
  Widget host(Widget child) => MaterialApp(
        theme: buildPortalTheme(brightness: Brightness.light),
        home: Scaffold(
          body: Padding(padding: const EdgeInsets.all(16), child: child),
        ),
      );

  TextInputAction? action(WidgetTester t) =>
      t.widget<TextField>(find.byType(TextField)).textInputAction;

  testWidgets('single-line with no action defaults to Next', (t) async {
    await t.pumpWidget(host(const PortalTextField(label: 'Name')));
    expect(action(t), TextInputAction.next);
  });

  testWidgets('an explicit action wins; multi-line keeps the default',
      (t) async {
    await t.pumpWidget(host(
      const PortalTextField(textInputAction: TextInputAction.done),
    ));
    expect(action(t), TextInputAction.done);

    await t.pumpWidget(host(const PortalTextField(maxLines: 3)));
    expect(action(t), isNull);
  });

  testWidgets('warning renders under the field; an error replaces it',
      (t) async {
    await t.pumpWidget(host(
      const PortalTextField(helper: 'Helper', warning: 'Looks high'),
    ));
    expect(find.text('Looks high'), findsOneWidget);
    expect(find.text('Helper'), findsNothing);

    await t.pumpWidget(host(
      const PortalTextField(warning: 'Looks high', errorText: 'Required'),
    ));
    expect(find.text('Required'), findsOneWidget);
    expect(find.text('Looks high'), findsNothing);
  });
}
