import 'package:flutter/material.dart';

import '../theme/portal_semantic_colors.dart';
import '../theme/portal_ui_theme.dart';
import 'portal_avatar_mark.dart';
import 'portal_pressable.dart';
import 'portal_prompt.dart';
import 'portal_section_header.dart';
import 'portal_skeleton.dart';

/// Tint of a 40 dp tonal tile: `primaryContainer`, `tertiaryContainer` for
/// read-only status rows, `errorContainer` for destructive ones. Never a grey
/// secondary chip.
enum PortalListTone { primary, tertiary, error }

/// How a [PortalListItem.value] reads. Never the only signal: pair
/// positive/negative with a sign or an icon.
enum PortalValueSentiment { neutral, positive, negative, dim, meta }

/// What leads a row. One size per page: when any section has a 40 leading,
/// icon rows take [PortalListLeading.tile].
class PortalListLeading {
  const PortalListLeading._(this.extent, this._build);

  /// The painted width; [PortalListSection] insets its dividers by it.
  final double extent;
  final Widget Function(BuildContext) _build;

  /// A bare 24 dp icon, for dense or utility lists.
  factory PortalListLeading.icon(IconData icon) => PortalListLeading._(
        24,
        (c) => ExcludeSemantics(
          child: Icon(icon,
              size: 24, color: Theme.of(c).colorScheme.onSurfaceVariant),
        ),
      );

  /// A 40 dp tonal tile holding an icon.
  factory PortalListLeading.tile(
    IconData icon, {
    PortalListTone tone = PortalListTone.primary,
  }) =>
      PortalListLeading._(40, (c) {
        final cs = Theme.of(c).colorScheme;
        final (bg, fg) = switch (tone) {
          PortalListTone.primary => (
              cs.primaryContainer,
              cs.onPrimaryContainer
            ),
          PortalListTone.tertiary => (
              cs.tertiaryContainer,
              cs.onTertiaryContainer
            ),
          PortalListTone.error => (cs.errorContainer, cs.onErrorContainer),
        };
        return ExcludeSemantics(
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: bg,
              borderRadius:
                  BorderRadius.circular(PortalUiTheme.of(c).tokens.radii.sm),
            ),
            child: Icon(icon, size: 24, color: fg),
          ),
        );
      });

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

  bool get _wholeRow =>
      _kind == _Kind.checkbox ||
      _kind == _Kind.radio ||
      _kind == _Kind.switchControl;
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
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: styles.body.copyWith(
        color: disabled
            ? cs.onSurface.withValues(alpha: 0.38)
            : detail
                ? cs.onSurfaceVariant
                : cs.onSurface,
        fontWeight: heavy ?? (detail ? FontWeight.w400 : FontWeight.w500),
      ),
    );
    final subtitleText = subtitle == null
        ? null
        : Text(
            subtitle!,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: styles.caption.copyWith(
              color: isNew ? cs.onSurface : cs.onSurfaceVariant,
            ),
          );
    final textColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (inverted && subtitleText != null) subtitleText,
        titleText,
        if (!inverted && subtitleText != null) subtitleText,
        if (meta != null)
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
        accessory = Row(mainAxisSize: MainAxisSize.min, children: [
          if (acc.icon != null) ...[
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
      if (acc._kind == _Kind.value) acc.text,
      if (acc._kind == _Kind.navigate) acc.text,
      subtitle,
      if (isNew) 'new',
    ].whereType<String>().where((s) => s.isNotEmpty);

    Widget row = ConstrainedBox(
      constraints: BoxConstraints(minHeight: tapTarget + sp.md),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: sp.lg, vertical: sp.sm),
        // A disabled row dims to 38% and top-aligns its leading and trailing to
        // the title line, so the reason under the subtitle reads at full
        // contrast.
        child: Row(
          crossAxisAlignment:
              disabled ? CrossAxisAlignment.start : CrossAxisAlignment.center,
          children: [
            if (leading != null) ...[
              Opacity(
                opacity: disabled ? .38 : 1,
                child: leading!._build(context),
              ),
              SizedBox(width: sp.lg),
            ],
            Expanded(child: textColumn),
            if (accessory != null) ...[
              SizedBox(width: sp.md),
              Opacity(opacity: disabled ? .38 : 1, child: accessory),
            ],
          ],
        ),
      ),
    );

    if (rowTap != null) {
      row = PortalPressable(onTap: rowTap, child: row);
    }

    return Semantics(
      container: true,
      explicitChildNodes:
          acc._kind == _Kind.iconButton || acc._kind == _Kind.button,
      button: rowTap != null && acc._kind == _Kind.navigate,
      checked: acc._kind == _Kind.checkbox || acc._kind == _Kind.radio
          ? acc.checked
          : null,
      toggled: acc._kind == _Kind.switchControl ? acc.checked : null,
      inMutuallyExclusiveGroup: acc._kind == _Kind.radio ? true : null,
      enabled: !disabled,
      label: labelParts.join(', '),
      onTap: rowTap,
      excludeSemantics:
          acc._kind != _Kind.iconButton && acc._kind != _Kind.button,
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
  final List<PortalListItem> children;
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
          indent: sp.lg + item.textInset,
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
          Padding(
            padding: EdgeInsets.fromLTRB(sp.lg, sp.lg, sp.lg, sp.sm),
            child: captionHeader
                ? Text(
                    header!,
                    style: tokens.textStyles.caption
                        .copyWith(color: cs.onSurfaceVariant),
                  )
                : PortalSectionHeader(title: header!, trailing: headerAction),
          ),
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
