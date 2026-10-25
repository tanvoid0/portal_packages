import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

double _ratio(Color a, Color b) {
  final hi = a.computeLuminance() > b.computeLuminance() ? a : b;
  final lo = identical(hi, a) ? b : a;
  return (hi.computeLuminance() + 0.05) / (lo.computeLuminance() + 0.05);
}

void main() {
  const page = Color(0xFFF4F4F5);

  Future<Color> offPage(WidgetTester t, Color fill) async {
    late Color out;
    await t.pumpWidget(MaterialApp(
      theme: buildPortalTheme(brightness: Brightness.light),
      home: Scaffold(
        backgroundColor: page,
        body: Builder(builder: (context) {
          out = portalOffPage(context, fill);
          return const SizedBox();
        }),
      ),
    ));
    return out;
  }

  testWidgets('a fill the colour of its page steps off it', (t) async {
    final out = await offPage(t, page);
    expect(out, isNot(page));
    expect(_ratio(out, page), greaterThanOrEqualTo(1.05));
  });

  testWidgets('a fill already clear of its page is left alone', (t) async {
    expect(await offPage(t, Colors.white), Colors.white);
  });

  testWidgets('a translucent fill is judged as it lands on the page',
      (t) async {
    // 50% of the page tone over the page is still the page.
    final out = await offPage(t, page.withValues(alpha: 0.5));
    expect(_ratio(out, page), greaterThanOrEqualTo(1.05));
  });

  test('ink on a runtime colour: preferred when it holds, else white or black',
      () {
    const violet = Color(0xFF7C3AED);
    expect(portalInkOn(violet, const Color(0xFF38265C)), Colors.white);
    expect(portalInkOn(violet, Colors.white), Colors.white);
    expect(portalInkOn(const Color(0xFFFFCA28), Colors.white), Colors.black);
  });
}
