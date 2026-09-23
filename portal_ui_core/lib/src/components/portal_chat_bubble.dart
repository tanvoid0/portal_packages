import 'package:flutter/material.dart';

import '../theme/portal_ui_theme.dart';

/// One side of a chat turn.
enum PortalChatAuthor { user, assistant }

/// A single message in a thread.
///
/// The two authors read differently on purpose: the assistant's turn is a
/// tone (`surfaceContainer`) at the full column width, because a reply is
/// often prose, a list or a fenced code block, and a bubble that caps the
/// measure fights all three. The user's own turn is the one bubble on the
/// page -- a gradient fill capped at [maxWidthFactor] of the available
/// width, which is also what makes it findable scrolling back for what you
/// asked. Both share the same tail shape: a squared corner on the side that
/// points at its author, the other three rounded. [leading] (an avatar) only
/// draws for [PortalChatAuthor.assistant] -- the user's own turn needs no
/// face beside it.
///
/// The tail corner is named with [BorderRadiusDirectional] rather than
/// left/right, so it stays pointed at its own edge -- the assistant's
/// start-side, the user's end-side -- under RTL instead of flipping to the
/// wrong side.
class PortalChatBubble extends StatelessWidget {
  const PortalChatBubble({
    super.key,
    required this.child,
    required this.author,
    this.leading,
    this.footer,
    this.onLongPress,
    this.maxWidthFactor = 0.85,
  });

  /// Already-built content -- markdown, a plain [Text], a tool-call card.
  final Widget child;
  final PortalChatAuthor author;

  /// Avatar gutter beside an assistant turn. Ignored for
  /// [PortalChatAuthor.user], which carries no face.
  final Widget? leading;

  /// Actions/timestamp row under the bubble, outside its fill.
  final Widget? footer;
  final VoidCallback? onLongPress;

  /// Caps the bubble as a fraction of the available width. Only applied to
  /// [PortalChatAuthor.user] -- an assistant turn always takes the full
  /// measure.
  final double maxWidthFactor;

  @override
  Widget build(BuildContext context) {
    final tokens = PortalUiTheme.of(context).tokens;
    final scheme = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;
    final isUser = author == PortalChatAuthor.user;

    final radius = BorderRadiusDirectional.only(
      topStart: Radius.circular(isUser ? tokens.radii.lg : tokens.radii.sm),
      topEnd: Radius.circular(tokens.radii.lg),
      bottomStart: Radius.circular(tokens.radii.lg),
      bottomEnd: Radius.circular(isUser ? tokens.radii.sm : tokens.radii.lg),
    );

    Widget bubble = DecoratedBox(
      decoration: BoxDecoration(
        color: isUser ? null : scheme.surfaceContainer,
        gradient: isUser ? tokens.gradients.accent(scheme) : null,
        borderRadius: radius,
        boxShadow: tokens.elevation.soft(brightness),
      ),
      child: Padding(
        padding: EdgeInsets.all(tokens.spacing.md),
        child: isUser
            ? DefaultTextStyle.merge(
                style: TextStyle(color: scheme.onPrimaryContainer),
                child: child,
              )
            : child,
      ),
    );

    if (onLongPress != null) {
      bubble = GestureDetector(onLongPress: onLongPress, child: bubble);
    }

    Widget content;
    if (isUser) {
      // Relative to the space this bubble was given, not the screen -- a
      // caller that has already inset the column keeps that inset.
      content = Align(
        alignment: AlignmentDirectional.centerEnd,
        child: LayoutBuilder(
          builder: (context, constraints) => ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: constraints.maxWidth * maxWidthFactor,
            ),
            child: bubble,
          ),
        ),
      );
    } else if (leading != null) {
      content = Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          leading!,
          SizedBox(width: tokens.spacing.sm),
          Expanded(child: bubble),
        ],
      );
    } else {
      content = bubble;
    }

    if (footer == null) return content;
    return Column(
      crossAxisAlignment:
          isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [content, footer!],
    );
  }
}
