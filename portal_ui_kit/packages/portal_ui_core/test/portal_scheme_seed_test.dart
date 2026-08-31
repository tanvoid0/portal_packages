import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

/// The point of this helper is what it does *not* touch: an app adopting a
/// palette picker must not have its hand-tuned surfaces move underneath it.
void main() {
  const base = ColorScheme.dark(
    primary: Color(0xFFFF5A1F),
    onPrimary: Color(0xFF120A06),
    surface: Color(0xFF141210),
    onSurface: Color(0xFFF2EEEA),
    secondary: Color(0xFF34D399),
    error: Color(0xFFFF6B5A),
  );

  const seed = Color(0xFF7C3AED);

  test('leaves every non-primary role exactly as it was', () {
    final out = portalSchemeWithSeed(base, seed);

    expect(out.surface, base.surface);
    expect(out.onSurface, base.onSurface);
    expect(out.secondary, base.secondary);
    expect(out.error, base.error);
    expect(out.brightness, base.brightness);
  });

  test('replaces the primary family', () {
    final out = portalSchemeWithSeed(base, seed);

    expect(out.primary, isNot(base.primary));
    expect(out.primaryContainer, isNot(base.primaryContainer));
  });

  test('keeps the base brightness rather than the seed\'s', () {
    // A light seed must not quietly produce a light scheme on a dark app.
    final out = portalSchemeWithSeed(base, const Color(0xFFFFF176));
    expect(out.brightness, Brightness.dark);
    expect(out.surface, base.surface);
  });

  test('derives onPrimary rather than leaving the old one', () {
    // The failure this guards: setting `primary` alone and keeping the label
    // colour that was chosen for the *previous* accent, which is how a palette
    // picker ends up with unreadable buttons.
    final out = portalSchemeWithSeed(base, seed);
    expect(out.onPrimary, isNot(base.onPrimary));
  });
}
