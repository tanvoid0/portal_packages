import 'package:flutter/material.dart';

import '../theme/portal_semantic_colors.dart';
import '../theme/portal_ui_theme.dart';
import '../tokens/design_tokens.dart';
import 'portal_avatar_mark.dart';
import 'portal_badge.dart';
import 'portal_icon_tile.dart';
import 'portal_pressable.dart';
import 'portal_progress.dart';
import 'portal_prompt.dart';
import 'portal_section_header.dart';
import 'portal_skeleton.dart';
import 'portal_typing_dots.dart';

/// How a [PortalListItem.value] reads. Never the only signal: pair
/// positive/negative with a sign or an icon.
enum PortalValueSentiment { neutral, positive, negative, dim, meta }

/// What leads a row. One size per page: when any section has a 40 leading,
/// icon rows take [PortalListLeading.tile].
class PortalListLeading {
  const PortalListLeading._(this.extent, this._build,
      {this.interactive = false});

  /// The painted width; [PortalListSection] insets its dividers by it.
  final double extent;
  final Widget Function(BuildContext) _build;

  /// True when the child is a control that keeps its own semantics.
  final bool interactive;

  /// A bare 24 dp icon, for dense or utility lists. [color] defaults to
  /// `onSurfaceVariant`.
  factory PortalListLeading.icon(IconData icon, {Color? color}) =>
      PortalListLeading._(
        24,
        (c) => ExcludeSemantics(
          child: Icon(icon,
              size: 24,
              color: color ?? Theme.of(c).colorScheme.onSurfaceVariant),
        ),
      );

  /// A 40 dp tonal tile holding an icon. [backgroundColor] and
  /// [foregroundColor] replace the [tone]'s pair; [shape] is a rounded square
  /// or a circle.
  factory PortalListLeading.tile(
    IconData icon, {
    PortalListTone tone = PortalListTone.primary,
    Color? backgroundColor,
    Color? foregroundColor,
    PortalIconTileShape shape = PortalIconTileShape.roundedSquare,
  }) =>
      PortalListLeading.tileBuilder(
        (c, color) => Icon(icon, size: 24, color: color),
        tone: tone,
        shape: shape,
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
      );

  /// [PortalListLeading.tile] for any glyph: [iconBuilder] gets the ink to
  /// paint with (a `FaIcon`, an SVG) and sizes it itself (24).
  factory PortalListLeading.tileBuilder(
    Widget Function(BuildContext context, Color color) iconBuilder, {
    PortalListTone tone = PortalListTone.primary,
    Color? backgroundColor,
    Color? foregroundColor,
    PortalIconTileShape shape = PortalIconTileShape.roundedSquare,
  }) =>
      PortalListLeading._(
        40,
        (c) => PortalIconTile.builder(
          iconBuilder,
          tone: tone,
          shape: shape,
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
        ),
      );

  /// Any widget (a logo plate, a mark), [extent] wide. Decorative: it is
  /// left out of the row's label.
  factory PortalListLeading.custom(Widget child, {double extent = 40}) =>
      PortalListLeading._(extent, (c) => ExcludeSemantics(child: child));

  /// A control in the leading slot (a checkbox, a button). Unlike every other
  /// leading it is *not* decorative: it keeps its own semantics, so give it a
  /// name (`Semantics(label:)`, `tooltip:`) and the row stops reading as one
  /// merged label.
  factory PortalListLeading.interactive(Widget child, {double extent = 40}) =>
      PortalListLeading._(extent, (c) => child, interactive: true);

  /// A 40 dp avatar, or 56 dp for an account cell.
  factory PortalListLeading.avatar(
    String initials, {
    ImageProvider? image,
    bool large = false,
  }) =>
      PortalListLeading._(
        large ? 56 : 40,
        (c) => ExcludeSemantics(
          child: PortalAvatarMark(
            initials: initials,
            image: image,
            size: large ? PortalAvatarMarkSize.lg : PortalAvatarMarkSize.md,
          ),
        ),
      );

  /// A 40 dp thumbnail, clipped to the tile radius.
  factory PortalListLeading.thumbnail(Widget image) => PortalListLeading._(
        40,
        (c) => ExcludeSemantics(
          child: ClipRRect(
            borderRadius:
                BorderRadius.circular(PortalUiTheme.of(c).tokens.radii.sm),
            child: SizedBox(width: 40, height: 40, child: image),
          ),
        ),
      );

