import 'package:flutter/material.dart';

import '../motion/portal_haptics.dart';
import '../theme/portal_component_extensions.dart';
import '../theme/portal_icons.dart';
import '../theme/portal_ui_theme.dart';
import 'portal_pressable.dart';
import 'portal_skeleton.dart';

/// [PortalFilterChip.status]: progress on a strip, apart from selection. [now]
/// is the current step, selected but with no mark (a check would read as
/// already done).
enum PortalChipStatus { done, skipped, now }

/// Selectable pill.
///
/// Selected state is carried by fill *and* border, never by fill alone — a
/// chip that only changes tint disappears for anyone who cannot separate the
/// two colours.
///
/// [exclusive] is one choice of several (a month): announced in a mutually
/// exclusive group, which [PortalFilterChipRow.semanticLabel] names. [menu]
/// adds a trailing chevron for a chip that opens an option sheet. [status]
/// marks progress on a strip. [enabled] false dims the chip, makes it inert
/// and announces it disabled; a null [onTap] alone keeps the enabled look.
/// [PortalFilterChip.action] is the chip that is never selected (a muscle that
/// opens the library, a search suggestion): heard as a button only.
class PortalFilterChip extends StatelessWidget {
  const PortalFilterChip({
    super.key,
    required this.label,
    required this.selected,
    this.onTap,
    this.icon,
    this.leading,
    this.onLongPress,
    this.selectedColor,
    this.onSelectedColor,
    this.unselectedColor,
    this.onUnselectedColor,
    this.borderColor,
    this.compact = false,
    this.onDeleted,
    this.deleteTooltip,
    this.exclusive = false,
    this.menu = false,
    this.status,
    this.enabled = true,
  })  : _action = false,
        assert(onDeleted == null || deleteTooltip != null,
            'a delete control needs deleteTooltip: it is its only name');

  const PortalFilterChip.action({
    super.key,
    required this.label,
    this.onTap,
    this.icon,
    this.leading,
    this.onLongPress,
    this.compact = false,
    this.menu = false,
    this.enabled = true,
  })  : selected = false,
        selectedColor = null,
        onSelectedColor = null,
        unselectedColor = null,
        onUnselectedColor = null,
        borderColor = null,
        onDeleted = null,
        deleteTooltip = null,
        exclusive = false,
        status = null,
        _action = true;

  final String label;
  final bool selected;
  final bool _action;

  /// Null for a chip that only displays state -- a metadata label rendered as
  /// a pill. It then takes no ink and does not announce as a button.
  final VoidCallback? onTap;

  final IconData? icon;

  /// Takes precedence over [icon] — an avatar, a colour swatch, a count.
  final Widget? leading;

  final VoidCallback? onLongPress;

  final Color? selectedColor;

  /// Label and glyph colour when selected. Must contrast with
  /// [selectedColor] — a bright brand takes an ink label, not white.
  final Color? onSelectedColor;

  final Color? unselectedColor;

  /// Label and glyph colour when not selected. Defaults to
  /// `onSurfaceVariant`; set it where the unselected fill is tinted per
  /// item rather than being the one neutral surface.
  final Color? onUnselectedColor;

  final Color? borderColor;

  /// A 32 dp painted chip for dense rows. The hit area stays `minTapTarget`
  /// (an outer box, not taller paint). Re-skin colours and height app-wide
  /// with [PortalFilterChipTheme].
  final bool compact;

  /// Adds a trailing close glyph that calls this (an input chip: a tag, a
  /// filter you can remove). The glyph's own hit area is `minTapTarget` wide
  /// and tall, over the chip's end, whatever the painted height.
  final VoidCallback? onDeleted;

  /// Names the delete control, written from what it does ("Remove vegan").
  /// Required with [onDeleted].
  final String? deleteTooltip;

  /// One choice of several: announced in a mutually exclusive group. Keep
  /// independent toggles out of it.
  final bool exclusive;

  /// A trailing chevron: this chip opens an option sheet.
  final bool menu;

  /// Progress on a strip, in place of [icon] ([leading] still wins): a done
  /// check, a skipped dash. Heard as "<label>, done" / "skipped" / "current".
  final PortalChipStatus? status;

  /// False refuses taps, dims to 38% and announces disabled.
  final bool enabled;

  /// The painted height of a [compact] chip.
  static const double _compactHeight = 32;

