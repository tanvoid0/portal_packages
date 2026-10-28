import 'package:flutter/material.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

import '../chat/ai_card.dart';
import '../tools/ai_tool.dart';
import 'ai_app_card.dart';
import 'ai_step_tile.dart';

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
class AiConfirmCard extends StatelessWidget {
  const AiConfirmCard({
    super.key,
    required this.toolName,
    required this.args,
    this.onAccept,
    this.onDecline,
    this.onEdit,
    this.previewTitle,
    this.coverImageUrl,
    this.eyebrow,
    this.mark,
    this.onOpen,
    this.openLabel,
    this.rows = const [],
    this.onOpenRow,
    this.receipt,
    this.failure,
    this.destructive,
    this.retryLabel = 'Retry',
    this.declineLabel = 'Decline',
    this.editLabel = 'Edit',
    this.acceptLabel = 'Accept',
  });

  /// The qualified tool name; titles the card and, when it names a delete or
  /// remove, turns Accept into the destructive button.
  final String toolName;
  final Map<String, dynamic> args;

  /// A null answer leaves its button disabled: the card is shown, but nothing
  /// is wired to take the answer.
  final VoidCallback? onAccept;
  final VoidCallback? onDecline;

  /// No Edit button when null.
  final VoidCallback? onEdit;

  /// The row this call would change, named. Becomes the title, with the tool
  /// above it as the eyebrow; without it the tool title is the title.
  final String? previewTitle;

  /// Defaults to the first image-ish URL in [args], which is then left out of
  /// the argument rows -- the photo is shown, so its URL is not worth a row.
  final String? coverImageUrl;

  /// Heads the card with the owning app: [mark] and this caption, and Open
  /// ([onOpen], named by [openLabel]) when there is somewhere to go. Replaces
  /// the tool-title caption over [previewTitle].
  final String? eyebrow;
  final Widget? mark;
  final VoidCallback? onOpen;
  final String? openLabel;

  /// What the change is made of, as list rows under the arguments.
  final List<AiCardRow> rows;
  final ValueChanged<AiCardRow>? onOpenRow;

  /// The change went through: the answers give way to what was done, and
  /// where to see it. Never set for a save that failed.
  final AiCardReceipt? receipt;

  /// The save failed: this is said over the answers, and [retryLabel] takes
  /// Accept's solid slot.
  final String? failure;

  /// Accept in the error fill. Null derives it from [toolName] naming a
  /// delete or remove.
  final bool? destructive;
  final String retryLabel;

  final String declineLabel;
  final String editLabel;
  final String acceptLabel;

  @override
  Widget build(BuildContext context) {
    final portal = PortalUiTheme.of(context);
    final tokens = portal.tokens;
    final spacing = tokens.spacing;
    final styles = tokens.textStyles;
    final cover = coverImageUrl ?? aiPreviewImage(args);
    final argRows = [
      for (final arg in args.entries)
        if (cover == null || arg.value != cover) arg,
    ];
    final name = toolName.toLowerCase();
    final destructive =
        this.destructive ??
        (name.contains('delete') || name.contains('remove'));
    final headed = eyebrow != null || mark != null;

    return PortalCard(
      variant: PortalCardVariant.outlined,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (cover != null)
            AspectRatio(
              aspectRatio: 16 / 9,
              // A cover photo is decoration. A broken link must not take
              // the card -- and the decision it is asking for -- with it;
              // PortalNetworkImage's own muted fallback keeps the card whole
              // instead of collapsing it to nothing.
              child: PortalNetworkImage(url: cover),
            ),
          if (headed)
            AiCardHead(
              mark: mark,
              eyebrow:
                  eyebrow ??
                  (previewTitle == null ? '' : aiToolTitle(toolName)),
              openLabel: openLabel,
              onOpen: onOpen,
            ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              spacing.lg,
              headed ? 0 : spacing.lg,
              spacing.lg,
              // The answers (or the receipt) pad their own top.
              0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (previewTitle != null && !headed)
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
                if (argRows.isNotEmpty) ...[
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
                      for (final arg in argRows)
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
              ],
            ),
          ),
          if (rows.isNotEmpty) AiCardRows(rows: rows, onOpenRow: onOpenRow),
          if (receipt == null)
            Padding(
              padding: EdgeInsets.fromLTRB(
                spacing.lg,
                spacing.md,
                spacing.lg,
                spacing.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (failure != null) ...[
                    PortalPrompt(
                      message: failure!,
                      size: PortalPromptSize.inline,
                      sentiment: PortalSentiment.negative,
                    ),
                    SizedBox(height: spacing.md),
                  ],
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
                          label: failure != null ? retryLabel : acceptLabel,
                          variant: destructive && failure == null
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
          if (receipt case final done?)
            Padding(
              padding: EdgeInsets.fromLTRB(
                spacing.lg,
                spacing.sm,
                spacing.lg,
                spacing.lg,
              ),
              child: AiReceipt(
                label: done.label,
                openLabel: done.openLabel,
                onOpen: done.openLabel == null ? null : onOpen,
              ),
            ),
        ],
      ),
    );
  }
}
