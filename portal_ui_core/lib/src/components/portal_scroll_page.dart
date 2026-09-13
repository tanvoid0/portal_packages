import 'package:flutter/material.dart';

import '../theme/portal_ui_theme.dart';
import 'portal_app_bar.dart';

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
    this.subtitle,
    this.appBar,
    this.actions = const [],
    this.trailing,
    this.onRefresh,
    this.padding,
    this.backgroundColor,
    this.floatingActionButton,
    this.bottomNavigationBar,
  });

  /// Content slivers' children, laid out in a list under the app bar.
  final List<Widget> children;

  /// Title for the default [PortalSliverAppBar]. Ignored when [appBar] is given.
  final String? title;
  final String? subtitle;

  /// A custom sliver app bar. Supply this when the app dresses its own —
  /// it must be a sliver.
  final Widget? appBar;

  /// Actions for the default bar; overflow past two into the action sheet.
  final List<PortalAction> actions;

  /// Non-action widgets in the bar (search, sync dot). See [PortalAppBar].
  final List<Widget>? trailing;

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
            : PortalSliverAppBar(
                title: title!,
                subtitle: subtitle,
                actions: actions,
                trailing: trailing,
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
