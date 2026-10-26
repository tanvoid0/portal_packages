import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../../contrast_gate.dart';
import '../theme/portal_sentiment.dart';
import '../theme/portal_ui_theme.dart';
import '../tokens/design_tokens.dart';
import '../theme/portal_theme_helpers.dart';

export '../theme/portal_sentiment.dart' show PortalSentiment, PortalSentimentColors;

enum PortalPromptSize { standard, compact, inline }

/// The one action a prompt may carry: a verb for what fixes it ("Retry now").
typedef PortalPromptAction = ({String label, VoidCallback onPressed});

/// Between a toast (transient) and a dialog (interrupting): a message that
/// lives in the content and says what happened and what to do.
///
/// One tonal emphasis: the sentiment's base at 12% over `portal.card`, no
/// border, stripe or shadow. The badge carries the colour (a disc in four
/// shapes, so sentiment reads in greyscale); text stays ink, except an inline
/// negative's, which takes `error`. At most one action. [onDismiss] is for an
/// event that has happened, never a state that clears itself.
///
/// Every prompt is a live region; a negative one also announces itself
/// assertively the first time it shows, except an inline one, which stays
/// polite so several in one frame do not cut each other off.
class PortalPrompt extends StatefulWidget {
  const PortalPrompt({
    super.key,
    required this.message,
    this.title,
    this.sentiment = PortalSentiment.neutral,
    this.size = PortalPromptSize.standard,
    this.icon,
    this.action,
    this.secondaryAction,
    this.onDismiss,
    this.visible = true,
  })  : assert(
          size != PortalPromptSize.inline ||
              (title == null && onDismiss == null),
          'inline has no title and no dismiss',
        ),
        assert(
          size != PortalPromptSize.compact ||
              action == null ||
              onDismiss == null,
          'compact carries an action or a dismiss, never both',
        ),
        assert(
          secondaryAction == null ||
              (action != null && size == PortalPromptSize.standard),
          'a secondary action needs an action and the standard size',
        );

  final String message;

  /// Standard: the title line. Compact: a bold lead.
  final String? title;
  final PortalSentiment sentiment;
  final PortalPromptSize size;

  /// Replaces the default glyph and keeps the disc.
  final IconData? icon;
  final PortalPromptAction? action;

  /// A quieter second verb beside [action] ("Dismiss", "Not now"); standard
  /// size only. The kit's prompt cards are one-action-max, but production
  /// deliberately allows one optional quiet secondary; the one-action default
  /// is unchanged.
  final PortalPromptAction? secondaryAction;

  /// Shows the close button.
  final VoidCallback? onDismiss;

  /// False runs the exit, then collapses to zero height.
  final bool visible;

  @override
  State<PortalPrompt> createState() => _PortalPromptState();
}

class _PortalPromptState extends State<PortalPrompt>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
    reverseDuration: const Duration(milliseconds: 200),
  );
  bool _announced = false;

  @override
  void initState() {
    super.initState();
    if (widget.visible) _c.forward();
  }

  @override
  void didUpdateWidget(PortalPrompt old) {
    super.didUpdateWidget(old);
    if (widget.visible != old.visible) {
      widget.visible ? _c.forward() : _c.reverse();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _announce(BuildContext context) {
    if (_announced ||
        !widget.visible ||
        widget.sentiment != PortalSentiment.negative ||
        widget.size == PortalPromptSize.inline) {
      return;
    }
    _announced = true;
    final text = [widget.title, widget.message].whereType<String>().join('. ');
    final dir = Directionality.of(context);
    final view = View.of(context);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SemanticsService.sendAnnouncement(
        view,
        text,
        dir,
        assertiveness: Assertiveness.assertive,
      );
    });
  }

  void _dismiss() {
    FocusScope.of(context).nextFocus();
    widget.onDismiss?.call();
  }

  @override
  Widget build(BuildContext context) {
    _announce(context);
    final reduce = MediaQuery.of(context).disableAnimations;
    final body = Semantics(
      liveRegion: true,
      container: true,
      child: _PromptBody(prompt: widget, onDismiss: _dismiss),
    );
    if (widget.size == PortalPromptSize.inline) {
      return widget.visible ? body : const SizedBox.shrink();
    }

    final fade = CurvedAnimation(
      parent: _c,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    );
    final spatial = CurvedAnimation(
      parent: _c,
      curve: PortalMotion.spatial,
      reverseCurve: Curves.easeIn,
    );
    Widget child = body;
    if (!reduce) {
      child = AnimatedBuilder(
        animation: spatial,
        builder: (_, c) {
          final t = spatial.value;
          return Transform.translate(
            offset: Offset(0, -8 * (1 - t)),
            child: Transform.scale(
              scale: .96 + .04 * t,
              alignment: Alignment.topCenter,
              child: c,
            ),
          );
        },
        child: body,
      );
    }
    return SizeTransition(
      sizeFactor: reduce
          ? AlwaysStoppedAnimation(widget.visible ? 1.0 : 0.0)
          : CurvedAnimation(parent: _c, curve: PortalMotion.effects),
      alignment: Alignment.topCenter,
      child: FadeTransition(opacity: fade, child: child),
    );
  }
}

