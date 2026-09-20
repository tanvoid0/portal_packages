import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../theme/portal_surface_treatment.dart';
import '../theme/portal_ui_theme.dart';

/// One action in a [PortalAppBar].
///
/// The same object renders as an icon button while it fits inline and as a
/// labelled sheet row once it overflows, so [label] is required — it is the
/// tooltip in one place and the visible text in the other. A null [onPressed]
/// disables it in both.
class PortalAction {
  const PortalAction({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.destructive = false,
    this.badge = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  /// Drawn in the destructive colour in the sheet, never inline — a red icon
  /// in the bar reads as an error state, not an affordance.
  final bool destructive;

  /// Small dot on the icon: "something changed here".
  final bool badge;
}

/// The fleet's title bar: title, optional one-line subtitle, back button when
/// there is somewhere to go back to, and actions that overflow into a bottom
/// sheet instead of a `more_vert` popup.
///
/// Compact on purpose — `kToolbarHeight` with or without a subtitle, title at
/// `typeScale.xl` rather than the theme's 22sp `titleLarge`. Replaces the
/// seven per-app bars that all had this shape (`ModernAppBar` ×2,
/// `GymThemedAppBar`, recipe's inline `SliverAppBar`s, ...).
///
/// [actions] up to [maxInline] show as icon buttons. Past that the first
/// `maxInline - 1` stay inline and the rest move to a "More" button that
/// opens [showPortalActionSheet] — labelled rows with thumb-sized targets,
/// which is what a phone user actually wants from an overflow.
///
/// [trailing] is the escape hatch for a widget that is not an action — a
/// search field, a sync indicator, a progress ring. It renders before the
/// actions and is never overflowed.
///
/// A title that changes — `Obx(() => Text(c.name.value))`, an emoji + text
/// row — goes in [titleWidget]; the bar applies its compact style over it via
/// `DefaultTextStyle`, so a plain `Text` inside inherits the right type.
/// Reactive actions: wrap the `Scaffold` in `Obx`, or use [trailing].
class PortalAppBar extends StatelessWidget implements PreferredSizeWidget {
  const PortalAppBar({
    super.key,
    this.title,
    this.titleWidget,
    this.subtitle,
    this.leading,
    this.actions = const [],
    this.trailing,
    this.maxInline = 2,
    this.centerTitle,
    this.backgroundColor,
    this.bottom,
  }) : assert((title == null) != (titleWidget == null),
            'Give exactly one of title or titleWidget');

  final String? title;

  /// Any widget in the title slot — reactive or composite. Styled by the bar.
  final Widget? titleWidget;

  /// Breadcrumb or context line under the title ("Wardrobe", "3 of 12").
  final String? subtitle;

  /// Overrides the automatic back button.
  final Widget? leading;

  final List<PortalAction> actions;
  final List<Widget>? trailing;

  /// Icon buttons the bar will show before overflowing. Two is the default
  /// because three plus a title plus a back button is already tight at 360dp.
  final int maxInline;

  final bool? centerTitle;
  final Color? backgroundColor;

  /// Tabs or a filter row hung under the bar.
  final PreferredSizeWidget? bottom;

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: _PortalAppBarTitle(
        title: title,
        titleWidget: titleWidget,
        subtitle: subtitle,
        centerTitle: centerTitle,
      ),
      leading: leading,
      centerTitle: centerTitle,
      backgroundColor: backgroundColor,
      bottom: bottom,
      actions: _barActions(
        context,
        actions: actions,
        trailing: trailing,
        maxInline: maxInline,
      ),
    );
  }
}

/// [PortalAppBar] as a pinned sliver, for `CustomScrollView` pages.
///
/// [expandedHeight] + [flexibleSpace] are for the one shape a compact bar
/// cannot be — a hero image that collapses into the title. Everything else
/// stays `kToolbarHeight`.
class PortalSliverAppBar extends StatelessWidget {
  const PortalSliverAppBar({
    super.key,
    this.title,
    this.titleWidget,
    this.subtitle,
    this.leading,
    this.actions = const [],
    this.trailing,
    this.maxInline = 2,
    this.centerTitle,
    this.backgroundColor,
    this.bottom,
    this.pinned = true,
    this.floating = false,
    this.expandedHeight,
    this.flexibleSpace,
  }) : assert((title == null) != (titleWidget == null),
            'Give exactly one of title or titleWidget');

