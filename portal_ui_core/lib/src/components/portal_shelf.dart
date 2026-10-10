import 'package:flutter/material.dart';

import '../theme/portal_ui_theme.dart';
import 'portal_section_header.dart';

/// A catalogue shelf: an optional [header] over a sideways-scrolling row of
/// fixed-width cards.
///
/// Promoted from the demo kit's `KitShelf`; replaces the hand-built
/// `SizedBox > ListView(horizontal) > SizedBox(width, card)` in the apps. The
/// cards stay app-side — pass them as [children] and they are sized to
/// [itemWidth]. Gutter is `layout.pageHorizontal`, gap defaults to
/// `spacing.md`. Compute a responsive [itemWidth] in a `LayoutBuilder`.
class PortalShelf extends StatelessWidget {
  const PortalShelf({
    super.key,
    this.header,
    required this.children,
    required this.itemWidth,
    this.height,
    this.gap,
    this.trailing,
    this.padding,
  });

  /// Section title above the row, drawn by [PortalSectionHeader].
  final String? header;
  final List<Widget> children;

  /// Width of each child. [trailing] sizes itself.
  final double itemWidth;

  /// Row height. Set, children are laid out inside it with a bounded cross
  /// axis (so one may use `Expanded`); null, the row is as tall as its tallest
  /// child.
  final double? height;

  /// Between items; defaults to `spacing.md`.
  final double? gap;

  /// A last cell after the children — an "add" chip, a shuffle.
  final Widget? trailing;

  /// Leading/trailing padding around the row (and header). Null uses the page
  /// gutter (`layout.pageHorizontal`); pass `EdgeInsets.zero` when the shelf
  /// sits inside an already-padded parent so it is not double-inset.
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final tokens = PortalUiTheme.of(context).tokens;
    final gutter = padding ??
        EdgeInsets.symmetric(horizontal: tokens.layout.pageHorizontal);
    final between = gap ?? tokens.spacing.md;
    final items = <Widget>[
      for (final c in children) SizedBox(width: itemWidth, child: c),
      if (trailing != null) trailing!,
    ];

    // A ListView needs a bounded height; without one, size to content.
    // Gaps are interleaved by hand, not Row.spacing — this package's SDK floor
    // is Dart 3.3 and Row.spacing needs Flutter 3.27.
    final spaced = <Widget>[
      for (var i = 0; i < items.length; i++) ...[
        if (i > 0) SizedBox(width: between),
        items[i],
      ],
    ];
    final row = height == null
        ? SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: gutter,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: spaced,
            ),
          )
        : SizedBox(
            height: height,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: gutter,
              itemCount: items.length,
              itemBuilder: (_, i) => items[i],
              separatorBuilder: (_, __) => SizedBox(width: between),
            ),
          );

    if (header == null) return row;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: gutter,
          child: PortalSectionHeader(title: header!),
        ),
        SizedBox(height: tokens.spacing.sm),
        row,
      ],
    );
  }
}
