import 'package:flutter/material.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

/// Where a reply is in its life; picks what [AiReplyFoot] shows.
enum AiReplyStatus { writing, waiting, done, failed }

/// The one line under an assistant reply: its state while it is coming, its
/// actions once it is here, and a retry when it never arrived.
///
/// [mark] (the avatar or orb) leads every state but [AiReplyStatus.failed],
/// which is a prompt that carries its own badge. Labels are parameters so an
/// app can localise them; the English defaults are the fleet's.
class AiReplyFoot extends StatelessWidget {
  const AiReplyFoot({
    super.key,
    this.mark,
    required this.status,
    this.failure,
    this.onCopy,
    this.onRegenerate,
    this.onRetry,
    this.meta,
    this.writing = 'Writing',
    this.waitingForYou = 'Waiting for you',
    this.copyReply = 'Copy reply',
    this.regenerate = 'Regenerate reply',
    this.retry = 'Retry',
  });

  final Widget? mark;
  final AiReplyStatus status;

  /// The error message, shown when [status] is [AiReplyStatus.failed].
  final String? failure;
  final VoidCallback? onCopy;

  /// Omit to hide the regenerate button (only the last reply can be redone).
  final VoidCallback? onRegenerate;
  final VoidCallback? onRetry;

  /// A trailing caption, usually the timestamp.
  final String? meta;
  final String writing;
  final String waitingForYou;
  final String copyReply;
  final String regenerate;
  final String retry;

  @override
  Widget build(BuildContext context) {
    final tokens = PortalUiTheme.of(context).tokens;
    final cs = Theme.of(context).colorScheme;
    final caption = tokens.textStyles.caption.copyWith(
      color: cs.onSurfaceVariant,
    );
    final gap = SizedBox(width: tokens.spacing.sm);

    Widget iconButton(String tip, IconData icon, VoidCallback? onPressed) =>
        PortalButton.icon(
          tooltip: tip,
          onPressed: onPressed,
          icon: icon,
          variant: PortalButtonVariant.ghost,
          foregroundColor: cs.onSurfaceVariant,
        );

    final children = switch (status) {
      AiReplyStatus.writing => [
        if (mark != null) ...[mark!, gap],
        // The only live region on a streaming reply; PortalPrompt carries
        // its own, so failed does not nest one.
        Semantics(
          liveRegion: true,
          // ponytail: PortalShimmer sweeps the whole word, and drops to the
          // plain muted caption under reduce-motion. A per-letter wave
          // would be a custom painter; add if the sweep reads too flat.
          child: PortalShimmer(
            baseColor: cs.onSurfaceVariant,
            highlightColor: cs.onSurface,
            child: Text(writing, style: caption),
          ),
        ),
      ],
      AiReplyStatus.waiting => [
        if (mark != null) ...[mark!, gap],
        Text(waitingForYou, style: caption),
      ],
      AiReplyStatus.done => [
        if (mark != null) ...[mark!, gap],
        iconButton(copyReply, PortalIcons.content_copy_rounded, onCopy),
        if (onRegenerate != null)
          iconButton(regenerate, PortalIcons.refresh_rounded, onRegenerate),
        if (meta != null) ...[
          gap,
          Flexible(
            child: Text(
              meta!,
              style: caption,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ],
      AiReplyStatus.failed => [
        Expanded(
          child: PortalPrompt(
            size: PortalPromptSize.inline,
            sentiment: PortalSentiment.negative,
            message: failure ?? '',
            action: onRetry == null
                ? null
                : (label: retry, onPressed: onRetry!),
          ),
        ),
      ],
    };

    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: tokens.minTapTarget),
      child: Row(children: children),
    );
  }
}
