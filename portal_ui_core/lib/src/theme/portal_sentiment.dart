import 'package:flutter/material.dart';

import 'portal_semantic_colors.dart';
import 'portal_ui_theme.dart';

/// The one four-way status scale shared across the kit: a value column, an
/// amount, a prompt, a meter all read as one of these. Never the only signal —
/// pair positive/negative with a sign or a glyph, so sentiment survives in
/// greyscale.
enum PortalSentiment { neutral, positive, warning, negative }

/// The colours and default glyph a [PortalSentiment] reads as. One source for
/// what [PortalPrompt], the kit, [portalBudgetSentiment] and amount tones all
/// used to re-derive by hand.
extension PortalSentimentColors on PortalSentiment {
  /// The sentiment's colour: glyph, badge disc, delta, meter fill.
  Color base(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final sem = PortalSemanticColors.of(context);
    return switch (this) {
      PortalSentiment.neutral => cs.onSurfaceVariant,
      PortalSentiment.positive => sem.success,
      PortalSentiment.warning => sem.warning,
      PortalSentiment.negative => cs.error,
    };
  }

  /// Ink on [base], e.g. a badge glyph.
  Color onBase(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final sem = PortalSemanticColors.of(context);
    return switch (this) {
      PortalSentiment.neutral => PortalUiTheme.of(context).card,
      PortalSentiment.positive => sem.onSuccess,
      PortalSentiment.warning => sem.onWarning,
      PortalSentiment.negative => cs.onError,
    };
  }

  /// The default glyph, a shape per sentiment so it reads without colour.
  IconData get glyph => switch (this) {
        PortalSentiment.neutral => Icons.info_outline,
        PortalSentiment.positive => Icons.check,
        PortalSentiment.warning => Icons.warning_amber_rounded,
        PortalSentiment.negative => Icons.priority_high,
      };
}
