import 'package:flutter/material.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

import '../tools/ai_tool.dart';

/// The cover photo a call carries, if it named one.
///
/// Tools that save something people look at -- a recipe, a jacket -- take an
/// image URL the model found with `image_search`. Showing it beats printing
/// the URL: the picture is most of what makes the proposal recognisable.
String? aiPreviewImage(Map<String, dynamic> args) {
  for (final entry in args.entries) {
    final key = entry.key.toLowerCase();
    if (!key.contains('image') && !key.contains('photo')) continue;
    final value = entry.value;
    if (value is! String) continue;
    final url = Uri.tryParse(value.trim());
    if (url != null && (url.scheme == 'https' || url.scheme == 'http')) {
      return value.trim();
    }
  }
  return null;
}

/// One argument value as something a person can check.
///
/// The user is being asked to approve a change to their own data, so the
/// arguments have to be legible -- a JSON dump is not an answer to "allow
/// this?".
String _describe(Object? value) => switch (value) {
  null => '-',
  // Steps and ingredients are sentences. Joined with a comma they read as
  // "Preheat the oven., Cut the aubergine.", so each gets its own line.
  final List list => list.map(_describe).join('\n'),
  // Rows arrive as {recipe_id, date, meal_type, servings}. The id is the
  // one value a person cannot check -- "868faf5c-bdc9-4f55 2026-09-08
  // dinner 4" is not an answer to "allow this?" -- so it is dropped, unless
  // dropping leaves nothing to show.
  final Map map => switch (map.values
      .where((v) => !_looksLikeId(v))
      .map(_describe)
      .join(' ')) {
    '' => map.values.map(_describe).join(' '),
    final kept => kept,
  },
  _ => '$value',
};

final _uuid = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
  caseSensitive: false,
);

bool _looksLikeId(Object? value) =>
    value is String && _uuid.hasMatch(value.trim());

/// A proposed tool call, asked in the thread: what it is, what it carries,
/// and Decline / Edit / Accept.
///
/// With [failure] set the card is the failed-step state instead: the same
/// call, the reason it failed in an inline prompt, and [onRetry] in place of
/// the three answers. Retry re-runs the tool outside the agent loop -- the
/// user asked for it directly, so the model is not consulted again and the
/// host re-confirms before it writes.
class AiConfirmCard extends StatelessWidget {
  const AiConfirmCard({
    super.key,
    required this.toolName,
    required this.args,
    required this.onAccept,
    required this.onDecline,
    this.onEdit,
    this.previewTitle,
    this.coverImageUrl,
    this.failure,
    this.onRetry,
    this.declineLabel = 'Decline',
    this.editLabel = 'Edit',
    this.acceptLabel = 'Accept',
    this.retryLabel = 'Retry',
  });

  /// The qualified tool name; titles the card and, when it names a delete or
  /// remove, turns Accept into the destructive button.
  final String toolName;
  final Map<String, dynamic> args;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  /// No Edit button when null.
  final VoidCallback? onEdit;

  /// The row this call would change, named. Becomes the title, with the tool
  /// above it as the eyebrow; without it the tool title is the title.
  final String? previewTitle;

  /// Defaults to the first image-ish URL in [args], which is then left out of
  /// the argument rows -- the photo is shown, so its URL is not worth a row.
  final String? coverImageUrl;

  /// Why the step failed. Non-null swaps the answers for a Retry prompt.
  final String? failure;
  final VoidCallback? onRetry;
  final String declineLabel;
  final String editLabel;
  final String acceptLabel;
  final String retryLabel;

  @override
  Widget build(BuildContext context) {
    final portal = PortalUiTheme.of(context);
    final tokens = portal.tokens;
    final spacing = tokens.spacing;
    final styles = tokens.textStyles;
    final cover = coverImageUrl ?? aiPreviewImage(args);
    final rows = [
      for (final arg in args.entries)
        if (cover == null || arg.value != cover) arg,
    ];
    final name = toolName.toLowerCase();
    final destructive = name.contains('delete') || name.contains('remove');
    final failed = failure;

    return PortalCard(
      variant: PortalCardVariant.outlined,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (cover != null)
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.network(
                cover,
                fit: BoxFit.cover,
                // A cover photo is decoration. A broken link must not take
                // the card -- and the decision it is asking for -- with it.
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            ),
          Padding(
            padding: EdgeInsets.all(spacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (previewTitle != null)
                  Text(
                    aiToolTitle(toolName),
                    style: styles.caption.copyWith(
                      color: portal.onSurfaceVariant,
                    ),
                  ),
                Text(
                  previewTitle ?? aiToolTitle(toolName),
                  style: styles.subtitle.copyWith(color: portal.onSurface),
                ),
                if (rows.isNotEmpty) ...[
                  SizedBox(height: spacing.md),
                  Table(
                    // Labels size to their text but never past two fifths of
                    // the card, so a long name wraps instead of starving the
                    // value beside it.
                    columnWidths: const {
                      0: MinColumnWidth(
                        IntrinsicColumnWidth(),
                        FractionColumnWidth(0.4),
                      ),
                      1: FlexColumnWidth(),
                    },
                    children: [
                      for (final arg in rows)
                        TableRow(
                          children: [
                            Padding(
                              padding: EdgeInsets.only(
                                right: spacing.md,
                                bottom: spacing.xs,
                              ),
                              child: Text(
                                arg.key.replaceAll('_', ' '),
                                style: styles.caption.copyWith(
                                  color: portal.onSurfaceVariant,
                                ),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.only(bottom: spacing.xs),
                              child: Text(
                                _describe(arg.value),
                                style: styles.caption.copyWith(
                                  color: portal.onSurface,
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
                SizedBox(height: spacing.md),
                if (failed != null)
                  PortalPrompt(
                    message: failed,
                    sentiment: PortalSentiment.negative,
                    size: PortalPromptSize.inline,
                    action: onRetry == null
                        ? null
                        : (label: retryLabel, onPressed: onRetry!),
                  )
                else
                  Align(
                    alignment: Alignment.centerRight,
                    child: Wrap(
                      alignment: WrapAlignment.end,
                      spacing: spacing.sm,
                      runSpacing: spacing.xs,
                      children: [
                        PortalButton(
                          label: declineLabel,
                          variant: PortalButtonVariant.ghost,
                          size: PortalButtonSize.sm,
                          onPressed: onDecline,
                        ),
                        if (onEdit != null)
                          PortalButton(
                            label: editLabel,
                            variant: PortalButtonVariant.secondary,
                            size: PortalButtonSize.sm,
                            onPressed: onEdit,
                          ),
                        PortalButton(
                          label: acceptLabel,
                          variant: destructive
                              ? PortalButtonVariant.destructive
                              : PortalButtonVariant.primary,
                          size: PortalButtonSize.sm,
                          onPressed: onAccept,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
