import 'package:flutter/material.dart';

import '../responsive/portal_breakpoints.dart';
import '../theme/portal_ui_theme.dart';
import 'portal_app_bar.dart';
import 'portal_button_dock.dart';
import 'portal_refresh.dart';
import 'portal_gutter_scope.dart';

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
    this.controller,
    this.titleWidget,
    this.leading,
    this.count,
    this.status,
    this.statusIcon,
    this.grouped = false,
  })  : body = null,
        assert(
          bottom == null || bottomNavigationBar == null,
          'a page has one bottom bar: pass bottom or bottomNavigationBar',
        ),
        assert(
          title == null || titleWidget == null,
          'give a title or a titleWidget, not both',
        );

  /// For a page that owns its own scroll (chat, an active workout, a
  /// timeline) — the same bar, dock and nav/fab clearance, over [body]
  /// instead of a sliver list of [children].
  const PortalScrollPage.custom({
    super.key,
    required Widget this.body,
    this.title,
    this.subtitle,
    this.header,
    this.appBar,
    this.actions = const [],
    this.trailing,
    this.backgroundColor,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.bottom,
    this.titleWidget,
    this.leading,
    this.count,
    this.status,
    this.statusIcon,
    this.grouped = false,
  })  : children = const [],
        onRefresh = null,
        padding = null,
        controller = null,
        assert(
          bottom == null || bottomNavigationBar == null,
          'a page has one bottom bar: pass bottom or bottomNavigationBar',
        ),
        assert(
          title == null || titleWidget == null,
          'give a title or a titleWidget, not both',
        );

  /// A [PortalButtonDock] (or any bar) pinned under the content. The dock
  /// draws its top rule only while content scrolls beneath it; this page
  /// tells it when.
  final Widget? bottom;

  /// Drives the page's scroll view (jump to the new row, remember the
  /// offset). The caller owns and disposes it.
  final ScrollController? controller;

  /// Content slivers' children, laid out in a list under the app bar.
  final List<Widget> children;

  /// Title for the default [PortalSliverAppBar]. Ignored when [appBar] is given.
  final String? title;
  final String? subtitle;

  /// In place of [title] in the default bar -- a model switcher, say -- and
  /// centred. A control rather than the page's heading is the caller's to
  /// name.
  final Widget? titleWidget;

  /// Replaces the default bar's automatic back button (centred in its slot).
  final Widget? leading;

  /// A count and/or a one-line status under the default bar's title
  /// (`12 items · Synced just now`), muted, a polite live region. [statusIcon]
  /// leads the line. A bar has a [subtitle] or this, not both.
  // ponytail: the bar draws one status line, so [count] joins it as text with
  // no tabular figures and the icon leads the whole line; split them if a
  // second app wants the icon between the two.
  final String? count;
  final String? status;
  final IconData? statusIcon;

  /// `.scr.grouped`: in light the page (and its default bar) steps one tone
  /// under `portal.card` -- `surfaceContainerHigh` -- so inset sections read;
  /// dark keeps the scaffold. [backgroundColor] wins.
  final bool grouped;

  /// The large-title header — `PortalHeader.large(title: …)` — in place of
  /// the compact bar. Carries its own title and actions, so [title],
  /// [subtitle], [actions] and [trailing] are ignored when it is given.
  final PortalHeader? header;

  /// A custom app bar. Supply this when the app dresses its own — it must
  /// be a sliver for the default constructor, or a [PreferredSizeWidget]
  /// (a regular bar) for [PortalScrollPage.custom]. Wins over [header].
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

  /// [PortalScrollPage.custom]'s own-scroll body, in place of [children].
  final Widget? body;

  /// A tab page inside a shell that extends its body under a floating nav
  /// (`Scaffold.extendBody`, as [PortalTabShell] and the hand-built shells
  /// do) sees MediaQuery padding grown by the nav's height, but Scaffold
  /// places a FAB by viewPadding, which does not grow — so the FAB sat under
  /// the pill. Lift it by the difference; a pushed page, a page with its own
  /// nav, or one with the keyboard up gets zero.
  Widget? _clearShellNav(BuildContext context, Widget? fab) {
    if (fab == null || (bottom ?? bottomNavigationBar) != null) return fab;
    final lift = MediaQuery.paddingOf(context).bottom -
        MediaQuery.viewPaddingOf(context).bottom -
        MediaQuery.viewInsetsOf(context).bottom;
    return lift > 0
        ? Padding(padding: EdgeInsets.only(bottom: lift), child: fab)
        : fab;
  }

  @override
  Widget build(BuildContext context) {
    final portal = PortalUiTheme.of(context);
    final tokens = portal.tokens;
    final layout = tokens.layout;

    final theme = Theme.of(context);
    final pageColor = backgroundColor ??
        (grouped && theme.brightness == Brightness.light
            ? theme.colorScheme.surfaceContainerHigh
            : null);
    final statusLine =
        [count, status].where((s) => s != null && s.isNotEmpty).join(' · ');
    final fab = _clearShellNav(context, floatingActionButton);

    if (body case final body?) {
      // A regular (non-sliver) bar: [body] owns its own scroll, so there is
      // no sliver list for a [PortalSliverAppBar] to sit above.
      final customBar = appBar ??
          (title == null && titleWidget == null
              ? null
              : PortalAppBar(
                  title: title,
                  titleWidget: titleWidget,
                  subtitle: subtitle,
                  status: statusLine.isEmpty ? null : statusLine,
                  statusIcon: statusIcon,
                  leading: leading,
                  centerTitle: titleWidget == null ? null : true,
                  backgroundColor: grouped ? pageColor : null,
                  actions: actions,
                  trailing: trailing,
                ));
      assert(
        customBar == null || customBar is PreferredSizeWidget,
        '.custom has a regular (non-sliver) bar: give a PreferredSizeWidget '
        'appBar, not a sliver one',
      );
      Widget page(Widget Function(Widget) track) => Scaffold(
            backgroundColor: pageColor ?? portal.surface,
            appBar: customBar as PreferredSizeWidget?,
            floatingActionButton: fab,
            // Scaffold reserves the body's height above it automatically —
            // the same clearance [children]'s SliverPadding bakes in by hand.
            bottomNavigationBar: bottom ?? bottomNavigationBar,
            body: track(body),
          );
      return bottom == null ? page((b) => b) : _RuleHost(builder: page);
    }

    final bar = appBar ??
        header ??
        (title == null && titleWidget == null
            ? null
            : PortalSliverAppBar(
                title: title,
                titleWidget: titleWidget,
                subtitle: subtitle,
                status: statusLine.isEmpty ? null : statusLine,
                statusIcon: statusIcon,
                leading: leading,
                centerTitle: titleWidget == null ? null : true,
                // Only a grouped page tints its bar: a plain page's bar keeps
                // the theme's, whatever [backgroundColor] says.
                backgroundColor: grouped ? pageColor : null,
                actions: actions,
                trailing: trailing,
              ));

    final scroll = CustomScrollView(
      controller: controller,
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      slivers: [
        if (bar != null) bar,
        SliverPadding(
          padding: padding ??
              _contentPadding(
                context,
                baseGutter: layout.pageHorizontal,
                top: tokens.spacing.sm,
                bottom: layout.listBottomInset,
              ),
          sliver: SliverList.list(children: children),
        ),
      ],
    );

    // The default padding is the page gutter; say so, so what sits on it does
    // not add a second one (see [PortalGutterScope]).
    final guttered = PortalGutterScope(applied: padding == null, child: scroll);

    Widget page(Widget Function(Widget) track) => Scaffold(
          backgroundColor: pageColor ?? portal.surface,
          floatingActionButton: fab,
          bottomNavigationBar: bottom ?? bottomNavigationBar,
          body: onRefresh == null
              ? track(guttered)
              : PortalRefresh(
                  onRefresh: onRefresh!,
                  // Under the bar, not over it. A custom [appBar] is assumed
                  // compact — the same offset the default bar gets.
                  edgeOffset: bar == null
                      ? 0
                      : PortalRefresh.belowBar(context,
                          large: appBar == null && header != null),
                  child: track(guttered),
                ),
        );

    return bottom == null ? page((scroll) => scroll) : _RuleHost(builder: page);
  }
}

/// Page gutter that grows with the window and, past the readable column cap,
/// turns the extra width into a centred margin so content never stretches.
EdgeInsets _contentPadding(
  BuildContext context, {
  required double baseGutter,
  required double top,
  required double bottom,
}) {
  final side = portalContentSideInset(context, baseGutter: baseGutter);
  return EdgeInsets.fromLTRB(side, top, side, bottom);
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
