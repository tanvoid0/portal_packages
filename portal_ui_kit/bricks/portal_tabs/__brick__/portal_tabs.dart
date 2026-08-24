import 'package:flutter/material.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

/// Tab labels and matching page bodies (shadcn Tabs).
class PortalTabs extends StatefulWidget {
  const PortalTabs({
    required this.tabs,
    required this.children,
    super.key,
    this.tabViewHeight = 200,
  }) : assert(tabs.length == children.length && tabs.length > 0);

  final List<String> tabs;
  final List<Widget> children;

  /// Height of the tab page area; [TabBarView] has no intrinsic height.
  final double tabViewHeight;

  @override
  State<PortalTabs> createState() => _PortalTabsState();
}

class _PortalTabsState extends State<PortalTabs> with SingleTickerProviderStateMixin {
  late final TabController _controller = TabController(length: widget.tabs.length, vsync: this);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final portal = PortalUiTheme.of(context);
    final t = portal.tokens;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        PortalThemedSurface(
          borderRadius: BorderRadius.circular(t.radii.md),
          borderSide: portal.borderSide(),
          child: TabBar(
            controller: _controller,
            labelColor: portal.onSurface,
            unselectedLabelColor: portal.onSurfaceVariant,
            indicator: UnderlineTabIndicator(
              borderSide: BorderSide(width: 2, color: portal.primary),
              insets: EdgeInsets.symmetric(horizontal: t.spacing.lg),
            ),
            tabs: [for (final tab in widget.tabs) Tab(text: tab)],
          ),
        ),
        SizedBox(height: t.spacing.md),
        SizedBox(
          height: widget.tabViewHeight,
          child: TabBarView(
            controller: _controller,
            children: widget.children,
          ),
        ),
      ],
    );
  }
}