class _PromptBody extends StatelessWidget {
  const _PromptBody({required this.prompt, required this.onDismiss});

  final PortalPrompt prompt;
  final VoidCallback onDismiss;

  /// A foreground under its threshold on its fill steps 12% toward onSurface.
  static Color _clear(Color fg, Color bg, Color ink, double min) =>
      portalContrastRatio(fg, bg) >= min ? fg : Color.lerp(fg, ink, .12)!;

  @override
  Widget build(BuildContext context) {
    final portal = PortalUiTheme.of(context);
    final tokens = portal.tokens;
    final cs = Theme.of(context).colorScheme;
    final p = prompt;

    final base = p.sentiment.base(context);
    final onBase = p.sentiment.onBase(context);
    final glyph = p.sentiment.glyph;
    final fill = p.sentiment == PortalSentiment.neutral
        ? portalOffPage(context, cs.surfaceContainerHigh)
        : Color.alphaBlend(base.withValues(alpha: .12), portal.card);
    final ink = cs.onSurface;
    final muted = _clear(cs.onSurfaceVariant, fill, ink, 4.5);
    final disc = _clear(base, fill, ink, 3);
    final badgeGlyph = _clear(onBase, disc, ink, 3);
    final iconData = p.icon ?? glyph;

    Widget badge(double size, double glyphSize) => ExcludeSemantics(
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(color: disc, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Icon(iconData, size: glyphSize, color: badgeGlyph, fill: 1),
          ),
        );

    final styles = tokens.textStyles;
    final tap = tokens.minTapTarget;
    final tonal = Color.alphaBlend(ink.withValues(alpha: .08), fill);

    Widget actionButton(
        {required double height,
        required double radius,
        required double hPad,
        required double size}) {
      final a = p.action!;
      return FilledButton(
        onPressed: a.onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: tonal,
          foregroundColor: ink,
          elevation: 0,
          minimumSize: Size(0, height),
          padding: EdgeInsets.symmetric(horizontal: hPad),
          tapTargetSize: MaterialTapTargetSize.padded,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radius)),
          textStyle: Theme.of(context)
              .textTheme
              .labelLarge
              ?.copyWith(fontSize: size, fontWeight: FontWeight.w600),
        ),
        child: Text(a.label),
      );
    }

    Widget dismiss() => SizedBox(
          width: tap,
          height: tap,
          child: IconButton(
            tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
            onPressed: onDismiss,
            icon: const Icon(Icons.close, size: 20),
            color: muted,
            style: IconButton.styleFrom(
              overlayColor: ink,
              minimumSize: Size(tap, tap),
            ),
          ),
        );

    switch (p.size) {
      case PortalPromptSize.inline:
        final textColor = p.sentiment == PortalSentiment.negative
            ? _clear(cs.error, cs.surface, ink, 4.5)
            : ink;
        final a = p.action;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            badge(20, 14),
            SizedBox(width: tokens.spacing.sm),
            Expanded(
              child: Text.rich(
                TextSpan(children: [
                  TextSpan(text: p.message),
                  if (a != null) const TextSpan(text: '  '),
                ]),
                style: TextStyle(
                  fontSize: 13,
                  height: 20 / 13,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                  fontFamily: styles.body.fontFamily,
                ),
              ),
            ),
            if (a != null)
              TextButton(
                onPressed: a.onPressed,
                style: TextButton.styleFrom(
                  foregroundColor: _clear(cs.primary, cs.surface, ink, 4.5),
                  minimumSize: const Size(0, 20),
                  padding: EdgeInsets.zero,
                  tapTargetSize: MaterialTapTargetSize.padded,
                  textStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                    decorationThickness: 1.5,
                  ),
                ),
                child: Text(a.label),
              ),
          ],
        );

      case PortalPromptSize.compact:
        final hasAction = p.action != null;
        final hasDismiss = p.onDismiss != null;
        final lead = TextStyle(
            fontSize: 14,
            height: 20 / 14,
            fontWeight: FontWeight.w600,
            color: ink,
            fontFamily: styles.body.fontFamily);
        return Container(
          constraints: BoxConstraints(minHeight: tap),
          decoration: BoxDecoration(
              color: fill, borderRadius: BorderRadius.circular(24)),
          padding: EdgeInsetsDirectional.fromSTEB(
              12, 14, hasDismiss ? 0 : (hasAction ? 6 : 16), 14),
          child: Row(
            children: [
              badge(24, 16),
              const SizedBox(width: 10),
              Expanded(
                child: Text.rich(
                  TextSpan(children: [
                    if (p.title != null) ...[
                      TextSpan(text: p.title, style: lead),
                      TextSpan(text: ' · ', style: TextStyle(color: muted)),
                    ],
                    TextSpan(
                      text: p.message,
                      style: TextStyle(
                          color: p.title != null ? muted : ink,
                          fontWeight: p.title != null
                              ? FontWeight.w400
                              : FontWeight.w500),
                    ),
                  ]),
                  style: TextStyle(
                      fontSize: 14,
                      height: 20 / 14,
                      fontFamily: styles.body.fontFamily),
                ),
              ),
              if (hasAction) ...[
                const SizedBox(width: 8),
                actionButton(
                    height: tokens.componentSizes.buttonHeightSm,
                    radius: 18,
                    hPad: 14,
                    size: 14),
              ],
              if (hasDismiss) dismiss(),
            ],
          ),
        );

      case PortalPromptSize.standard:
        final gap = tokens.spacing.lg;
        final textStyle = TextStyle(fontFamily: styles.body.fontFamily);
        final content = Padding(
          padding:
              EdgeInsetsDirectional.only(end: p.onDismiss != null ? 32 : 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (p.title != null)
                Text(p.title!,
                    style: textStyle.copyWith(
                        fontSize: 16,
                        height: 24 / 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -.1,
                        color: ink)),
              Padding(
                padding: EdgeInsets.only(top: p.title != null ? 2 : 0),
                child: Text(
                  p.message,
                  style: p.title != null
                      ? textStyle.copyWith(
                          fontSize: 14, height: 20 / 14, color: muted)
                      : textStyle.copyWith(
                          fontSize: 15, height: 24 / 15, color: ink),
                ),
              ),
              if (p.action != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      actionButton(
                          height: tokens.componentSizes.buttonHeightSm,
                          radius: tokens.radii.md,
                          hPad: 16,
                          size: 14),
                      if (p.secondaryAction != null)
                        TextButton(
                          onPressed: p.secondaryAction!.onPressed,
                          style: TextButton.styleFrom(
                            foregroundColor: ink,
                            minimumSize: Size(0, tokens.minTapTarget),
                            padding: EdgeInsets.symmetric(
                                horizontal: tokens.spacing.lg),
                            tapTargetSize: MaterialTapTargetSize.padded,
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(tokens.radii.md)),
                            textStyle: Theme.of(context)
                                .textTheme
                                .labelLarge
                                ?.copyWith(
                                    fontSize: tokens.typeScale.md,
                                    fontWeight: FontWeight.w600),
                          ),
                          child: Text(p.secondaryAction!.label),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        );
        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(gap),
          decoration: BoxDecoration(
              color: fill,
              borderRadius: BorderRadius.circular(tokens.radii.lg)),
          child: Stack(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  badge(24, 16),
                  SizedBox(width: gap),
                  Expanded(child: content),
                ],
              ),
              if (p.onDismiss != null)
                PositionedDirectional(
                    top: -gap + 4, end: -gap + 4, child: dismiss()),
            ],
          ),
        );
    }
  }
}
