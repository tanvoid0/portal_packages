import 'package:flutter/material.dart';

/// The model's reasoning, folded away.
///
/// Collapsed by default and quieter than the answer: it is context for anyone
/// who wants to check the model's working, never the reply itself. Shown only
/// when the backend actually reports reasoning.
class AiThinkingTile extends StatefulWidget {
  const AiThinkingTile({
    super.key,
    required this.thinking,
    this.label = 'Thought process',
  });

  final String thinking;
  final String label;

  @override
  State<AiThinkingTile> createState() => _AiThinkingTileState();
}

class _AiThinkingTileState extends State<AiThinkingTile> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => setState(() => _open = !_open),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.psychology_outlined, size: 15, color: muted),
                const SizedBox(width: 6),
                Text(
                  widget.label,
                  style: theme.textTheme.labelSmall?.copyWith(color: muted),
                ),
                Icon(
                  _open ? Icons.expand_less : Icons.expand_more,
                  size: 16,
                  color: muted,
                ),
              ],
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          alignment: Alignment.topLeft,
          child: _open
              ? Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(top: 2, bottom: 4),
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border(
                      left: BorderSide(
                        color: theme.colorScheme.outlineVariant,
                        width: 2,
                      ),
                    ),
                  ),
                  child: Text(
                    widget.thinking,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: muted,
                      height: 1.4,
                      fontSize: 12,
                    ),
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}
