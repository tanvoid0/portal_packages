import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

/// One swipe action for [PortalSlidable].
///
/// Requires `flutter_slidable` in your app's `pubspec.yaml`.
class PortalSlidableAction {
  const PortalSlidableAction({
    required this.label,
    required this.onPressed,
    this.icon,
    this.backgroundColor,
    this.foregroundColor,
    this.flex = 1,
    this.isDestructive = false,
  });

  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final int flex;
  final bool isDestructive;
}

/// Swipeable row with themed action panes (shadcn-adjacent list interaction).
class PortalSlidable extends StatelessWidget {
  const PortalSlidable({
    required this.child,
    super.key,
    this.startActions = const [],
    this.endActions = const [],
  });

  final Widget child;
  final List<PortalSlidableAction> startActions;
  final List<PortalSlidableAction> endActions;

  @override
  Widget build(BuildContext context) {
    final portal = PortalUiTheme.of(context);

    return Slidable(
      key: key,
      startActionPane: startActions.isEmpty
          ? null
          : ActionPane(
              motion: const DrawerMotion(),
              children: [
                for (final action in startActions)
                  _buildAction(context, portal, action),
              ],
            ),
      endActionPane: endActions.isEmpty
          ? null
          : ActionPane(
              motion: const DrawerMotion(),
              children: [
                for (final action in endActions)
                  _buildAction(context, portal, action),
              ],
            ),
      child: child,
    );
  }

  SlidableAction _buildAction(
    BuildContext context,
    PortalUiTheme portal,
    PortalSlidableAction action,
  ) {
    final bg = action.backgroundColor ??
        (action.isDestructive ? portal.destructive : portal.primary);
    final fg = action.foregroundColor ??
        (action.isDestructive ? portal.onDestructive : portal.onPrimary);

    return SlidableAction(
      onPressed: (_) => action.onPressed(),
      backgroundColor: bg,
      foregroundColor: fg,
      icon: action.icon,
      label: action.label,
      flex: action.flex,
    );
  }
}
