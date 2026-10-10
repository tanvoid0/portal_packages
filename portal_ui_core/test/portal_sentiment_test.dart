import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

void main() {
  // The one place the four-way scale maps to colour: prompt, progress, the kit
  // and amount tones all read through this, so pin the mapping here.
  testWidgets('base/onBase resolve to the semantic tokens', (t) async {
    late BuildContext ctx;
    await t.pumpWidget(MaterialApp(
      theme: buildPortalTheme(brightness: Brightness.light),
      home: Builder(builder: (c) {
        ctx = c;
        return const SizedBox();
      }),
    ));
    final sem = PortalSemanticColors.of(ctx);
    final cs = Theme.of(ctx).colorScheme;

    expect(PortalSentiment.positive.base(ctx), sem.success);
    expect(PortalSentiment.positive.onBase(ctx), sem.onSuccess);
    expect(PortalSentiment.warning.base(ctx), sem.warning);
    expect(PortalSentiment.warning.onBase(ctx), sem.onWarning);
    expect(PortalSentiment.negative.base(ctx), cs.error);
    expect(PortalSentiment.negative.onBase(ctx), cs.onError);
    expect(PortalSentiment.neutral.base(ctx), cs.onSurfaceVariant);
    expect(PortalSentiment.neutral.onBase(ctx), PortalUiTheme.of(ctx).card);
  });

  test('every sentiment carries a distinct glyph', () {
    final glyphs = PortalSentiment.values.map((s) => s.glyph).toSet();
    expect(glyphs.length, PortalSentiment.values.length);
  });
}
