import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/rendering.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

void main() {
  const long = 'A very long value that cannot possibly fit beside a title';

  // G1: the value is capped at 45% of the row.
  const cap = .45;

  Widget host(Widget child,
          {double width = 360, TextDirection dir = TextDirection.ltr}) =>
      MaterialApp(
        theme: buildPortalTheme(brightness: Brightness.light),
        builder: (_, w) => Directionality(textDirection: dir, child: w!),
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(width: width, child: child),
          ),
        ),
      );

  // The row's content box is the width less 16 padding a side.
  const inner = 360.0 - 32;

  // Width the text would take unclamped, to tell a clipped title from a whole one.
  double natural(WidgetTester t, String text) {
    final style = t.widget<Text>(find.text(text)).style;
    return (TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout())
        .width;
  }

  testWidgets('a long value is capped at 45% and ellipsizes; the title is whole',
      (t) async {
    for (final acc in [
      const PortalListAccessory.value(long),
      const PortalListAccessory.navigate(value: long),
      PortalListAccessory.valueAndAction(long,
          icon: Icons.check, tooltip: 'Mark paid', onPressed: () {}),
    ]) {
      await t.pumpWidget(host(PortalListItem(
        title: 'Provider',
        trailing: acc,
      )));
      expect(t.takeException(), isNull);
      expect(t.getSize(find.text(long)).width, lessThanOrEqualTo(inner * cap));
      expect(t.widget<Text>(find.text(long)).overflow, TextOverflow.ellipsis);
      // The long value alone is wider than the whole row; the title still
      // gets its natural width, unclipped.
      expect(natural(t, long), greaterThan(inner));
      final title = t.renderObject<RenderParagraph>(find.text('Provider'));
      expect(title.didExceedMaxLines, isFalse);
      expect(t.getSize(find.text('Provider')).width,
          greaterThanOrEqualTo(natural(t, 'Provider')));
    }
  });

  testWidgets('a short value keeps its natural width; the title still expands',
      (t) async {
    await t.pumpWidget(host(const PortalListItem(
      title: 'Theme',
      trailing: PortalListAccessory.value('586 MB'),
    )));
    final value = t.getRect(find.text('586 MB'));
    expect(value.width, lessThan(inner * cap));
    // Right-aligned to the content edge, title at the start, and the title
    // (Expanded) fills everything the value and the 12 gap leave.
    expect(value.right, closeTo(16 + inner, .5));
    expect(t.getRect(find.text('Theme')).left, 16);
    final column = find
        .ancestor(of: find.text('Theme'), matching: find.byType(Column))
        .first;
    expect(t.getSize(column).width, closeTo(inner - 12 - value.width, .5));
    // Natural width: the unconstrained paragraph size.
    final p = TextPainter(
      text: TextSpan(
          text: '586 MB',
          style: t.widget<Text>(find.text('586 MB')).style),
      textDirection: TextDirection.ltr,
    )..layout();
    expect(value.width, closeTo(p.width, .5));
  });

  testWidgets('a control accessory is not capped', (t) async {
    await t.pumpWidget(host(PortalListItem(
      title: 'T',
      trailing: PortalListAccessory.button(label: 'Update all now', onPressed: () {}),
    )));
    // The button label is wider than 45% of the row: controls are exempt.
    expect(t.getSize(find.text('Update all now')).width,
        greaterThan(inner * cap));
  });

  testWidgets('RTL: the title takes the start (right) side, the value the left',
      (t) async {
    await t.pumpWidget(host(
      PortalListItem(
        title: 'Provider',
        leading: PortalListLeading.icon(Icons.home),
        trailing: const PortalListAccessory.value(long),
      ),
      dir: TextDirection.rtl,
    ));
    expect(t.takeException(), isNull);
    final value = t.getRect(find.text(long));
    final title = t.getRect(find.text('Provider'));
    expect(value.left, closeTo(16, .5));
    expect(value.width, lessThanOrEqualTo(inner * cap));
    expect(title.left, greaterThan(value.right));
    expect(title.right, lessThan(360 - 16));
  });

  testWidgets('a reason top-aligns the value; otherwise it is centred',
      (t) async {
    await t.pumpWidget(host(const PortalListItem(
      title: 'Provider',
      disabledReason: 'Sign in first',
      trailing: PortalListAccessory.value('586 MB'),
    )));
    expect(t.getRect(find.text('586 MB')).top,
        closeTo(t.getRect(find.text('Provider')).top, .5));
    await t.pumpWidget(host(const PortalListItem(
      title: 'Provider',
      subtitle: 'Subtitle',
      trailing: PortalListAccessory.value('586 MB'),
    )));
    final row = t.getRect(find.byType(PortalListItem));
    final value = t.getRect(find.text('586 MB'));
    expect(value.center.dy, closeTo(row.center.dy, 1));
    expect(value.top, greaterThan(t.getRect(find.text('Provider')).top));
  });

  testWidgets('inside IntrinsicWidth and an AlertDialog it does not throw',
      (t) async {
    await t.pumpWidget(host(const IntrinsicWidth(
      child: PortalListItem(
        title: 'AI provider',
        trailing: PortalListAccessory.navigate(value: 'Portal Cloud'),
      ),
    )));
    expect(t.takeException(), isNull);
    await t.pumpWidget(host(const IntrinsicHeight(
      child: PortalListItem(
        title: 'On-device model',
        trailing: PortalListAccessory.value('586 MB'),
      ),
    )));
    expect(t.takeException(), isNull);

    await t.pumpWidget(MaterialApp(
      theme: buildPortalTheme(brightness: Brightness.light),
      home: const Scaffold(
        body: AlertDialog(
          content: PortalListItem(
            title: 'AI provider',
            trailing: PortalListAccessory.navigate(value: 'Portal Cloud'),
          ),
        ),
      ),
    ));
    expect(t.takeException(), isNull);
    expect(find.text('Portal Cloud'), findsOneWidget);
  });
}
