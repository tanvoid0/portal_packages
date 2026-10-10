import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../motion/portal_haptics.dart';
import '../theme/portal_component_extensions.dart';
import '../theme/portal_ui_theme.dart';
import 'portal_pressable.dart';

/// A sideways strip of days: a weekday caption over a tabular date, one
/// `minTapTarget` wide.
///
/// The selected day is filled, today wears a ring, and each is announced: a
/// day reads as its full date (plus "today"), and a strip with a [selected]
/// reports which day is selected, so the fill is never the only signal. A null
/// [selected] is a strip used as navigation: today's ring only, no day heard
/// as selected. A null [onSelected] is display-only: the days are plain
/// content, not buttons. Re-skin with [PortalCalendarTheme], as the month grid.
///
/// [mark] draws a per-day mark under the date (a [PortalDayDot], a small
/// meter); it inherits the day's `IconTheme` colour, flipped to the on-fill ink
/// on the selected day. The mark is its **own semantics node**, never folded
/// into the day's label, so a mark with a tap of its own stays reachable by a
/// screen reader. [markLabel] names a decorative mark ("workout logged"); a
/// mark that is interactive names itself and leaves [markLabel] null. A tap on
/// the mark's empty space still selects the day.
class PortalDayStrip extends StatelessWidget {
  const PortalDayStrip({
    super.key,
    required this.days,
    this.selected,
    this.onSelected,
    this.today,
    this.mark,
    this.markLabel,
    this.controller,
  });

  /// Date-only, local time; only year, month and day are compared.
  final List<DateTime> days;
  final DateTime? selected;
  final ValueChanged<DateTime>? onSelected;

  /// The day that gets the ring and the spoken "today".
  final DateTime? today;
  final Widget Function(DateTime day)? mark;
  final String? Function(DateTime day)? markLabel;

  /// Scrolls the strip, so a caller can bring today into view.
  final ScrollController? controller;

  static bool _same(DateTime a, DateTime? b) =>
      b != null && a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final t = PortalUiTheme.of(context).tokens;
    return SingleChildScrollView(
      controller: controller,
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: t.spacing.lg),
      child: Row(
        spacing: t.spacing.xs,
        children: [for (final d in days) _cell(context, d)],
      ),
    );
  }

  Widget _cell(BuildContext context, DateTime d) {
    final portal = PortalUiTheme.of(context);
    final t = portal.tokens;
    final skin = PortalCalendarTheme.of(context);
    final accent = skin.selectedColor ?? portal.primary;
    final onAccent = skin.onSelectedColor ?? portal.onPrimary;
    final marker = skin.markerColor ?? accent;
    final loc = MaterialLocalizations.of(context);
    final weekday = DateFormat.E(Localizations.localeOf(context).toString());
    final pill = BorderRadius.circular(t.radii.full);
    final on = _same(d, selected);
    final isToday = _same(d, today);
    final picks = selected != null;
    final tap = onSelected;
    final slot = mark;

    return Semantics(
      container: true,
      selected: picks ? on : null,
      inMutuallyExclusiveGroup: picks ? true : null,
      label: [loc.formatFullDate(d), if (isToday) loc.currentDateLabel]
          .join(', '),
      child: PortalPressable(
        onTap: tap == null ? null : () => tap(d),
        haptic: PortalHapticKind.selection,
        borderRadius: pill,
        child: Container(
          width: t.minTapTarget,
          constraints: BoxConstraints(minHeight: t.minTapTarget),
          padding: EdgeInsets.symmetric(vertical: t.spacing.sm),
          decoration: BoxDecoration(
            color: on ? accent : null,
            borderRadius: pill,
            border: isToday && !on
                ? Border.all(
                    color: accent,
                    width: t.borderWidth * 1.5,
                    strokeAlign: BorderSide.strokeAlignInside,
                  )
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Caption and date are the day's label; the mark below is not.
              ExcludeSemantics(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      weekday.format(d),
                      style: t.textStyles.caption.copyWith(
                        color: on ? onAccent : portal.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      '${d.day}',
                      style: t.textStyles.numeric(t.textStyles.body).copyWith(
                            color: on ? onAccent : portal.onSurface,
                            fontWeight: on ? FontWeight.w700 : null,
                          ),
                    ),
                  ],
                ),
              ),
              if (slot != null)
                SizedBox(
                  height: t.spacing.md,
                  child: IconTheme.merge(
                    data: IconThemeData(color: on ? onAccent : marker),
                    child: Center(
                      // container: a boundary, so a mark's own button / tap
                      // never merges into the day's node above.
                      child: Semantics(
                        container: true,
                        label: markLabel?.call(d),
                        child: slot(d),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A day's mark on [PortalDayStrip] ("workout logged"): a `spacing.sm` dot in
/// the day's `IconTheme` colour (the marker colour, or the on-fill ink on the
/// selected day). Decorative: name it with `markLabel`.
class PortalDayDot extends StatelessWidget {
  const PortalDayDot({super.key});

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          color: IconTheme.of(context).color,
          shape: BoxShape.circle,
        ),
        child: SizedBox.square(
          dimension: PortalUiTheme.of(context).tokens.spacing.sm,
        ),
      );
}
