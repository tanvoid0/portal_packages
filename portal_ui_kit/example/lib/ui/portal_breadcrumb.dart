import 'package:flutter/material.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

class PortalBreadcrumbItem {
  const PortalBreadcrumbItem({required this.label, this.onTap});

  final String label;
  final VoidCallback? onTap;
}

/// Horizontal trail with chevrons (shadcn Breadcrumb).
class PortalBreadcrumb extends StatelessWidget {
  PortalBreadcrumb({
    required this.items,
    super.key,
  }) : assert(items.isNotEmpty);

  final List<PortalBreadcrumbItem> items;

  @override
  Widget build(BuildContext context) {
    final portal = PortalUiTheme.of(context);
    final t = portal.tokens;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) ...[
              Padding(
                padding: EdgeInsets.symmetric(horizontal: t.spacing.xs),
                child: Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: portal.onSurfaceVariant,
                ),
              ),
            ],
            _Crumb(
              item: items[i],
              isLast: i == items.length - 1,
            ),
          ],
        ],
      ),
    );
  }
}

class _Crumb extends StatelessWidget {
  const _Crumb({required this.item, required this.isLast});

  final PortalBreadcrumbItem item;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final portal = PortalUiTheme.of(context);
    final style = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: isLast ? portal.onSurface : portal.onSurfaceVariant,
          fontWeight: isLast ? FontWeight.w600 : FontWeight.w400,
        );

    final text = Text(item.label, style: style);
    if (item.onTap == null || isLast) {
      return text;
    }
    return InkWell(
      onTap: item.onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
        child: text,
      ),
    );
  }
}
