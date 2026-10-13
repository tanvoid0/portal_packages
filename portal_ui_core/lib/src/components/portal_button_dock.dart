import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../responsive/portal_breakpoints.dart';
import '../theme/portal_ui_theme.dart';
import 'portal_button.dart';
import 'portal_prompt.dart';

/// Tells a [PortalButtonDock] whether content scrolls beneath it. A
/// `PortalScrollPage(bottom:)` provides it; a dock outside one passes
/// `showRule` itself.
class PortalDockRule extends InheritedWidget {
  const PortalDockRule(
      {super.key, required this.showRule, required super.child});

  final bool showRule;

  static bool of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<PortalDockRule>()?.showRule ??
      false;

  @override
  bool updateShouldNotify(PortalDockRule old) => showRule != old.showRule;
}

/// Sticky bottom actions: a primary `PortalButton` (large) and an optional
/// secondary under it, full width, on the page's tone.
///
/// A 1 dp top rule shows only while content scrolls beneath it. Padding is
/// 12 16 32 at rest and drops to 12 at the bottom when the keyboard is open,
/// when the dock rides on top of it. Never inside a section card.
class PortalButtonDock extends StatelessWidget {
  const PortalButtonDock({
    super.key,
    required this.primary,
    this.secondary,
    this.showRule,
    this.inline = false,
  })  : actions = null,
        flexes = null,
        scrollable = false,
        columns = null;

  /// N equal actions in a grid instead of primary + secondary: [columns] to a
  /// row (default: all of them, at most 4), 8 apart, a short last row left
  /// aligned. Each is the caller's `PortalButton`.
  const PortalButtonDock.grid({
    super.key,
    required List<Widget> this.actions,
    this.columns,
    this.showRule,
    this.flexes,
    this.scrollable = false,
    this.inline = false,
  })  : primary = null,
        secondary = null;

  /// The dock a form saves from: a large primary [PortalButton] named [label],
  /// with an inline prompt over it while there is something to say. [errors]
  /// above zero says how many fields need fixing; otherwise [failed], once the
  /// save has come back, says why, with a Retry that calls [onSave] again - a
  /// failed save is never left looking like a success. While [saving] the
  /// button spins as [busyLabel] and refuses taps, and a stale [failed] is
  /// not shown. [secondary] sits under it as in the plain dock.
  factory PortalButtonDock.save({
    required String label,
    String? busyLabel,
    bool saving = false,
    int errors = 0,
    String? failed,
    VoidCallback? onSave,
    Widget? secondary,
  }) {
    assert(errors >= 0);
    final save = PortalButton(
      label: label,
      size: PortalButtonSize.lg,
      expand: true,
      isLoading: saving,
      busyLabel: busyLabel,
      onPressed: onSave,
    );
    final prompt = errors > 0
        ? PortalPrompt(
            size: PortalPromptSize.inline,
            sentiment: PortalSentiment.negative,
            message: errors == 1
                ? '1 field needs fixing before this saves.'
                : '$errors fields need fixing before this saves.',
          )
        : failed != null && !saving
            ? PortalPrompt(
                size: PortalPromptSize.inline,
                sentiment: PortalSentiment.negative,
                message: failed,
                action:
                    onSave == null ? null : (label: 'Retry', onPressed: onSave),
              )
            : null;
    return PortalButtonDock(
      primary: prompt == null
          ? save
          : Builder(
              builder: (context) => Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  prompt,
                  SizedBox(height: PortalUiTheme.of(context).tokens.spacing.md),
                  save,
                ],
              ),
            ),
      secondary: secondary,
    );
  }

  final Widget? primary;

  /// For a dock that sits inside a scroll body: no surface, no rule, no
  /// padding (the 12 16 32 above is for a pinned dock), so the body's own
  /// padding places it. [showRule] is ignored.
  final bool inline;

  /// Under the primary; a ghost or tonal `PortalButton`, 48 painted.
  final Widget? secondary;

  /// Overrides what an enclosing `PortalScrollPage` reports.
  final bool? showRule;

  final List<Widget>? actions;
  final int? columns;

  /// Per-action flex for [PortalButtonDock.grid], by index (default 1 each).
  /// Give the buttons `expand: true` so they fill their share.
  final List<int>? flexes;

  /// One row that scrolls sideways instead of wrapping: [columns] and
  /// [flexes] are ignored and each action takes its natural width.
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final gap = PortalUiTheme.of(context).tokens.spacing.sm;
    final children = actions != null
        ? _grid(actions!, gap)
        : [
            primary!,
            if (secondary != null) ...[
              SizedBox(height: gap),
              secondary!,
            ],
          ];
    if (inline) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      );
    }
    final portal = PortalUiTheme.of(context);
    final cs = Theme.of(context).colorScheme;
    final mq = MediaQuery.of(context);
    final keyboard = mq.viewInsets.bottom > 0;
    // 32 clears the gesture bar's own inset plus breathing room.
    final bottom = keyboard ? 12.0 : math.max(32.0, mq.viewPadding.bottom + 16);
    final rule = showRule ?? PortalDockRule.of(context);
    // On a wide window the surface spans full width but the actions centre at
    // the readable measure, lining up with the page content capped above.
    final side = portalContentSideInset(context, baseGutter: 16);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: portal.surface,
        border: Border(
          top: BorderSide(
            color: rule ? cs.outlineVariant : Colors.transparent,
            width: 1,
          ),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(side, 12, side, bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      ),
    );
  }

  List<Widget> _grid(List<Widget> items, double gap) {
    if (scrollable) {
      return [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: [
            for (var j = 0; j < items.length; j++) ...[
              if (j > 0) SizedBox(width: gap),
              items[j],
            ],
          ]),
        ),
      ];
    }
    final per = (columns ?? math.min(items.length, 4)).clamp(1, 1 << 20);
    final rows = <Widget>[];
    for (var i = 0; i < items.length; i += per) {
      if (rows.isNotEmpty) rows.add(SizedBox(height: gap));
      final chunk = items.skip(i).take(per).toList();
      rows.add(Row(children: [
        for (var j = 0; j < per; j++) ...[
          if (j > 0) SizedBox(width: gap),
          Expanded(
            flex: flexes != null && i + j < flexes!.length ? flexes![i + j] : 1,
            child: j < chunk.length ? chunk[j] : const SizedBox(),
          ),
        ],
      ]));
    }
    return rows;
  }
}