  /// A plain tabular numeral, for ordered lists; not a tinted tile.
  factory PortalListLeading.order(int n) => PortalListLeading._(
        24,
        (c) => ExcludeSemantics(
          child: SizedBox(
            width: 24,
            child: Text(
              '$n',
              textAlign: TextAlign.center,
              style: PortalUiTheme.of(c).tokens.textStyles.body.copyWith(
                color: Theme.of(c).colorScheme.onSurfaceVariant,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ),
      );
}

enum _Kind {
  none,
  navigate,
  checkbox,
  radio,
  switchControl,
  iconButton,
  button,
  value,
  meta,
  custom,
  iconButtons,
  valueAndAction,
}

/// One icon button of [PortalListAccessory.iconButtons].
class PortalListIconAction {
  const PortalListIconAction({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;

  /// The accessible name: write it from what the handler does.
  final String tooltip;
  final VoidCallback? onPressed;
}

/// The one trailing accessory a row carries.
///
/// `navigate` means "opens a sub-page", never "next step". A control accessory
/// (checkbox, radio, switch) makes the whole row its target; an `iconButton` or
/// `button` makes only itself the target.
class PortalListAccessory {
  const PortalListAccessory._(
    this._kind, {
    this.text,
    this.unit,
    this.icon,
    this.checked = false,
    this.onChanged,
    this.onPressed,
    this.tooltip,
    this.sentiment = PortalValueSentiment.neutral,
    this.unread = false,
    this.child,
    this.actions = const [],
    this.interactive = false,
    this.swatch,
    this.tonal = false,
    this.busy = false,
    this.busyLabel,
    this.fill = false,
    this.markLabel,
    this.spoken,
  }) : assert(
            !busy || busyLabel != null, 'a busy accessory announces busyLabel');

  final _Kind _kind;
  final String? text;
  final String? unit;
  final IconData? icon;
  final bool checked;
  final ValueChanged<bool>? onChanged;
  final VoidCallback? onPressed;
  final String? tooltip;
  final PortalValueSentiment sentiment;
  final bool unread;
  final Widget? child;
  final List<PortalListIconAction> actions;

  /// A custom [child] that is a control and keeps its own semantics.
  final bool interactive;

  /// The accent dot [PortalListAccessory.navigate] draws in place of its value.
  final Color? swatch;

  /// [PortalListAccessory.iconButton] paints a neutral fill behind the glyph.
  final bool tonal;

  /// [PortalListAccessory.button] in flight, and what it announces meanwhile.
  final bool busy;
  final String? busyLabel;

  /// [PortalListAccessory.value] fills its Symbols glyph.
  final bool fill;

  /// [PortalListAccessory.meta]: the name of its [icon], and the long form of
  /// its time.
  final String? markLabel;
  final String? spoken;

  static const none = PortalListAccessory._(_Kind.none);

  /// A chevron; [value] is the muted current value ("Theme · System ›").
  /// [swatch] draws a 20 dp colour dot in place of that text (an accent
  /// picker); [value] still names it in the row's label.
  const PortalListAccessory.navigate({String? value, Color? swatch})
      : this._(_Kind.navigate, text: value, swatch: swatch);

  const PortalListAccessory.checkbox({
    required bool checked,
    required ValueChanged<bool>? onChanged,
  }) : this._(_Kind.checkbox, checked: checked, onChanged: onChanged);

  const PortalListAccessory.radio({
    required bool checked,
    required ValueChanged<bool>? onChanged,
  }) : this._(_Kind.radio, checked: checked, onChanged: onChanged);

  const PortalListAccessory.switchControl({
    required bool checked,
    required ValueChanged<bool>? onChanged,
  }) : this._(_Kind.switchControl, checked: checked, onChanged: onChanged);

  /// [tooltip] names it for a screen reader: write it from what the handler does.
  /// [tonal] paints a neutral-fill disc behind the glyph: a quick action meant
  /// to read as a control (a habit's +1), not the ghost icon of a quiet row.
  const PortalListAccessory.iconButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback? onPressed,
    bool tonal = false,
  }) : this._(_Kind.iconButton,
            icon: icon, tooltip: tooltip, onPressed: onPressed, tonal: tonal);

  /// [tooltip] is the accessible name when [label] alone is ambiguous
  /// ("Update Gym"). [busy] is the button in flight (a Stop while the job winds
  /// down): a spinner in the pill, no taps, no greying out, and [busyLabel] is
  /// what it announces, so pass `onPressed: null` with it.
  const PortalListAccessory.button({
    required String label,
    required VoidCallback? onPressed,
    String? tooltip,
    bool busy = false,
    String? busyLabel,
  }) : this._(_Kind.button,
            text: label,
            onPressed: onPressed,
            tooltip: tooltip,
            busy: busy,
            busyLabel: busyLabel);

  /// A right-column value: tabular, never wraps. [unit] follows a space. [fill]
  /// fills the Symbols glyph: the value is set (a rating's star).
  const PortalListAccessory.value(
    String value, {
    String? unit,
    IconData? icon,
    PortalValueSentiment sentiment = PortalValueSentiment.neutral,
    bool fill = false,
  }) : this._(_Kind.value,
            text: value,
            unit: unit,
            icon: icon,
            sentiment: sentiment,
            fill: fill);

  /// An inbox row's trailing: the time over a primary dot ([unread]) or a
  /// muted status glyph ([icon]: pinned, waiting to sync), named by
  /// [markLabel]. [spoken] is the long form a screen reader hears of [time]
  /// ("Friday" for "Fri").
  const PortalListAccessory.meta(
    String time, {
    bool unread = false,
    IconData? icon,
    String? markLabel,
    String? spoken,
  }) : this._(_Kind.meta,
            text: time,
            unread: unread,
            icon: icon,
            markLabel: markLabel,
            spoken: spoken);

  /// Any widget in the trailing slot (an amount over a badge). The row reads
  /// as one label, so say what the widget shows in [semanticLabel]. A
  /// decorative child is left out of semantics; an [interactive] one (a
  /// button, a checkbox) keeps its own and is *not* part of the row's label.
  const PortalListAccessory.widget(
    Widget child, {
    String? semanticLabel,
    bool interactive = false,
  }) : this._(_Kind.custom,
            child: child, text: semanticLabel, interactive: interactive);

  /// A right-column [value] plus an icon button beside it (an amount and a
  /// "mark paid" action). The value is in the row's label, the button is its
  /// own target named by [tooltip].
  const PortalListAccessory.valueAndAction(
    String value, {
    String? unit,
    PortalValueSentiment sentiment = PortalValueSentiment.neutral,
    required IconData icon,
    required String tooltip,
    required VoidCallback? onPressed,
  }) : this._(_Kind.valueAndAction,
            text: value,
            unit: unit,
            sentiment: sentiment,
            icon: icon,
            tooltip: tooltip,
            onPressed: onPressed);

  /// Several icon buttons side by side; each is its own target and name.
  const PortalListAccessory.iconButtons(List<PortalListIconAction> actions)
      : this._(_Kind.iconButtons, actions: actions);

  bool get _wholeRow =>
      _kind == _Kind.checkbox ||
      _kind == _Kind.radio ||
      _kind == _Kind.switchControl;

  /// Keeps its own semantics instead of merging into the row's label.
  bool get _keepsSemantics =>
      _kind == _Kind.iconButton ||
      _kind == _Kind.iconButtons ||
      _kind == _Kind.button ||
      _kind == _Kind.valueAndAction ||
      (_kind == _Kind.custom && interactive);
}

/// The list row: leading, text, one trailing accessory.
///
/// A row that sends a prompt is not a list item: starters are
/// `PortalPromptCard`. List items navigate, toggle, pick or show a value.
/// Interactive is the whole row *or* the accessory only, never mixed in one
/// section. Announces title, value, then subtitle.
class PortalListItem extends StatelessWidget {
  const PortalListItem({
    super.key,
    required this.title,
    this.subtitle,
    this.meta,
    this.leading,
    this.inverted = false,
    this.trailing = PortalListAccessory.none,
    this.onTap,
    this.disabledReason,
    this.isNew = false,
    this.subtitleWidget,
    this.metaWidget,
    this.progress,
    this.progressColor,
    this.progressLabel,
    this.onLongPress,
    this.destructive = false,
    this.dimmed = false,
    this.struck = false,
    this.titleMaxLines = 1,
    this.overline,
    this.chips,
    this.semanticLabel,
    this.live,
    this.titleSpans,
    this.subtitleSpans,
    this.done = false,
    this.edit,
  })  : _skeleton = false,
        _skeletonLeading = null,
        _skeletonMeter = false;

  /// A checklist row (a subtask): a switch for the control and [done] striking
  /// and muting the title, together so no call site can pair the one without
  /// the other. The whole row is the target.
  ///
  /// [onEdit] adds a pencil button after the switch, its own target and its
  /// own node, named [editTooltip] ("Rename subtask"): the row's one accessory
  /// is the switch, so the edit control sits beside the row.
  factory PortalListItem.checklist({
    Key? key,
    required String title,
    required bool done,
    required ValueChanged<bool>? onChanged,
    String? subtitle,
    PortalListLeading? leading,
    VoidCallback? onEdit,
    String editTooltip = 'Edit',
  }) =>
      PortalListItem(
        key: key,
        title: title,
        subtitle: subtitle,
        leading: leading,
        done: done,
        trailing: PortalListAccessory.switchControl(
            checked: done, onChanged: onChanged),
        edit: onEdit == null
            ? null
            : PortalListIconAction(
                icon: Icons.edit_outlined,
                tooltip: editTooltip,
                onPressed: onEdit,
              ),
      );

  /// Shaped like the row, its leading too: [PortalSkeletonLeading.avatar]
  /// (default), `.tile` or `.none`. [meter] adds the track and label of a row's
  /// [progress] under the text.
  // ponytail: one label bar; a [meter] row with two caption labels would want
  // the kit's none/start/both choice.
  const PortalListItem.skeleton({
    super.key,
    PortalSkeletonLeading leading = PortalSkeletonLeading.avatar,
    bool meter = false,
  })  : title = '',
        subtitle = null,
        meta = null,
        leading = null,
        inverted = false,
        trailing = PortalListAccessory.none,
        onTap = null,
        disabledReason = null,
        isNew = false,
        subtitleWidget = null,
        metaWidget = null,
        progress = null,
        progressColor = null,
        progressLabel = null,
        onLongPress = null,
        destructive = false,
        dimmed = false,
        struck = false,
        titleMaxLines = 1,
        overline = null,
        chips = null,
        semanticLabel = null,
        live = null,
        titleSpans = null,
        subtitleSpans = null,
        done = false,
        edit = null,
        _skeleton = true,
        _skeletonLeading = leading,
        _skeletonMeter = meter;

  final String title;

  /// Up to two lines.
  final String? subtitle;
  final String? meta;
  final PortalListLeading? leading;

  /// Subtitle first, title second.
  final bool inverted;
  final PortalListAccessory trailing;

  /// Whole-row target for a row with no chevron. A `navigate` accessory or a
  /// control accessory is already whole-row: they take [onTap] or their own
  /// handler.
  final VoidCallback? onTap;

  /// Disables the row and says why, under the subtitle, as an inline prompt.
  final String? disabledReason;

  /// Title and meta go to 700, and the label says "new" so colour is not alone.
  final bool isNew;

  /// Replace [subtitle] / [meta] with any widget (a chip row, rich text with
  /// inline amounts). A widget is not in the row's label.
  final Widget? subtitleWidget;
  final Widget? metaWidget;

  /// 0..1: a track across the full row under the text, [progressColor] its
  /// fill, [progressLabel] a line under it.
  final double? progress;
  final Color? progressColor;
  final Widget? progressLabel;

  final VoidCallback? onLongPress;

  /// The title in the error colour, for a row that deletes or signs out.
  final bool destructive;

  /// Fades the whole row to half (an archived, done or inactive row) without
  /// disabling it or changing what a screen reader says. A row that cannot be
  /// used is [disabledReason], not this.
  final bool dimmed;

  /// Strikes the title through (a done task, a ticked item). Pair it with
  /// [dimmed] if the whole row should recede; a screen reader still reads the
  /// same label, so say "done" in [subtitle] or the accessory if it matters.
  final bool struck;

  /// Lines the title may take before it ellipsizes. Default 1.
  final int titleMaxLines;

  /// An eyebrow above the title, drawn uppercase in the `overline` token and
  /// the primary colour: marks one row (next up). It leads the row's label.
  final String? overline;

  /// Row metadata under the subtitle, wrapped: [PortalBadge]s (category,
  /// priority, due). A row stays two lines of text plus this; more than four
  /// chips is a detail page's job. A [PortalBadge]'s label joins the row's
  /// label; any other widget is decorative.
  final List<Widget>? chips;

  /// Replaces the composed title, value, subtitle label.
  final String? semanticLabel;

  /// A reply still being written: typing dots and these words in the
  /// subtitle's slot, announced as a live region as the row changes.
  final String? live;

  /// Painted in place of [title] / [subtitle] in the row's own style (a
  /// search's marks); the row still reads [title] and [subtitle].
  final List<InlineSpan>? titleSpans;
  final List<InlineSpan>? subtitleSpans;

  /// A finished checklist item: [struck] through, and the title muted. See
  /// [PortalListItem.checklist].
  final bool done;

  /// An icon button after the trailing, beside the row rather than in it; its
  /// [PortalListIconAction.tooltip] is its name and it keeps its own node.
  final PortalListIconAction? edit;

  final bool _skeleton;
  final PortalSkeletonLeading? _skeletonLeading;
  final bool _skeletonMeter;

  /// Where a section's divider starts: the text column.
  double get textInset => switch ((_skeleton, leading, _skeletonLeading)) {
        (true, _, PortalSkeletonLeading.none) => 0,
        (true, _, _) => 40 + 16,
        (_, final PortalListLeading l, _) => l.extent + 16,
        _ => 0,
      };

  @override
  Widget build(BuildContext context) {
    final portal = PortalUiTheme.of(context);
    final tokens = portal.tokens;
    final cs = Theme.of(context).colorScheme;
    final sp = tokens.spacing;
    final styles = tokens.textStyles;
    final disabled = disabledReason != null;
    final detail = _ListScope.detailOf(context);

    if (_skeleton) {
      final skeleton = ExcludeSemantics(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: sp.lg, vertical: sp.md),
          child: Row(children: [
            if (_skeletonLeading != PortalSkeletonLeading.none) ...[
              PortalSkeleton(
                width: 40,
                height: 40,
                shape: _skeletonLeading == PortalSkeletonLeading.avatar
                    ? BoxShape.circle
                    : BoxShape.rectangle,
                borderRadius: BorderRadius.circular(tokens.radii.sm),
              ),
              SizedBox(width: sp.lg),
            ],
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PortalSkeleton(width: 160),
                  SizedBox(height: 8),
                  PortalSkeleton(width: 100, height: 11),
                ],
              ),
            ),
            const PortalSkeleton(width: 48),
          ]),
        ),
      );
      if (!_skeletonMeter) return skeleton;
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          skeleton,
          ExcludeSemantics(
            child: Padding(
              padding: EdgeInsetsDirectional.only(
                  start: sp.lg + textInset, end: sp.lg, bottom: sp.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  PortalSkeleton(
                    height: sp.xs,
                    borderRadius: BorderRadius.circular(tokens.radii.full),
                  ),
                  SizedBox(height: sp.sm),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: PortalSkeleton(width: sp.xxxl * 2, height: sp.md),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    Text text(String s, List<InlineSpan>? spans, int lines, TextStyle style) =>
        spans == null
            ? Text(s,
                maxLines: lines, overflow: TextOverflow.ellipsis, style: style)
            : Text.rich(TextSpan(children: spans),
                maxLines: lines, overflow: TextOverflow.ellipsis, style: style);

    final heavy = isNew ? FontWeight.w700 : null;
    final titleText = text(
      title,
      titleSpans,
      titleMaxLines,
      styles.body.copyWith(
        decoration: struck || done ? TextDecoration.lineThrough : null,
        color: disabled
            ? cs.onSurface.withValues(alpha: 0.38)
            : destructive
                ? cs.error
                : done || detail
                    ? cs.onSurfaceVariant
                    : cs.onSurface,
        fontWeight: heavy ?? (detail ? FontWeight.w400 : FontWeight.w500),
      ),
    );
    final subtitleText = live != null
        ? Row(mainAxisSize: MainAxisSize.min, children: [
            const PortalTypingDots(),
            SizedBox(width: sp.sm),
            Flexible(
              child: Text(
                live!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: styles.caption.copyWith(
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
              ),
            ),
          ])
        : subtitleWidget ??
            (subtitle == null
                ? null
                : text(
                    subtitle!,
                    subtitleSpans,
                    2,
                    styles.caption.copyWith(
                      color: isNew ? cs.onSurface : cs.onSurfaceVariant,
                    ),
                  ));
    final textColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (overline != null)
          Text(overline!.toUpperCase(),
              style: styles.overline.copyWith(color: cs.primary)),
        if (inverted && subtitleText != null) subtitleText,
        titleText,
        if (!inverted && subtitleText != null) subtitleText,
        if (chips != null && chips!.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(top: sp.xs),
            child: Wrap(
              spacing: sp.xs,
              runSpacing: sp.xs,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: chips!,
            ),
          ),
        if (metaWidget != null)
          metaWidget!
        else if (meta != null)
          Text(meta!,
              style: styles.caption.copyWith(color: cs.onSurfaceVariant)),
        if (disabled)
          Padding(
            padding: EdgeInsets.only(top: sp.xs + 2),
            // The row's hint carries it, so it is not a live region of its own.
            child: ExcludeSemantics(
              child: PortalPrompt(
                message: disabledReason!,
                size: PortalPromptSize.inline,
              ),
            ),
          ),
      ],
    );

    final acc = trailing;
    final tapTarget = tokens.minTapTarget;
    Widget? accessory;
    Widget valueRow({bool withIcon = true}) {
      final sem = PortalSemanticColors.of(context);
      final color = switch (acc.sentiment) {
        PortalValueSentiment.positive => sem.success,
        PortalValueSentiment.negative => cs.error,
        PortalValueSentiment.dim ||
        PortalValueSentiment.meta =>
          cs.onSurfaceVariant,
        PortalValueSentiment.neutral => cs.onSurface,
      };
      final base = acc.sentiment == PortalValueSentiment.meta
          ? styles.caption
          : styles.body;
      return Row(mainAxisSize: MainAxisSize.min, children: [
        if (withIcon && acc.icon != null) ...[
          Icon(acc.icon, size: 18, fill: acc.fill ? 1 : null, color: color),
          SizedBox(width: sp.xs),
        ],
        Text(
          acc.unit == null ? acc.text! : '${acc.text} ${acc.unit}',
          softWrap: false,
          style: base.copyWith(
            color: color,
            fontWeight: acc.sentiment == PortalValueSentiment.dim
                ? FontWeight.w400
                : FontWeight.w500,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ]);
    }

    switch (acc._kind) {
      case _Kind.none:
        break;
      case _Kind.navigate:
        accessory = Row(mainAxisSize: MainAxisSize.min, children: [
          if (acc.swatch != null)
            Padding(
              padding: EdgeInsets.only(right: sp.xs),
              child: ExcludeSemantics(
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                      color: acc.swatch, shape: BoxShape.circle),
                ),
              ),
            )
          else if (acc.text != null)
            Padding(
              padding: EdgeInsets.only(right: sp.xs),
              child: Text(
                acc.text!,
                style: styles.body.copyWith(
                  color: detail ? cs.onSurface : cs.onSurfaceVariant,
                  fontWeight: detail ? FontWeight.w500 : null,
                ),
              ),
            ),
          ExcludeSemantics(
            child: Icon(Icons.chevron_right, size: 20, color: cs.outline),
          ),
        ]);
      case _Kind.checkbox:
        accessory = ExcludeSemantics(
          child: Checkbox(
            value: acc.checked,
            onChanged: disabled || acc.onChanged == null
                ? null
                : (v) => acc.onChanged!(v ?? false),
          ),
        );
      case _Kind.radio:
        accessory = ExcludeSemantics(
          child: Icon(
            acc.checked
                ? Icons.radio_button_checked
                : Icons.radio_button_unchecked,
            color: acc.checked ? cs.primary : cs.outline,
          ),
        );
      case _Kind.switchControl:
        accessory = ExcludeSemantics(
          child: Switch(
            value: acc.checked,
            onChanged: disabled ? null : acc.onChanged,
          ),
        );
      case _Kind.iconButton:
        accessory = IconButton(
          icon: Icon(acc.icon),
          tooltip: acc.tooltip,
          style: acc.tonal
              ? IconButton.styleFrom(backgroundColor: cs.surfaceContainerHigh)
              : null,
          onPressed: disabled ? null : acc.onPressed,
        );
      case _Kind.custom:
        accessory = acc.child;
      case _Kind.iconButtons:
        accessory = Row(mainAxisSize: MainAxisSize.min, children: [
          for (final a in acc.actions)
            IconButton(
              icon: Icon(a.icon),
              tooltip: a.tooltip,
              onPressed: disabled ? null : a.onPressed,
            ),
        ]);
      case _Kind.button:
        // Busy refuses taps without greying out: the disabled colours are the
        // enabled ones, and the spinner says why.
        final busyName = acc.busy ? acc.busyLabel! : null;
        accessory = Tooltip(
          message: busyName ?? acc.tooltip ?? acc.text!,
          child: FilledButton.tonal(
            onPressed: disabled || acc.busy ? null : acc.onPressed,
            style: FilledButton.styleFrom(
              minimumSize: Size(tapTarget, tapTarget),
              backgroundColor: cs.surfaceContainerHigh,
              foregroundColor: cs.onSurface,
              disabledBackgroundColor:
                  acc.busy ? cs.surfaceContainerHigh : null,
              disabledForegroundColor: acc.busy ? cs.onSurface : null,
            ),
            child: busyName == null
                ? Text(acc.text!)
                : Row(mainAxisSize: MainAxisSize.min, children: [
                    SizedBox.square(
                      dimension: styles.body.fontSize,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: cs.onSurface,
                        value:
                            MediaQuery.disableAnimationsOf(context) ? .25 : null,
                      ),
                    ),
                    SizedBox(width: sp.sm),
                    Text(busyName),
                  ]),
          ),
        );
      case _Kind.value:
        accessory = valueRow();
      case _Kind.valueAndAction:
        accessory = Row(mainAxisSize: MainAxisSize.min, children: [
          ExcludeSemantics(child: valueRow(withIcon: false)),
          IconButton(
            icon: Icon(acc.icon),
            tooltip: acc.tooltip,
            onPressed: disabled ? null : acc.onPressed,
          ),
        ]);
      case _Kind.meta:
        accessory = Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              acc.text!,
              style: styles.caption.copyWith(
                color: isNew ? cs.onSurface : cs.onSurfaceVariant,
                fontWeight: heavy,
              ),
            ),
            SizedBox(height: sp.xs),
            if (acc.unread)
              Container(
                width: 10,
                height: 10,
                decoration:
                    BoxDecoration(color: cs.primary, shape: BoxShape.circle),
              )
            else if (acc.icon != null)
              Icon(acc.icon, size: 18, color: cs.onSurfaceVariant),
          ],
        );
    }

    VoidCallback? rowTap = disabled ? null : onTap;
    if (!disabled && acc._wholeRow && acc.onChanged != null) {
      rowTap = () => acc.onChanged!(
            acc._kind == _Kind.radio ? true : !acc.checked,
          );
    }

    final labelParts = [
      overline,
      title,
      if (acc._kind == _Kind.value || acc._kind == _Kind.valueAndAction)
        acc.text,
      if (acc._kind == _Kind.navigate ||
          (acc._kind == _Kind.custom && !acc.interactive))
        acc.text,
      subtitle,
      meta,
      if (acc._kind == _Kind.meta) acc.spoken ?? acc.text,
      if (acc._kind == _Kind.meta && !acc.unread) acc.markLabel,
      live,
      for (final c in chips ?? const <Widget>[])
        if (c is PortalBadge) c.label,
      if (isNew) 'new',
    ].whereType<String>().where((s) => s.isNotEmpty);

    final keepsSemantics =
        acc._keepsSemantics || leading?.interactive == true || edit != null;

    Widget row = ConstrainedBox(
      constraints: BoxConstraints(minHeight: tapTarget + sp.md),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: sp.lg, vertical: sp.sm),
        // A disabled row dims to 38% and top-aligns its leading and trailing to
        // the title line, so the reason under the subtitle reads at full
        // contrast.
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: disabled
                  ? CrossAxisAlignment.start
                  : CrossAxisAlignment.center,
              children: [
                if (leading != null) ...[
                  Opacity(
                    opacity: disabled ? .38 : 1,
                    child: leading!._build(context),
                  ),
                  SizedBox(width: sp.lg),
                ],
                Expanded(
                  // The row's label already says it; a control beside it
                  // keeps its own node, so the text must not read twice.
                  child: keepsSemantics
                      ? ExcludeSemantics(child: textColumn)
                      : textColumn,
                ),
                if (accessory != null) ...[
                  SizedBox(width: sp.md),
                  Opacity(
                    opacity: disabled ? .38 : 1,
                    // Only the leading is interactive: the row's label already
                    // reads this accessory's text, so it must not read twice.
                    child: keepsSemantics && !acc._keepsSemantics
                        ? ExcludeSemantics(child: accessory)
                        : accessory,
                  ),
                ],
                if (edit != null)
                  Opacity(
                    opacity: disabled ? .38 : 1,
                    child: IconButton(
                      icon: Icon(edit!.icon),
                      tooltip: edit!.tooltip,
                      onPressed: disabled ? null : edit!.onPressed,
                    ),
                  ),
              ],
            ),
            if (progress != null) ...[
              SizedBox(height: sp.md),
              PortalProgress(
                value: progress!,
                fillColor: progressColor,
                height: sp.xs,
              ),
              if (progressLabel != null) ...[
                SizedBox(height: sp.sm),
                progressLabel!,
              ],
            ],
          ],
        ),
      ),
    );

    if (dimmed) row = Opacity(opacity: .5, child: row);

    final rowLongPress = disabled ? null : onLongPress;
    if (rowTap != null || rowLongPress != null) {
      row = PortalPressable(
        onTap: rowTap,
        onLongPress: rowLongPress,
        child: row,
      );
    }

    return Semantics(
      container: true,
      explicitChildNodes: keepsSemantics,
      button: rowTap != null && acc._kind == _Kind.navigate,
      checked: acc._kind == _Kind.checkbox || acc._kind == _Kind.radio
          ? acc.checked
          : null,
      toggled: acc._kind == _Kind.switchControl ? acc.checked : null,
      inMutuallyExclusiveGroup: acc._kind == _Kind.radio ? true : null,
      enabled: !disabled,
      liveRegion: live == null ? null : true,
      label: semanticLabel ?? labelParts.join(', '),
      hint: disabledReason,
      onTap: rowTap,
      excludeSemantics: !keepsSemantics,
      child: row,
    );
  }
}

