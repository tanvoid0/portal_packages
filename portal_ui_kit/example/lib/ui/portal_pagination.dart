import 'package:flutter/material.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

/// Previous / next with current page label (shadcn Pagination).
class PortalPagination extends StatelessWidget {
  const PortalPagination({
    required this.currentPage,
    required this.totalPages,
    required this.onPageChanged,
    super.key,
  })  : assert(currentPage >= 1 && currentPage <= totalPages),
        assert(totalPages >= 1);

  final int currentPage;
  final int totalPages;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    final portal = PortalUiTheme.of(context);
    final t = portal.tokens;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          visualDensity: VisualDensity.compact,
          onPressed: currentPage > 1 ? () => onPageChanged(currentPage - 1) : null,
          icon: const Icon(Icons.chevron_left),
          color: portal.onSurface,
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: t.spacing.sm),
          child: Text(
            '$currentPage / $totalPages',
            style: Theme.of(context).textTheme.labelLarge,
          ),
        ),
        IconButton(
          visualDensity: VisualDensity.compact,
          onPressed: currentPage < totalPages ? () => onPageChanged(currentPage + 1) : null,
          icon: const Icon(Icons.chevron_right),
          color: portal.onSurface,
        ),
      ],
    );
  }
}
