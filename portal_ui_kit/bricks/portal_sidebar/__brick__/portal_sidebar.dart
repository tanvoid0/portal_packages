import 'package:flutter/material.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

class PortalSidebarItem {
  const PortalSidebarItem({
    required this.label,
    this.icon,
    this.badge,
  });

  final String label;
  final IconData? icon;
  final String? badge;
}

/// Vertical navigation rail with themed surface (shadcn Sidebar).
class PortalSidebar extends StatelessWidget {
  const PortalSidebar({
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
    super.key,
    this.header,
    this.footer,
    this.width = 240,
  });

  final List<PortalSidebarItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final Widget? header;
  final Widget? footer;
  final double width;

  @override
  Widget build(BuildContext context) {
    final portal = PortalUiTheme.of(context);
    final t = portal.tokens;

    return PortalThemedSurface(
      color: portal.card,
      borderRadius: BorderRadius.circular(t.radii.lg),
      child: SizedBox(
        width: width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (header != null) ...[
              Padding(
                padding: EdgeInsets.all(t.spacing.lg),
                child: header!,
              ),
              Divider(height: 1, color: portal.subtleBorderSide().color),
            ],
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.symmetric(
                  horizontal: t.spacing.sm,
                  vertical: t.spacing.md,
                ),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  final selected = index == selectedIndex;
                  return _SidebarTile(
                    item: item,
                    selected: selected,
                    onTap: () => onSelected(index),
                  );
                },
              ),
            ),
            if (footer != null) ...[
              Divider(height: 1, color: portal.subtleBorderSide().color),
              Padding(
                padding: EdgeInsets.all(t.spacing.lg),
                child: footer!,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SidebarTile extends StatelessWidget {
  const _SidebarTile({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final PortalSidebarItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final portal = PortalUiTheme.of(context);
    final t = portal.tokens;
    final fg = selected ? portal.primary : portal.foreground;
    final bg = selected ? portal.accent : Colors.transparent;

    return Padding(
      padding: EdgeInsets.only(bottom: t.spacing.xs),
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(t.radii.md),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(t.radii.md),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: t.spacing.md,
              vertical: t.spacing.sm,
            ),
            child: Row(
              children: [
                if (item.icon != null) ...[
                  Icon(item.icon, size: 20, color: fg),
                  SizedBox(width: t.spacing.md),
                ],
                Expanded(
                  child: Text(
                    item.label,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: fg,
                          fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                        ),
                  ),
                ),
                if (item.badge != null)
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: portal.muted,
                      borderRadius: BorderRadius.circular(t.radii.full),
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: t.spacing.sm,
                        vertical: t.spacing.xs / 2,
                      ),
                      child: Text(
                        item.badge!,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: portal.mutedForeground,
                            ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