/// What the skeleton row draws in the leading slot.
enum PortalSkeletonLeading { avatar, tile, none }

/// How a [PortalListSection] frames its rows.
enum PortalListStyle { inset, fullBleed }

/// A header over rows. `inset` is a grouped card at `radius.lg` painted
/// `portal.card`; dividers start at the text column and none follows the last
/// row. One style per screen: inset or full-bleed, never both. A screen of
/// inset sections is a grouped page: the page paints its own tone under it.
class PortalListSection extends StatelessWidget {
  const PortalListSection({
    super.key,
    this.header,
    this.headerAction,
    this.captionHeader = false,
    this.style = PortalListStyle.inset,
    this.detail = false,
    this.onReorder,
    required this.children,
  })  : selected = null,
        _selectable = false;

  /// An inset option list for radio / checkbox rows, outlined when selected
  /// rather than filled alone. Pass [selected] to say which row.
  const PortalListSection.selectable({
    super.key,
    this.header,
    this.headerAction,
    required this.children,
    this.selected,
  })  : captionHeader = false,
        style = PortalListStyle.inset,
        detail = false,
        onReorder = null,
        _selectable = true;

  final String? header;

  /// A text action at the header's end, e.g. "See all".
  final Widget? headerAction;

  /// The caption header style, for a feed's date buckets only; section headers
  /// stay subtitle.
  final bool captionHeader;
  final PortalListStyle style;

