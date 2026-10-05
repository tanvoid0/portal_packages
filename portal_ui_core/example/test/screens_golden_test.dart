import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portal_ui_core/portal_ui_core.dart';
import 'package:portal_ui_core_example/screens.dart';

/// G6: the G5 reference screens in light and dark at 1.0 and 1.3 text scale,
/// with the real typeface loaded (no Ahem boxes). A token change shows what
/// it did: `flutter test --update-goldens`, then read the diff in the PNGs.
void main() {
  setUpAll(() async {
    final loader = FontLoader('packages/portal_ui_core/PlusJakartaSans');
    for (final w in ['Regular', 'Medium', 'SemiBold', 'Bold', 'ExtraBold']) {
      final bytes = File('../assets/fonts/PlusJakartaSans-$w.ttf').readAsBytesSync();
      loader.addFont(Future.value(ByteData.sublistView(bytes)));
    }
    await loader.load();

    // Icon fonts too, or every glyph is a tofu box.
    Future<void> load(String family, String path) async {
      final l = FontLoader(family)
        ..addFont(Future.value(ByteData.sublistView(File(path).readAsBytesSync())));
      await l.load();
    }

    final sdk = Platform.environment['FLUTTER_ROOT']!;
    await load('MaterialIcons', '$sdk/bin/cache/artifacts/material_fonts/materialicons-regular.otf');
    final cfg = jsonDecode(File('.dart_tool/package_config.json').readAsStringSync()) as Map;
    final symbols = (cfg['packages'] as List)
        .cast<Map>()
        .firstWhere((p) => p['name'] == 'material_symbols_icons')['rootUri'] as String;
    await load(
      'packages/material_symbols_icons/MaterialSymbolsRounded',
      '${Uri.parse(symbols).toFilePath()}/lib/fonts/MaterialSymbolsRounded.ttf',
    );
  });

  const screens = <String, Widget>{
    'transactions': TransactionsScreen(),
    'settings': SettingsScreen(),
    'form': EditFormScreen(),
    'result': ResultDemoScreen(),
  };

  for (final entry in screens.entries) {
    for (final dark in [false, true]) {
      for (final scale in [1.0, 1.3]) {
        final name = '${entry.key}_${dark ? 'dark' : 'light'}_$scale';
        testWidgets('golden: $name', (t) async {
          t.view
            ..physicalSize = const Size(412, 892)
            ..devicePixelRatio = 1;
          addTearDown(t.view.reset);
          final config = PortalThemeConfig(tokens: designTokensForPreset(PortalUiPreset.defaultPreset));
          await t.pumpWidget(MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: dark ? config.dark() : config.light(),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
              child: child!,
            ),
            home: entry.value,
          ));
          await t.pump(const Duration(seconds: 1));
          await expectLater(
            find.byType(MaterialApp),
            matchesGoldenFile('goldens/$name.png'),
          );
        });
      }
    }
  }
}
