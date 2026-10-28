import 'package:flutter/material.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

import '../chat/ai_card.dart';
import 'ai_step_tile.dart';

/// A tile from another app, drawn in the thread: the owning app's mark and an
/// eyebrow with Open, an optional summary figure, [AiCardRow]s, and a receipt
/// once the assistant acted.
class AiAppCard extends StatelessWidget {
  const AiAppCard({
    super.key,
    required this.card,
    this.mark,
    this.onOpen,
    this.onOpenRow,
  });

  final AiCard card;

  /// The owning app's glyph; a generic one when null.
  final Widget? mark;

  /// Open in the head and the receipt. Neither is drawn when null.
  final VoidCallback? onOpen;

  /// A row with an [AiCardRow.openLabel] was tapped. Those rows are inert
  /// when null.
  final ValueChanged<AiCardRow>? onOpenRow;

  @override
  Widget build(BuildContext context) {
    final t = PortalUiTheme.of(context).tokens;
    final receipt = card.receipt;
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: card.label ?? card.eyebrow,
      child: PortalCard(
        variant: PortalCardVariant.outlined,
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AiCardHead(
              mark: mark,
              eyebrow: card.eyebrow,
              openLabel: card.openLabel,
              onOpen: onOpen,
            ),
            if (card.summary case final s?)
              Padding(
                padding: EdgeInsets.fromLTRB(
                  t.spacing.lg,
                  0,
                  t.spacing.lg,
                  t.spacing.sm,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    PortalAmount.text(
                      s.amount,
                      unit: s.of,
                      size: PortalAmountSize.summary,
                    ),
                    if (s.caption case final caption?)
                      Text(
                        caption,
                        style: t.textStyles.caption.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                  ],
                ),
              ),
            if (card.rows.isNotEmpty)
              AiCardRows(rows: card.rows, onOpenRow: onOpenRow),
            if (receipt != null)
              Padding(
                padding: EdgeInsets.fromLTRB(
                  t.spacing.lg,
                  0,
                  t.spacing.lg,
                  t.spacing.md,
                ),
                child: AiReceipt(
                  label: receipt.label,
                  openLabel: receipt.openLabel,
                  onOpen: receipt.openLabel == null ? null : onOpen,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// The head of an app card or an ask: the app's mark, a caption eyebrow, and
/// Open when there is somewhere to go ([openLabel] names it for the screen
/// reader, "Open Finance").
class AiCardHead extends StatelessWidget {
  const AiCardHead({
    super.key,
    this.mark,
    required this.eyebrow,
    this.openLabel,
    this.onOpen,
  });

  final Widget? mark;
  final String eyebrow;
  final String? openLabel;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final t = PortalUiTheme.of(context).tokens;
    final cs = Theme.of(context).colorScheme;
    final open = openLabel != null && onOpen != null;
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: t.minTapTarget),
      child: Padding(
        padding: EdgeInsetsDirectional.only(
          start: t.spacing.lg,
          end: open ? t.spacing.sm : t.spacing.lg,
        ),
        child: Row(
          spacing: t.spacing.sm,
          children: [
            ExcludeSemantics(
              child:
                  mark ??
                  Icon(
                    Icons.apps_rounded,
                    size: t.iconSizes.md,
                    color: cs.onSurfaceVariant,
                  ),
            ),
            Expanded(
              child: Text(
                eyebrow,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: t.textStyles.caption.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ),
            if (open)
              Semantics(
                label: openLabel,
                button: true,
                excludeSemantics: true,
                child: PortalButton(
                  label: 'Open',
                  variant: PortalButtonVariant.secondary,
                  size: PortalButtonSize.sm,
                  onPressed: onOpen,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// [AiCardRow]s as one full-bleed list: a thumbnail when the row has a
/// picture, its figure at the end, and the whole row a button when it has an
/// [AiCardRow.openLabel] and [onOpenRow].
class AiCardRows extends StatelessWidget {
  const AiCardRows({super.key, required this.rows, this.onOpenRow});

  final List<AiCardRow> rows;
  final ValueChanged<AiCardRow>? onOpenRow;

  @override
  Widget build(BuildContext context) {
    return PortalListSection(
      style: PortalListStyle.fullBleed,
      children: [
        for (final row in rows)
          PortalListItem(
            title: row.title,
            subtitle: row.subtitle,
            leading: row.imageUrl == null
                ? null
                : PortalListLeading.thumbnail(
                    // A dead or repeat image must not blank the row: the
                    // text is the answer, and PortalNetworkImage already
                    // falls back the same way cached_network_image fails.
                    PortalNetworkImage(url: row.imageUrl),
                  ),
            trailing: row.value == null
                ? PortalListAccessory.none
                : PortalListAccessory.value(row.value!, unit: row.unit),
            onTap: row.openLabel == null || onOpenRow == null
                ? null
                : () => onOpenRow!(row),
            semanticLabel: row.openLabel == null || onOpenRow == null
                ? null
                : [
                    row.openLabel!,
                    if (row.value case final v?)
                      [v, row.unit].nonNulls.join(' '),
                    row.subtitle,
                  ].nonNulls.join(', '),
          ),
      ],
    );
  }
}