  /// Label-to-value rows with no leading: the label muted, the value ink.
  final bool detail;

  /// Drag-to-reorder: the rows become a reorderable list. Each of [children]
  /// needs a key and carries its own [PortalReorderHandle] (so the drag is the
  /// handle's, never the row's, and a row's swipe still works). Called with
  /// the index the row left and the one it lands at, once the row is out of
  /// the list: `list.insert(to, list.removeAt(from))`. Null, the default, is
  /// a plain column.
  // ponytail: the list is its own (non-scrolling) Scrollable, so a drag does
  // not autoscroll the page; fine for a short section.
  final void Function(int from, int to)? onReorder;

  /// Usually [PortalListItem]s; any widget (a foreign `ListTile`, a platform
  /// control) may sit in a section and gets the same dividers, which start at
  /// a row's text column and at the edge for anything that is not one.
  final List<Widget> children;
  final int? selected;
  final bool _selectable;

  @override
  Widget build(BuildContext context) {
    assert(onReorder == null || children.every((c) => c.key != null),
        'onReorder needs a key on every child');
    final portal = PortalUiTheme.of(context);
    final tokens = portal.tokens;
    final cs = Theme.of(context).colorScheme;
    final sp = tokens.spacing;
    final inset = style == PortalListStyle.inset;

    final rows = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      final item = children[i];
      Widget w = item;
      if (_selectable && selected == i) {
        w = DecoratedBox(
          position: DecorationPosition.foreground,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(tokens.radii.lg),
            border: Border.all(color: cs.primary, width: 1.5),
          ),
          child: w,
        );
      }
      rows.add(w);
      if (i < children.length - 1 && !_selectable) {
        rows.add(Divider(
          height: 1,
          thickness: 1,
          indent: sp.lg + _textInset(item),
          color: cs.outlineVariant,
        ));
      }
    }

    Widget list = Column(children: rows);
    final reorder = onReorder;
    if (reorder != null) {
      // [rows] alternates row, divider (never selectable here): each row is
      // one keyed cell with its divider, so a lifted row carries its rule.
      list = ReorderableListView(
        shrinkWrap: true,
        primary: false,
        physics: const NeverScrollableScrollPhysics(),
        buildDefaultDragHandles: false,
        onReorderItem: reorder,
        // The lifted row is drawn in the overlay, off the card: give it the
        // card's surface and a soft shadow, not Material's.
        proxyDecorator: (child, _, __) => DecoratedBox(
          decoration: BoxDecoration(
            boxShadow: tokens.elevation.soft(Theme.of(context).brightness),
          ),
          child: Material(
            color: inset
                ? portal.card
                : Theme.of(context).scaffoldBackgroundColor,
            child: child,
          ),
        ),
        children: [
          for (var i = 0; i < rows.length; i += 2)
            Column(
              key: ValueKey(children[i ~/ 2].key),
              mainAxisSize: MainAxisSize.min,
              children: rows.skip(i).take(2).toList(),
            ),
        ],
      );
    }

    Widget body = _ListScope(detail: detail, child: list);
    if (inset) {
      body = Material(
        color: portal.card,
        borderRadius: BorderRadius.circular(tokens.radii.lg),
        clipBehavior: Clip.antiAlias,
        child: body,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (header != null)
          _sectionHeader(tokens, cs, header!, captionHeader, headerAction),
        Padding(
          padding:
              inset ? EdgeInsets.symmetric(horizontal: sp.lg) : EdgeInsets.zero,
          child: Semantics(
            container: true,
            child: _selectable
                ? Semantics(inMutuallyExclusiveGroup: true, child: body)
                : body,
          ),
        ),
      ],
    );
  }
}

