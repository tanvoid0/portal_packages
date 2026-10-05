import 'package:flutter/material.dart';

import '../theme/portal_semantic_colors.dart';
import '../theme/portal_ui_theme.dart';
import '../tokens/design_tokens.dart';
import 'portal_avatar_mark.dart';
import 'portal_icon_tile.dart';
import 'portal_pressable.dart';
import 'portal_progress.dart';
import 'portal_prompt.dart';
import 'portal_section_header.dart';
import 'portal_skeleton.dart';

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
  });

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

  static const none = PortalListAccessory._(_Kind.none);

  /// A chevron; [value] is the muted current value ("Theme · System ›").
  const PortalListAccessory.navigate({String? value})
      : this._(_Kind.navigate, text: value);

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
  const PortalListAccessory.iconButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback? onPressed,
  }) : this._(_Kind.iconButton,
            icon: icon, tooltip: tooltip, onPressed: onPressed);

  /// [tooltip] is the accessible name when [label] alone is ambiguous
  /// ("Update Gym").
  const PortalListAccessory.button({
    required String label,
    required VoidCallback? onPressed,
    String? tooltip,
  }) : this._(_Kind.button,
            text: label, onPressed: onPressed, tooltip: tooltip);

  /// A right-column value: tabular, never wraps. [unit] follows a space.
  const PortalListAccessory.value(
    String value, {
    String? unit,
    IconData? icon,
    PortalValueSentiment sentiment = PortalValueSentiment.neutral,
  }) : this._(_Kind.value,
            text: value, unit: unit, icon: icon, sentiment: sentiment);

  /// An inbox row's trailing: the time over a primary dot ([unread]) or a
  /// muted status glyph ([icon]: pinned, waiting to sync).
  const PortalListAccessory.meta(
    String time, {
    bool unread = false,
    IconData? icon,
  }) : this._(_Kind.meta, text: time, unread: unread, icon: icon);

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
  })  : _skeleton = false,
        _skeletonLeading = null;

  /// Shaped like the row, its leading too: [PortalSkeletonLeading.avatar]
  /// (default), `.tile` or `.none`.
  const PortalListItem.skeleton({
    super.key,
    PortalSkeletonLeading leading = PortalSkeletonLeading.avatar,
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
        _skeleton = true,
        _skeletonLeading = leading;

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

  final bool _skeleton;
  final PortalSkeletonLeading? _skeletonLeading;

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
      return ExcludeSemantics(
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
    }

    final heavy = isNew ? FontWeight.w700 : null;
    final titleText = Text(
      title,
      maxLines: titleMaxLines,
      overflow: TextOverflow.ellipsis,
      style: styles.body.copyWith(
        decoration: struck ? TextDecoration.lineThrough : null,
        color: disabled
            ? cs.onSurface.withValues(alpha: 0.38)
            : destructive
                ? cs.error
                : detail
                    ? cs.onSurfaceVariant
                    : cs.onSurface,
        fontWeight: heavy ?? (detail ? FontWeight.w400 : FontWeight.w500),
      ),
    );
    final subtitleText = subtitleWidget ??
        (subtitle == null
            ? null
            : Text(
                subtitle!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: styles.caption.copyWith(
                  color: isNew ? cs.onSurface : cs.onSurfaceVariant,
                ),
              ));
    final textColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (inverted && subtitleText != null) subtitleText,
        titleText,
        if (!inverted && subtitleText != null) subtitleText,
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
          Icon(acc.icon, size: 18, color: color),
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
          if (acc.text != null)
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
        accessory = Tooltip(
          message: acc.tooltip ?? acc.text!,
          child: FilledButton.tonal(
            onPressed: disabled ? null : acc.onPressed,
            style: FilledButton.styleFrom(
              minimumSize: Size(tapTarget, tapTarget),
              backgroundColor: cs.surfaceContainerHigh,
              foregroundColor: cs.onSurface,
            ),
            child: Text(acc.text!),
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
      title,
      if (acc._kind == _Kind.value || acc._kind == _Kind.valueAndAction)
        acc.text,
      if (acc._kind == _Kind.navigate ||
          (acc._kind == _Kind.custom && !acc.interactive))
        acc.text,
      subtitle,
      if (isNew) 'new',
    ].whereType<String>().where((s) => s.isNotEmpty);

    final keepsSemantics = acc._keepsSemantics || leading?.interactive == true;

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
                  Opacity(opacity: disabled ? .38 : 1, child: accessory),
                ],
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
      label: labelParts.join(', '),
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

  /// Usually [PortalListItem]s; any widget (a foreign `ListTile`, a platform
  /// control) may sit in a section and gets the same dividers, which start at
  /// a row's text column and at the edge for anything that is not one.
  final List<Widget> children;
  final int? selected;
  final bool _selectable;

  @override
  Widget build(BuildContext context) {
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

    Widget body = _ListScope(detail: detail, child: Column(children: rows));
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
