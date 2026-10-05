import 'package:flutter/material.dart';

import '../theme/portal_ui_theme.dart';
import 'portal_app_bar.dart';
import 'portal_button_dock.dart';
import 'portal_refresh.dart';

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
    this.header,
    this.appBar,
    this.actions = const [],
    this.trailing,
    this.onRefresh,
    this.padding,
    this.backgroundColor,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.bottom,
  }) : assert(
          bottom == null || bottomNavigationBar == null,
          'a page has one bottom bar: pass bottom or bottomNavigationBar',
        );

  /// A [PortalButtonDock] (or any bar) pinned under the content. The dock
  /// draws its top rule only while content scrolls beneath it; this page
  /// tells it when.
  final Widget? bottom;

  /// Content slivers' children, laid out in a list under the app bar.
  final List<Widget> children;

  /// Title for the default [PortalSliverAppBar]. Ignored when [appBar] is given.
  final String? title;
  final String? subtitle;

  /// The large-title header — `PortalHeader.large(title: …)` — in place of
  /// the compact bar. Carries its own title and actions, so [title],
  /// [subtitle], [actions] and [trailing] are ignored when it is given.
  final PortalHeader? header;

  /// A custom sliver app bar. Supply this when the app dresses its own —
  /// it must be a sliver. Wins over [header].
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
        header ??
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

    Widget page(Widget Function(Widget) track) => Scaffold(
      backgroundColor: backgroundColor ?? portal.surface,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottom ?? bottomNavigationBar,
      body: onRefresh == null
          ? track(scroll)
          : PortalRefresh(
              onRefresh: onRefresh!,
              // Under the bar, not over it. A custom [appBar] is assumed
              // compact — the same offset the default bar gets.
              edgeOffset: bar == null
                  ? 0
                  : PortalRefresh.belowBar(context,
                      large: appBar == null && header != null),
              child: track(scroll),
            ),
    );

    return bottom == null
        ? page((scroll) => scroll)
        : _RuleHost(builder: page);
  }
}

/// Watches the page's scroll and tells a [PortalButtonDock] below it whether
/// content still runs beneath.
class _RuleHost extends StatefulWidget {
  const _RuleHost({required this.builder});

  final Widget Function(Widget Function(Widget scroll) track) builder;

  @override
  State<_RuleHost> createState() => _RuleHostState();
}

class _RuleHostState extends State<_RuleHost> {
  bool _rule = false;

  // ScrollMetricsNotification fires after layout, so a page that opens with
  // more content than fits shows its rule before the first drag.
  bool _onScroll(Notification n) {
    final metrics = switch (n) {
      ScrollNotification(depth: 0) => n.metrics,
      ScrollMetricsNotification(depth: 0) => n.metrics,
      _ => null,
    };
    if (metrics == null) return false;
    final rule = metrics.extentAfter > 0;
    if (rule != _rule) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _rule = rule);
      });
    }
    return false;
  }

  @override
  Widget build(BuildContext context) => PortalDockRule(
        showRule: _rule,
        child: widget.builder(
          (scroll) => NotificationListener<Notification>(
            onNotification: _onScroll,
            child: scroll,
          ),
        ),
      );
}
