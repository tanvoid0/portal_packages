import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:markdown_widget/markdown_widget.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

/// Assistant prose, rendered as markdown.
///
/// Models emit `**bold**` and bullet lists whether or not you ask them to, and
/// as plain text those read as literal asterisks. Sized and coloured from the
/// host's theme so a reply looks like it belongs to the app around it.
class AiMarkdown extends StatelessWidget {
  const AiMarkdown({
    super.key,
    required this.text,
    this.style,
    this.copyCodeLabel = 'Copy code',
    this.copiedLabel = 'Copied',
  });

  final String text;

  final String copyCodeLabel;
  final String copiedLabel;

  /// Base style for body text. Defaults to the theme's `bodyMedium`.
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = PortalUiTheme.of(context).tokens;
    final rule = BorderSide(
      color: theme.colorScheme.outlineVariant,
      width: tokens.borderWidth,
    );
    final body = (style ?? theme.textTheme.bodyMedium ?? const TextStyle())
        .copyWith(height: 1.45);
    // Plain text is the common case -- a sentence or two. Skip the block
    // parser for it so the usual reply stays a single Text.
    if (!_looksLikeMarkdown(text)) {
      return SelectableText(text, style: body);
    }
    return MarkdownBlock(
      data: text,
      selectable: true,
      generator: MarkdownGenerator(
        generators: [
          SpanNodeGeneratorWithTag(
            tag: MarkdownTag.table.name,
            generator: (e, config, visitor) =>
                _AlignedTableNode(config, visitor),
          ),
          for (final tag in [MarkdownTag.th.name, MarkdownTag.td.name])
            SpanNodeGeneratorWithTag(
              tag: tag,
              generator: (e, config, visitor) =>
                  _CellNode(e.attributes['align'], e.textContent),
            ),
        ],
      ),
      config: MarkdownConfig(
        configs: [
          PConfig(textStyle: body),
          H1Config(style: theme.textTheme.titleMedium ?? body),
          H2Config(style: theme.textTheme.titleSmall ?? body),
          H3Config(style: theme.textTheme.titleSmall ?? body),
          ListConfig(marginLeft: 16),
          CodeConfig(
            style: body.copyWith(
              fontFamily: 'monospace',
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
            ),
          ),
          PreConfig(
            textStyle: body.copyWith(fontFamily: 'monospace'),
            padding: EdgeInsets.fromLTRB(
              tokens.spacing.lg,
              0,
              tokens.spacing.lg,
              tokens.spacing.md,
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(tokens.radii.md),
            ),
            // A code block is the one thing nobody retypes by hand: the
            // language on the left, Copy on the right, the code under both.
            wrapper: (child, code, language) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    if (language.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(left: tokens.spacing.lg),
                        child: Text(
                          language,
                          style: tokens.textStyles.caption.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    const Spacer(),
                    _CopyCodeButton(
                      code: code,
                      tooltip: copyCodeLabel,
                      copied: copiedLabel,
                    ),
                  ],
                ),
                child,
              ],
            ),
          ),
          // Rules between rows, a heavier header, tabular figures.
          TableConfig(
            border: TableBorder(horizontalInside: rule, bottom: rule),
            headerStyle: body.copyWith(
              fontWeight: tokens.textStyles.subtitle.fontWeight,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            bodyStyle: body.copyWith(
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
            headPadding: EdgeInsets.symmetric(
              horizontal: tokens.spacing.sm,
              vertical: tokens.spacing.sm,
            ),
            bodyPadding: EdgeInsets.symmetric(
              horizontal: tokens.spacing.sm,
              vertical: tokens.spacing.sm,
            ),
          ),
          LinkConfig(style: body.copyWith(color: theme.colorScheme.primary)),
          HrConfig(color: theme.colorScheme.outlineVariant),
        ],
      ),
    );
  }

  /// Cheap check for the markers worth running the parser over.
  static bool _looksLikeMarkdown(String text) {
    return text.contains('**') ||
        text.contains('`') ||
        text.contains('](') ||
        RegExp(r'(^|\n)\s*([*\-+]\s|\d+\.\s|#{1,6}\s|>\s)').hasMatch(text) ||
        // A table's rule row; without it a table reads as bare pipes.
        RegExp(r'(^|\n)\s*\|?\s*:?-{3,}:?\s*\|').hasMatch(text);
  }
}

