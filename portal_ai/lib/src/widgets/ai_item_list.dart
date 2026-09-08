import 'package:flutter/material.dart';

import '../tools/ai_tool.dart';

/// Draws an [AiBlock.items] result: one card, one row per item.
///
/// This is the assistant's own renderer, so a tool that returns rows shows
/// them the same way in every app. Everything is taken from the host's
/// [ThemeData], so the card inherits whatever palette and type scale the app
/// around it uses. A host that wants a different shape registers a renderer
/// for its own block kind instead.
class AiItemList extends StatelessWidget {
  const AiItemList({super.key, required this.items, this.onTap});

  final List<AiItem> items;

  /// Opens the host's own screen for a row. Rows are inert without it: the
  /// package has no idea what a recipe or a wardrobe item looks like.
  final ValueChanged<AiItem>? onTap;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outlineVariant, width: 0.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                thickness: 0.5,
                // Starts past the thumbnail so the images read as one column.
                indent: 76,
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
              ),
            _AiItemRow(item: items[i], theme: theme, onTap: onTap),
          ],
        ],
      ),
    );
  }
}

class _AiItemRow extends StatelessWidget {
  const _AiItemRow({required this.item, required this.theme, this.onTap});

  final AiItem item;
  final ThemeData theme;
  final ValueChanged<AiItem>? onTap;

  @override
  Widget build(BuildContext context) {
    final tap = onTap;
    final row = _row();
    if (tap == null) return row;
    return InkWell(onTap: () => tap(item), child: row);
  }

  Widget _row() {
    final image = item.imageUrl;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              width: 52,
              height: 52,
              child: image == null || image.isEmpty
                  ? _placeholder
                  : Image.network(
                      image,
                      fit: BoxFit.cover,
                      // A dead or slow image must not blank the row: the text
                      // beside it is the actual answer.
                      errorBuilder: (_, _, _) => _placeholder,
                      loadingBuilder: (_, child, progress) =>
                          progress == null ? child : _placeholder,
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.title,
                  // Two lines: a real title ("Dark Chocolate Skillet Cookie")
                  // does not survive one next to a trailing pill.
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                  ),
                ),
                if (item.subtitle.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    item.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.2,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (item.trailing.isNotEmpty) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text(
                item.trailing,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          if (onTap != null)
            Icon(
              Icons.chevron_right,
              size: 18,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
        ],
      ),
    );
  }

  Widget get _placeholder => ColoredBox(
    color: theme.colorScheme.surfaceContainerHighest,
    child: Icon(
      Icons.image_outlined,
      size: 20,
      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
    ),
  );
}
