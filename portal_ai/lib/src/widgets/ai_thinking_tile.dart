import 'package:flutter/material.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

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
    final tokens = PortalUiTheme.of(context).tokens;
    final cs = Theme.of(context).colorScheme;
    final caption = tokens.textStyles.caption.copyWith(
      color: cs.onSurfaceVariant,
    );
    final spacing = tokens.spacing;
    final motion = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : tokens.motion.fast;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          button: true,
          expanded: _open,
          child: InkWell(
            onTap: () => setState(() => _open = !_open),
            borderRadius: BorderRadius.circular(tokens.radii.sm),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: tokens.minTapTarget),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedRotation(
                    turns: _open ? .25 : 0,
                    duration: motion,
                    child: Icon(
                      PortalIcons.chevron_right_rounded,
                      size: tokens.iconSizes.sm,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  SizedBox(width: spacing.xs),
                  Text(widget.label, style: caption),
                ],
              ),
            ),
          ),
        ),
        AnimatedSize(
          duration: motion,
          curve: Curves.easeOut,
          alignment: Alignment.topLeft,
          child: _open
              ? Container(
                  width: double.infinity,
                  margin: EdgeInsets.only(bottom: spacing.xs),
                  padding: EdgeInsets.symmetric(
                    horizontal: spacing.md,
                    vertical: spacing.sm,
                  ),
                  decoration: BoxDecoration(
                    border: Border(
                      left: BorderSide(
                        color: cs.outlineVariant,
                        width: tokens.borderWidth * 2,
                      ),
                    ),
                  ),
                  child: Text(widget.thinking, style: caption),
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}
