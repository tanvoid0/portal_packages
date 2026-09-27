import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portal_ui_core/kit_export.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

/// Writes docs/ui-kit/data/tokens.json; skipped unless KIT_EXPORT_DIR is set.
/// Run through scripts/export-kit-data.sh.
void main() {
  test('exports tokens.json', () {
    final icons = buildPortalTheme(brightness: Brightness.light).iconTheme;
    final json = {
      'generatedBy': 'packages/portal_ui_core/test/kit_export_test.dart',
      'default': kitTokens(DesignTokens.defaults),
      'presets': {
        for (final p in PortalDesignTokenPresets.all)
          if (p.id != PortalDesignTokenPresets.defaultPreset.id)
            p.id: kitTokens(p.tokens),
      },
      // Material Symbols axes every glyph inherits from the icon theme.
      'icons': {
        'fontFamily': PortalIcons.home_rounded.fontFamily,
        'fill': icons.fill,
        'weight': icons.weight,
        'grade': icons.grade,
        'opticalSize': icons.opticalSize,
      },
    };
    File('$kitExportDir/tokens.json')
      ..createSync(recursive: true)
      ..writeAsStringSync(kitJson(json));
  }, skip: kitExportDir.isEmpty);
}
