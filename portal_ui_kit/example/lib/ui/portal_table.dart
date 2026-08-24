import 'package:flutter/material.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

/// Lightweight bordered [Table] (shadcn Table).
class PortalTable extends StatelessWidget {
  PortalTable({
    required this.columns,
    required this.rows,
    super.key,
  }) : assert(rows.every((r) => r.length == columns.length));

  final List<String> columns;
  final List<List<String>> rows;

  @override
  Widget build(BuildContext context) {
    final portal = PortalUiTheme.of(context);
    final t = portal.tokens;
    final borderSide = portal.subtleBorderSide();
    final borderColor = borderSide.color;

    Widget cell(String text, {bool header = false}) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: t.spacing.md, vertical: t.spacing.sm),
        child: Text(
          text,
          style: header
              ? Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: portal.onSurface,
                  )
              : Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: portal.onSurface,
                  ),
        ),
      );
    }

    return PortalThemedSurface(
      borderRadius: BorderRadius.circular(t.radii.md),
      borderSide: borderSide,
      child: Table(
        border: TableBorder.all(color: borderColor, width: t.borderWidth),
        children: [
          TableRow(
            decoration: BoxDecoration(color: portal.muted),
            children: [for (final c in columns) cell(c, header: true)],
          ),
          for (final r in rows)
            TableRow(
              children: [for (final c in r) cell(c)],
            ),
        ],
      ),
    );
  }
}