/// Tells the rows of a `detail` section to read as label-to-value.
class _ListScope extends InheritedWidget {
  const _ListScope({required this.detail, required super.child});

  final bool detail;

  static bool detailOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_ListScope>()?.detail ?? false;

  @override
  bool updateShouldNotify(_ListScope old) => detail != old.detail;
}

double _textInset(Widget w) => w is PortalListItem ? w.textInset : 0;

Widget _sectionHeader(DesignTokens tokens, ColorScheme cs, String header,
    bool caption, Widget? action) {
  final sp = tokens.spacing;
  return Padding(
    padding: EdgeInsets.fromLTRB(sp.lg, sp.lg, sp.lg, sp.sm),
    child: caption
        ? Text(header,
            style:
                tokens.textStyles.caption.copyWith(color: cs.onSurfaceVariant))
        : PortalSectionHeader(title: header, trailing: action),
  );
}

/// [PortalListSection] for a long list: a sliver that builds only the rows in
/// view, so a list is one section rather than one section per row. Same frame
/// (header, inset card, dividers from each [PortalListItem]'s text column);
/// put it in a `CustomScrollView`.
// ponytail: the card is painted per row (a `Material` with the corners only on
// the first and last) so ink stays above it; a row builder that returns a
// foreign widget gets the same Material but a divider at the edge.
class PortalSliverListSection extends StatelessWidget {
  const PortalSliverListSection({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.header,
    this.headerAction,
    this.captionHeader = false,
    this.style = PortalListStyle.inset,
    this.detail = false,
  });

