import 'package:flutter/material.dart';

import '../theme/portal_ui_theme.dart';
import 'portal_gutter_scope.dart';

/// A detail page's head: a mark, a caption, the page's one hero amount, its
/// delta, then a wrapping meta line with a status badge. Composed from
/// ui_core's own parts (typically [PortalIconTile.hero] for [mark],
/// `PortalAmount.text` at `PortalAmountSize.hero` for [amount],
/// `PortalAmountDelta.toned` for [delta] and [PortalBadge] for [badge]).
/// Ported from the design kit's `DetailHero`.
class PortalDetailHero extends StatelessWidget {
  const PortalDetailHero({
    super.key,
    this.mark,
    this.caption,
    required this.amount,
    this.delta,
    this.meta,
    this.badge,
  });

  /// A [PortalIconTile.hero], or a photo for recipe and lifestyle.
  final Widget? mark;
  final String? caption;

  /// A `PortalAmount.text` at `PortalAmountSize.hero`.
  final Widget amount;

  /// A `PortalAmountDelta.toned`.
  final Widget? delta;
  final String? meta;

  /// A [PortalBadge].
  final Widget? badge;

  @override
  Widget build(BuildContext context) {
    final t = PortalUiTheme.of(context).tokens;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final cap = t.textStyles.caption.copyWith(color: muted);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        PortalGutterScope.inset(context, t.spacing.lg),
        t.spacing.sm,
        PortalGutterScope.inset(context, t.spacing.lg),
        t.spacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: t.spacing.sm,
        children: [
          if (mark case final m?)
            Padding(padding: EdgeInsets.only(bottom: t.spacing.xs), child: m),
          if (caption case final c?) Text(c, style: cap),
          amount,
          if (delta case final d?) d,
          if (meta != null || badge != null)
            Wrap(
              spacing: t.spacing.md,
              runSpacing: t.spacing.sm,
              crossAxisAlignment: WrapCrossAlignment.end,
              children: [
                if (meta case final m?) Text(m, style: cap),
                if (badge case final b?) b,
              ],
            ),
        ],
      ),
    );
  }
}