  final String? title;
  final Widget? titleWidget;
  final String? subtitle;
  final Widget? leading;
  final List<PortalAction> actions;
  final List<Widget>? trailing;
  final int maxInline;
  final bool? centerTitle;
  final Color? backgroundColor;
  final PreferredSizeWidget? bottom;
  final bool pinned;
  final bool floating;
  final double? expandedHeight;
  final Widget? flexibleSpace;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      pinned: pinned,
      floating: floating,
      snap: floating,
      expandedHeight: expandedHeight,
      flexibleSpace: flexibleSpace,
      title: _PortalAppBarTitle(
        title: title,
        titleWidget: titleWidget,
        subtitle: subtitle,
        centerTitle: centerTitle,
      ),
      leading: leading,
      centerTitle: centerTitle,
      backgroundColor: backgroundColor,
      bottom: bottom,
      actions: _barActions(
        context,
        actions: actions,
        trailing: trailing,
        maxInline: maxInline,
      ),
    );
  }
}

List<Widget> _barActions(
  BuildContext context, {
  required List<PortalAction> actions,
  List<Widget>? trailing,
  int maxInline = 2,
}) {
  final overflows = actions.length > maxInline;
  final inline = overflows ? actions.take(maxInline - 1) : actions;
  final overflow =
      overflows ? actions.skip(maxInline - 1).toList() : <PortalAction>[];

  return [
    ...?trailing,
    for (final a in inline) _ActionButton(action: a),
    if (overflow.isNotEmpty)
      IconButton(
        tooltip: 'More',
        icon: Badge(
          isLabelVisible: overflow.any((a) => a.badge),
          smallSize: 8,
          child: const Icon(Icons.more_horiz),
        ),
        onPressed: () => showPortalActionSheet(context, overflow),
      ),
  ];
}

/// Bottom sheet of labelled actions. Used by the bar's overflow; also fine
/// for a card's long-press menu, so it is public.
Future<void> showPortalActionSheet(
  BuildContext context,
  List<PortalAction> actions, {
  String? title,
}) {
  final portal = PortalUiTheme.of(context);
  final tokens = portal.tokens;
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheet) => SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title != null)
            Padding(
              padding: EdgeInsets.fromLTRB(
                tokens.layout.pageHorizontal,
                0,
                tokens.layout.pageHorizontal,
                tokens.spacing.sm,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  title,
                  style: tokens.textStyles.overline
                      .copyWith(color: portal.onSurfaceVariant),
                ),
              ),
            ),
          for (final a in actions)
            ListTile(
              enabled: a.onPressed != null,
              leading: Icon(
                a.icon,
                color: a.destructive ? portal.destructive : null,
              ),
              title: Text(
                a.label,
                style: a.destructive
                    ? TextStyle(color: portal.destructive)
                    : null,
              ),
              trailing: a.badge
                  ? Badge(smallSize: 8, backgroundColor: portal.primary)
                  : null,
              onTap: a.onPressed == null
                  ? null
                  : () {
                      Navigator.of(sheet).pop();
                      a.onPressed!();
                    },
            ),
          SizedBox(height: tokens.spacing.sm),
        ],
      ),
    ),
  );
}

class _PortalAppBarTitle extends StatelessWidget {
  const _PortalAppBarTitle({
    this.title,
    this.titleWidget,
    this.subtitle,
    this.centerTitle,
  });

  final String? title;
  final Widget? titleWidget;
  final String? subtitle;
  final bool? centerTitle;

  @override
  Widget build(BuildContext context) {
    final portal = PortalUiTheme.of(context);
    final tokens = portal.tokens;
    final titleStyle = tokens.textStyles.title.copyWith(
      fontSize: tokens.typeScale.xl,
      color: portal.onSurface,
    );
    final titleText = DefaultTextStyle.merge(
      style: titleStyle,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      child: titleWidget ?? Text(title!),
    );
    if (subtitle == null) return titleText;

    final centered =
        centerTitle ?? Theme.of(context).appBarTheme.centerTitle ?? false;
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment:
          centered ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        titleText,
        Text(
          subtitle!,
          style: tokens.textStyles.caption.copyWith(
            fontSize: tokens.typeScale.sm,
            color: portal.onSurfaceVariant,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.action});

  final PortalAction action;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: action.label,
      onPressed: action.onPressed,
      icon: Badge(
        isLabelVisible: action.badge,
        smallSize: 8,
        child: Icon(action.icon),
      ),
    );
  }
}

/// The fleet's large-title header: a page title at `textStyles.headline`
/// that collapses into the compact [PortalSliverAppBar] shape as the page
/// scrolls, with what scrolls under the collapsed bar blurred through it.
///
/// Built on [SliverAppBar.large] — Material owns the collapse, the
/// cross-fade and the pinned toolbar. This adds the Portal type on both ends
/// of the collapse, the fleet's [PortalAction] overflow, and the glass: the
/// bar's background is the theme's bar colour at [PortalGlassStyle.tintAlpha]
/// over a [PortalGlassStyle.blurSigma] backdrop blur. The navigation layer is
/// the one surface that is glass on every visual theme, so nothing inside it
/// (a [PortalCard] in [trailing], say) should be glass again.
///
/// A sliver: hand it to [PortalScrollPage.header] or put it first in a
/// `CustomScrollView`. `scrolledUnderElevation` is 0 — the blur is the
/// scrolled-under signal.
class PortalHeader extends StatelessWidget {
  const PortalHeader.large({
    super.key,
    required this.title,
    this.subtitle,
    this.actions = const [],
    this.trailing,
  });

