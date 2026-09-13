import 'package:flutter/material.dart';

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
