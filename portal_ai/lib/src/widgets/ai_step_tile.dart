import 'package:flutter/material.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

/// One quiet line of an agent turn: a small glyph and what happened, in the
/// muted caption voice so the answer it led to stays the loudest thing.
class AiStepLine extends StatelessWidget {
  const AiStepLine({
    super.key,
    required this.icon,
    required this.text,
    this.iconColor,
  });

  final IconData icon;
  final String text;

  /// Defaults to the muted text colour.
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final portal = PortalUiTheme.of(context);
    final tokens = portal.tokens;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: tokens.spacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: tokens.iconSizes.sm,
            color: iconColor ?? portal.onSurfaceVariant,
          ),
          SizedBox(width: tokens.spacing.sm),
          Expanded(
            child: Text(
              text,
              // A tool result is written for the model, and some are long --
              // two lines say what happened without burying the conversation.
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: tokens.textStyles.caption.copyWith(
                color: portal.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The line under a finished turn that says what it did ("Saved to your
/// recipes"): a tick, or the error glyph when the step [failed], above a rule.
class AiReceipt extends StatelessWidget {
  const AiReceipt({super.key, required this.label, this.failed = false});

  final String label;
  final bool failed;

  @override
  Widget build(BuildContext context) {
    final portal = PortalUiTheme.of(context);
    final tokens = portal.tokens;
    final semantic = PortalSemanticColors.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(border: Border(top: portal.subtleBorderSide())),
      child: Padding(
        padding: EdgeInsets.only(top: tokens.spacing.sm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              failed
                  ? PortalIcons.error_rounded
                  : PortalIcons.check_circle_rounded,
              size: tokens.iconSizes.sm,
              color: failed ? semantic.danger : semantic.success,
            ),
            SizedBox(width: tokens.spacing.sm),
            Expanded(
              child: Text(
                label,
                style: tokens.textStyles.caption.copyWith(
                  color: portal.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