  @override
  Widget build(BuildContext context) {
    final portal = PortalUiTheme.of(context);
    final tokens = portal.tokens;

    final skin = PortalFilterChipTheme.of(context);
    final fill = selected
        ? (selectedColor ?? skin.selectedColor ?? portal.primary)
        : (unselectedColor ?? skin.unselectedColor ?? portal.surfaceVariant);
    final ink = selected
        ? (onSelectedColor ?? skin.onSelectedColor ?? portal.onPrimary)
        : (onUnselectedColor ??
            skin.onUnselectedColor ??
            portal.onSurfaceVariant);
    final painted =
        compact ? _compactHeight : (skin.minHeight ?? tokens.minTapTarget);
    final radius = BorderRadius.circular(tokens.radii.full);
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : tokens.motion.fast;

    final mark = switch (status) {
      PortalChipStatus.done => Icon(PortalIcons.check_circle_rounded,
          size: tokens.typeScale.md, color: portal.primary),
      PortalChipStatus.skipped => Icon(PortalIcons.remove_rounded,
          size: tokens.typeScale.md, color: portal.onSurfaceVariant),
      _ => null,
    };
    final lead = leading ?? mark;

    // Selection has to reach a screen reader too: the pressable announces
    // the button, but the state the fill and border carry visually would
    // otherwise be invisible to TalkBack.
    final chip = Semantics(
      container: onDeleted != null,
      selected: _action ? null : selected,
      inMutuallyExclusiveGroup: exclusive ? true : null,
      label: switch (status) {
        PortalChipStatus.done => '$label, done',
        PortalChipStatus.skipped => '$label, skipped',
        PortalChipStatus.now => '$label, current',
        null => null,
      },
      child: PortalPressable(
        onTap: onTap,
        onLongPress: onLongPress,
        enabled: enabled,
        haptic: PortalHapticKind.selection,
        borderRadius: radius,
        child: _hitArea(
          tokens.minTapTarget,
          painted,
          AnimatedContainer(
            duration: duration,
            curve: tokens.motion.standard,
            constraints: BoxConstraints(minHeight: painted),
            padding: EdgeInsetsDirectional.only(
              start: tokens.spacing.md,
              end: onDeleted == null && !menu
                  ? tokens.spacing.md
                  : tokens.spacing.sm,
            ),
            decoration: BoxDecoration(
              color: fill,
              borderRadius: radius,
              border: Border.all(
                color: selected
                    ? fill
                    : (borderColor ?? skin.borderColor ?? portal.outline),
                width: tokens.borderWidth,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (lead != null) ...[
                  lead,
                  SizedBox(width: tokens.spacing.xs),
                ] else if (icon != null) ...[
                  TweenAnimationBuilder<double>(
                    tween: Tween(end: selected ? 1 : 0),
                    duration: duration,
                    curve: tokens.motion.standard,
                    builder: (_, fillAxis, __) => Icon(
                      icon,
                      fill: fillAxis.clamp(0.0, 1.0),
                      size: tokens.typeScale.md,
                      color: ink,
                    ),
                  ),
                  SizedBox(width: tokens.spacing.xs),
                ],
                // With a status the label above already says the text.
                ExcludeSemantics(
                  excluding: status != null,
                  child: Text(
                    label,
                    style: tokens.textStyles.caption.copyWith(color: ink),
                  ),
                ),
                if (menu) ...[
                  SizedBox(width: tokens.spacing.xs),
                  Icon(PortalIcons.expand_more_rounded,
                      size: tokens.typeScale.md, color: ink),
                ],
                // The glyph's own box is as wide as the delete target less the
                // chip's end padding, so the target never reaches the label.
                if (onDeleted != null)
                  SizedBox(
                    width: tokens.minTapTarget - tokens.spacing.sm,
                    child: Icon(Icons.close,
                        size: tokens.typeScale.md, color: ink),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
    final shown =
        enabled ? chip : Opacity(opacity: tokens.motion.disabledOpacity, child: chip);
    if (onDeleted == null) return shown;

    // The close glyph is painted by the chip; the target is laid over its end
    // as a sibling, so the two buttons announce separately.
    final tap = tokens.minTapTarget;
    return Stack(
      children: [
        shown,
        PositionedDirectional(
          end: 0,
          top: 0,
          bottom: 0,
          width: tap,
          child: Semantics(
            container: true,
            child: Tooltip(
              message: deleteTooltip!,
              child: PortalPressable(
                onTap: onDeleted,
                enabled: enabled,
                haptic: PortalHapticKind.selection,
                borderRadius: radius,
                child: const SizedBox.expand(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// A paint under the minimum tap target gets a box around it, so the hit
  /// area is not painted height (`UI_PATTERNS.md`).
  static Widget _hitArea(double tap, double painted, Widget chip) =>
      painted >= tap
          ? chip
          : SizedBox(height: tap, child: Center(widthFactor: 1, child: chip));
}

/// Horizontally scrolling row of [PortalFilterChip]s, inset to the page
/// gutter so the first chip aligns with the content column.
///
/// [semanticLabel] names a group of [PortalFilterChip.exclusive] chips
/// ('Month'); [trailing] chips follow a hairline, outside the group (an
/// independent 'Over budget' toggle). The selected chip of an exclusive group
/// is brought to the middle of the strip when it becomes selected -- the
/// strip only, never the page.
class PortalFilterChipRow extends StatelessWidget {
  const PortalFilterChipRow({
    super.key,
    required this.children,
    this.padding,
    this.semanticLabel,
    this.trailing = const [],
  })  : _skeleton = null,
        _compact = false;

  /// The chips while they load: a pill at each of [widths], wrapping as a chip
  /// group does, as tall as the chips that replace it ([compact] if they are).
  /// Hidden from screen readers.
  const PortalFilterChipRow.skeleton({
    super.key,
    required List<double> widths,
    bool compact = false,
    this.padding,
  })  : _skeleton = widths,
        _compact = compact,
        children = const [],
        semanticLabel = null,
        trailing = const [];

  final List<Widget> children;
  final EdgeInsetsGeometry? padding;
  final String? semanticLabel;
  final List<Widget> trailing;
  final List<double>? _skeleton;
  final bool _compact;

  @override
  Widget build(BuildContext context) {
    final portal = PortalUiTheme.of(context);
    final tokens = portal.tokens;
    final gap = tokens.spacing.sm;
    final inset = padding ??
        EdgeInsets.fromLTRB(
          tokens.layout.pageHorizontal,
          0,
          tokens.layout.pageHorizontal,
          tokens.spacing.md,
        );

    if (_skeleton case final widths?) {
      final paint = _compact
          ? PortalFilterChip._compactHeight
          : (PortalFilterChipTheme.of(context).minHeight ??
              tokens.minTapTarget);
      final hit = paint < tokens.minTapTarget ? tokens.minTapTarget : paint;
      return ExcludeSemantics(
        child: PortalSkeletonTone(
          child: Padding(
            padding: inset,
            child: Wrap(
              spacing: gap,
              children: [
                for (final w in widths)
                  SizedBox(
                    width: w,
                    height: hit,
                    child: Center(
                      child: PortalSkeleton(
                        height: paint,
                        borderRadius: BorderRadius.circular(tokens.radii.full),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    Widget group = Row(
      mainAxisSize: MainAxisSize.min,
      spacing: gap,
      children: [
        for (final c in children)
          if (c is PortalFilterChip && c.exclusive && c.selected)
            _InView(key: ValueKey(('portal.chipRow.inView', c.label)), child: c)
          else
            c,
      ],
    );
    if (semanticLabel case final label?) {
      group = Semantics(
        container: true,
        explicitChildNodes: true,
        label: label,
        child: group,
      );
    }
    if (trailing.isNotEmpty) {
      group = Row(
        spacing: gap,
        children: [
          group,
          SizedBox(
            height: tokens.spacing.xl,
            child: VerticalDivider(
              width: tokens.borderWidth,
              thickness: tokens.borderWidth,
              color: portal.outline,
            ),
          ),
          ...trailing,
        ],
      );
    }
    return _EdgeFade(
      width: tokens.spacing.xl,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: inset,
        child: group,
      ),
    );
  }
}

/// Fades whichever end of a horizontal scroller still has content past it, so
/// a chip cut off by the viewport reads as "more this way" instead of as the
/// last one. Nothing is added while everything fits.
class _EdgeFade extends StatefulWidget {
  const _EdgeFade({required this.width, required this.child});

  final double width;
  final Widget child;

  @override
  State<_EdgeFade> createState() => _EdgeFadeState();
}

class _EdgeFadeState extends State<_EdgeFade> {
  // Keeps the scroller (and its offset) when the mask comes and goes.
  final _scroller = GlobalKey();
  bool _more = false; // content past the end edge
  bool _scrolled = false; // content before the start edge

  bool _update(ScrollMetrics m) {
    final more = m.pixels < m.maxScrollExtent - 1;
    final scrolled = m.pixels > m.minScrollExtent + 1;
    if (more != _more || scrolled != _scrolled) {
      setState(() {
        _more = more;
        _scrolled = scrolled;
      });
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final child = NotificationListener<ScrollMetricsNotification>(
      onNotification: (n) => _update(n.metrics),
      child: NotificationListener<ScrollNotification>(
        onNotification: (n) => _update(n.metrics),
        child: KeyedSubtree(key: _scroller, child: widget.child),
      ),
    );
    if (!_more && !_scrolled) return child;

    final dir = Directionality.of(context);
    return ShaderMask(
      blendMode: BlendMode.dstIn,
      shaderCallback: (rect) {
        final f = (widget.width / rect.width).clamp(0.0, 0.5);
        const clear = Color(0x00000000);
        const solid = Color(0xFF000000);
        return LinearGradient(
          begin: AlignmentDirectional.centerStart,
          end: AlignmentDirectional.centerEnd,
          colors: [
            _scrolled ? clear : solid,
            solid,
            solid,
            _more ? clear : solid
          ],
          stops: [0, f, 1 - f, 1],
        ).createShader(rect, textDirection: dir);
      },
      child: child,
    );
  }
}

/// Brings its child to the middle of its own horizontal strip once, when it
/// is built (a newly selected chip keys a new one).
class _InView extends StatefulWidget {
  const _InView({super.key, required this.child});

  final Widget child;

  @override
  State<_InView> createState() => _InViewState();
}

class _InViewState extends State<_InView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Scrollable.maybeOf(context)
          ?.position
          .ensureVisible(context.findRenderObject()!, alignment: .5);
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