  final int itemCount;
  final NullableIndexedWidgetBuilder itemBuilder;
  final String? header;
  final Widget? headerAction;
  final bool captionHeader;
  final PortalListStyle style;
  final bool detail;

  @override
  Widget build(BuildContext context) {
    final portal = PortalUiTheme.of(context);
    final tokens = portal.tokens;
    final cs = Theme.of(context).colorScheme;
    final sp = tokens.spacing;
    final inset = style == PortalListStyle.inset;
    final r = Radius.circular(tokens.radii.lg);

    final list = SliverList.builder(
      itemCount: itemCount,
      itemBuilder: (c, i) {
        final w = itemBuilder(c, i) ?? const SizedBox.shrink();
        final last = i == itemCount - 1;
        Widget row = _ListScope(
          detail: detail,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            w,
            if (!last)
              Divider(
                height: 1,
                thickness: 1,
                indent: sp.lg + _textInset(w),
                color: cs.outlineVariant,
              ),
          ]),
        );
        if (inset) {
          row = Material(
            color: portal.card,
            borderRadius: BorderRadius.vertical(
              top: i == 0 ? r : Radius.zero,
              bottom: last ? r : Radius.zero,
            ),
            clipBehavior: Clip.antiAlias,
            child: row,
          );
        }
        return row;
      },
    );
    return SliverMainAxisGroup(slivers: [
      if (header != null)
        SliverToBoxAdapter(
          child:
              _sectionHeader(tokens, cs, header!, captionHeader, headerAction),
        ),
      inset
          ? SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: sp.lg), sliver: list)
          : list,
    ]);
  }
}