/// A `th`/`td` that keeps the delimiter row's alignment (`:--`, `:-:`, `--:`)
/// and its plain text, both of which the stock cell nodes drop.
class _CellNode extends ElementNode {
  _CellNode(this.align, this.plain);

  final String? align;
  final String plain;

  @override
  TextStyle? get style => parentStyle;
}

/// Numbers, money, percentages: `12`, `-3.5`, `+4%`, `$1,200.00`, `(40)`.
final _numeric = RegExp(r'^\(?[+\-−]?[\$£€¥]?[+\-−]?\d[\d,]*(\.\d+)?%?\)?$');

/// The stock table centres every header and honours alignment only on body
/// cells. This one sizes columns to content, applies the delimiter alignment
/// to header and body alike, and right-aligns a column the author left
/// unaligned when every body cell in it is a number.
class _AlignedTableNode extends TableNode {
  _AlignedTableNode(super.config, this.visitor);

  final WidgetVisitor visitor;

  @override
  InlineSpan build() {
    final head = children.whereType<THeadNode>().expand((h) => h.children);
    final body = children.whereType<TBodyNode>().expand((b) => b.children);
    final headRow = head.isEmpty
        ? <SpanNode>[]
        : (head.first as TrNode).children;
    final bodyRows = [for (final r in body) (r as TrNode).children];

    Alignment alignOf(int col) {
      final explicit = col < headRow.length
          ? (headRow[col] as _CellNode).align
          : null;
      if (explicit != null) {
        return explicit == 'right'
            ? Alignment.centerRight
            : explicit == 'center'
            ? Alignment.center
            : Alignment.centerLeft;
      }
      final cells = [
        for (final r in bodyRows)
          if (col < r.length && (r[col] as _CellNode).plain.trim().isNotEmpty)
            (r[col] as _CellNode).plain.trim(),
      ];
      return cells.isNotEmpty && cells.every(_numeric.hasMatch)
          ? Alignment.centerRight
          : Alignment.centerLeft;
    }

    TableRow row(
      List<SpanNode> cells,
      int count,
      EdgeInsets pad,
      Decoration? d,
    ) => TableRow(
      decoration: d,
      children: [
        for (var i = 0; i < count; i++)
          i < cells.length
              ? Padding(
                  padding: pad,
                  child: Align(
                    alignment: alignOf(i),
                    child: ProxyRichText(
                      cells[i].build(),
                      richTextBuilder: visitor.richTextBuilder,
                    ),
                  ),
                )
              : const SizedBox.shrink(),
      ],
    );

    final n = headRow.length;
    final table = Table(
      defaultColumnWidth: const IntrinsicColumnWidth(),
      border: tbConfig.border,
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        if (n > 0)
          row(headRow, n, tbConfig.headPadding, tbConfig.headerRowDecoration),
        for (final r in bodyRows)
          row(r, n, tbConfig.bodyPadding, tbConfig.bodyRowDecoration),
      ],
    );
    // ponytail: columns are content-sized, so a wide table scrolls sideways
    // instead of wrapping long cells; give the long column a FlexColumnWidth
    // inside a bounded box if wrapping is wanted.
    return WidgetSpan(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: table,
      ),
    );
  }
}

class _CopyCodeButton extends StatelessWidget {
  const _CopyCodeButton({
    required this.code,
    required this.tooltip,
    required this.copied,
  });

  final String code;
  final String tooltip;
  final String copied;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      iconSize: 16,
      visualDensity: VisualDensity.compact,
      icon: const Icon(Icons.copy_outlined),
      onPressed: () {
        Clipboard.setData(ClipboardData(text: code));
        ScaffoldMessenger.maybeOf(
          context,
        )?.showSnackBar(SnackBar(content: Text(copied)));
      },
    );
  }
}