  final String title;

  /// Context line under the title. Shown large under the expanded title and
  /// compact under the collapsed one, like [PortalAppBar.subtitle].
  final String? subtitle;

  /// Overflow past two into the action sheet. See [PortalAppBar.actions].
  final List<PortalAction> actions;

  /// Non-action widgets before the actions. See [PortalAppBar.trailing].
  final List<Widget>? trailing;

  /// Height at rest, above the status bar — M3's large bar. Passed to the
  /// sliver rather than left to Material's private default so
  /// `PortalRefresh.belowBar` can measure against it.
  static const double expandedHeight = 152;

  @override
  Widget build(BuildContext context) {
    final portal = PortalUiTheme.of(context);
    final theme = Theme.of(context);
    final glass =
        portal.glassStyle ?? PortalGlassStyle.forBrightness(theme.brightness);
    // Absolute alpha, so a glass visual theme that already frosts
    // appBarTheme.backgroundColor is not frosted twice.
    final tint = (theme.appBarTheme.backgroundColor ?? portal.surface)
        .withValues(alpha: glass.tintAlpha);

    return _SliverBackdropBlur(
      sigma: glass.blurSigma,
      child: SliverAppBar.large(
        // Collapse to the fleet's 56, not M3's 64: `.large` derives its
        // pinned extent from a constant, not from toolbarHeight, so both go.
        toolbarHeight: kToolbarHeight,
        collapsedHeight: MediaQuery.paddingOf(context).top + kToolbarHeight,
        expandedHeight: expandedHeight,
        backgroundColor: tint,
        scrolledUnderElevation: 0,
        title: _LargeTitle(title: title, subtitle: subtitle),
        actions: _barActions(context, actions: actions, trailing: trailing),
      ),
    );
  }
}

class _LargeTitle extends StatelessWidget {
  const _LargeTitle({required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    // SliverAppBar.large builds this same widget twice — once in the
    // toolbar, once in the expanded flexible space — and styles both from
    // one titleTextStyle, so the widget has to tell the slots apart itself.
    // The toolbar copy sits inside Material's NavigationToolbar; the
    // expanded copy is a Stack sibling of it.
    final collapsed =
        context.findAncestorWidgetOfExactType<NavigationToolbar>() != null;
    if (collapsed) return _PortalAppBarTitle(title: title, subtitle: subtitle);

    final portal = PortalUiTheme.of(context);
    final styles = portal.tokens.textStyles;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: styles.headline.copyWith(color: portal.onSurface),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (subtitle != null)
          Text(
            subtitle!,
            style: styles.body.copyWith(color: portal.onSurfaceVariant),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
      ],
    );
  }
}

/// [BackdropFilter] for a sliver child: blurs whatever is painted under it.
/// Flutter ships no sliver equivalent, and a box [BackdropFilter] cannot wrap
/// a [SliverAppBar].
class _SliverBackdropBlur extends SingleChildRenderObjectWidget {
  const _SliverBackdropBlur({required this.sigma, required Widget super.child});

  final double sigma;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderSliverBackdropBlur(sigma);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderSliverBackdropBlur renderObject,
  ) =>
      renderObject.sigma = sigma;
}

class _RenderSliverBackdropBlur extends RenderProxySliver {
  _RenderSliverBackdropBlur(this._sigma);

  double _sigma;
  set sigma(double value) {
    if (value == _sigma) return;
    _sigma = value;
    markNeedsPaint();
  }

  // A handle keeps the layer alive across frames; a bare field would be
  // disposed with the clip layer's children the first time it is rebuilt.
  final _backdrop = LayerHandle<BackdropFilterLayer>(BackdropFilterLayer());

  @override
  bool get alwaysNeedsCompositing => child != null;

  @override
  void dispose() {
    _backdrop.layer = null;
    super.dispose();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child == null || !geometry!.visible) return;
    // A backdrop layer blurs everything inside the nearest clip, which here
    // would be the whole viewport — clip it to the bar first.
    layer = context.pushClipRect(
      needsCompositing,
      offset,
      paintBounds,
      (context, offset) {
        final backdrop = _backdrop.layer!
          ..filter = ImageFilter.blur(sigmaX: _sigma, sigmaY: _sigma);
        context.pushLayer(backdrop, super.paint, offset);
      },
      oldLayer: layer as ClipRectLayer?,
    );
  }
}
