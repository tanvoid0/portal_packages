import 'package:flutter/material.dart';

import '../theme/portal_ui_theme.dart';

/// Standard scrolling page: sliver app bar, gutter-aligned content, bottom
/// clearance for the floating nav, optional pull-to-refresh.
///
/// Extracted from portal_gym's `GymScrollPage`. Every screen that is "a title
/// and a column of things" should be this — the alternative is each screen
/// inventing its own padding, which is how the gutters drifted in the first
/// place.
class PortalScrollPage extends StatelessWidget {
  const PortalScrollPage({
    super.key,
    required this.children,
    this.title,
    this.appBar,
    this.actions,
    this.onRefresh,
    this.padding,
    this.backgroundColor,
    this.floatingActionButton,
    this.bottomNavigationBar,
  });

  /// Content slivers' children, laid out in a list under the app bar.
  final List<Widget> children;

  /// Title for the default sliver app bar. Ignored when [appBar] is given.
  final String? title;

  /// A custom sliver app bar. Supply this when the app dresses its own —
  /// it must be a sliver.
  final Widget? appBar;

  final List<Widget>? actions;

  /// Enables pull-to-refresh. Omit for a page that has nothing to refetch.
  final Future<void> Function()? onRefresh;

  /// Overrides the gutter/clearance padding. Defaults to
  /// `tokens.layout.pageHorizontal` and `tokens.layout.listBottomInset`.
  final EdgeInsets? padding;

  final Color? backgroundColor;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;

  @override
  Widget build(BuildContext context) {
    final portal = PortalUiTheme.of(context);
    final tokens = portal.tokens;
    final layout = tokens.layout;

    final bar = appBar ??
        (title == null
            ? null
            : SliverAppBar(
                pinned: true,
                title: Text(title!),
                actions: actions,
              ));

    final scroll = CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      slivers: [
        if (bar != null) bar,
        SliverPadding(
          padding: padding ??
              EdgeInsets.fromLTRB(
                layout.pageHorizontal,
                tokens.spacing.sm,
                layout.pageHorizontal,
                layout.listBottomInset,
              ),
          sliver: SliverList.list(children: children),
        ),
      ],
    );

    return Scaffold(
      backgroundColor: backgroundColor ?? portal.surface,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
      body: onRefresh == null
          ? scroll
          : RefreshIndicator(
              color: portal.primary,
              onRefresh: onRefresh!,
              child: scroll,
            ),
    );
  }
}
