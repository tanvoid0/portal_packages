import 'package:flutter/material.dart';

import '../theme/portal_component_extensions.dart';
import '../theme/portal_icons.dart';
import '../theme/portal_ui_theme.dart';
import 'portal_text.dart';

/// Month grid with an optional selected day and day markers.
///
/// The visible month is the widget's own state, seeded from [initialMonth],
/// else [selected], else today; [onMonthChanged] reports a flip. Each day is
/// a semantic button named by the localized full date, with [markedLabel]
/// appended when marked, and the selected day is reported as selected, so
/// neither the fill nor the dot is the only signal. The painted disc is 72%
/// of `minTapTarget`; the hit area is the whole `minTapTarget`. Re-skin with
/// [PortalCalendarTheme].
class PortalCalendar extends StatefulWidget {
  const PortalCalendar({
    super.key,
    this.selected,
    this.onSelected,
    this.initialMonth,
    this.markedDays = const {},
    this.firstWeekday = DateTime.monday,
    this.markedLabel = 'has activity',
    this.onMonthChanged,
  });

  final DateTime? selected;
  final ValueChanged<DateTime>? onSelected;
  final DateTime? initialMonth;

  /// Days that show a marker dot (date-only, local time).
  final Set<DateTime> markedDays;

  /// A [DateTime] weekday constant: the column the week starts on.
  final int firstWeekday;

  /// Spoken after the date of a marked day.
  final String markedLabel;

  /// The first of the month now showing.
  final ValueChanged<DateTime>? onMonthChanged;

  @override
  State<PortalCalendar> createState() => _PortalCalendarState();
}

class _PortalCalendarState extends State<PortalCalendar> {
  late DateTime _month;

  @override
  void initState() {
    super.initState();
    final base = widget.initialMonth ?? widget.selected ?? DateTime.now();
    _month = DateTime(base.year, base.month);
  }

  void _flip(int by) {
    setState(() => _month = DateTime(_month.year, _month.month + by));
    widget.onMonthChanged?.call(_month);
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final portal = PortalUiTheme.of(context);
    final t = portal.tokens;
    final skin = PortalCalendarTheme.of(context);
    final accent = skin.selectedColor ?? portal.primary;
    final onAccent = skin.onSelectedColor ?? portal.onPrimary;
    final marker = skin.markerColor ?? accent;
    final loc = MaterialLocalizations.of(context);
    final first = widget.firstWeekday;

    final days = DateTime(_month.year, _month.month + 1, 0).day;
    final leading =
        (DateTime(_month.year, _month.month).weekday - first + 7) % 7;
    final rows = (leading + days + 6) ~/ 7;
    final disc = t.minTapTarget * 0.72;
    final now = DateTime.now();

    return Material(
      color: portal.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(t.radii.md),
        side: BorderSide(
          color: portal.outline.withValues(alpha: 0.65),
          width: t.borderWidth,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: EdgeInsets.all(t.spacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => _flip(-1),
                  tooltip: loc.previousMonthTooltip,
                  icon: const Icon(PortalIcons.chevron_left_rounded),
                ),
                Expanded(
                  child: Semantics(
                    header: true,
                    liveRegion: true,
                    child: Text(
                      loc.formatMonthYear(_month),
                      textAlign: TextAlign.center,
                      style: t.textStyles.subtitle
                          .copyWith(color: portal.onSurface),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => _flip(1),
                  tooltip: loc.nextMonthTooltip,
                  icon: const Icon(PortalIcons.chevron_right_rounded),
                ),
              ],
            ),
            SizedBox(height: t.spacing.sm),
            ExcludeSemantics(
              child: Row(
                children: [
                  for (var i = 0; i < 7; i++)
                    Expanded(
                      child: Center(
                        child: PortalText(
                          // narrowWeekdays is Sunday-first; DateTime.sunday is 7.
                          loc.narrowWeekdays[(first - 1 + i + 1) % 7],
                          style: t.textStyles.caption
                              .copyWith(color: portal.onSurfaceVariant),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(height: t.spacing.xs),
            for (var r = 0; r < rows; r++)
              Row(
                children: [
                  for (var c = 0; c < 7; c++)
                    Expanded(
                      child: _cell(
                        context,
                        r * 7 + c - leading + 1,
                        days,
                        now,
                        disc,
                        accent,
                        onAccent,
                        marker,
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _cell(
    BuildContext context,
    int n,
    int days,
    DateTime now,
    double disc,
    Color accent,
    Color onAccent,
    Color marker,
  ) {
    final portal = PortalUiTheme.of(context);
    final t = portal.tokens;
    if (n < 1 || n > days) return SizedBox(height: t.minTapTarget);

    final day = DateTime(_month.year, _month.month, n);
    final sel = widget.selected != null && _sameDay(day, widget.selected!);
    final today = _sameDay(day, now);
    final marked = widget.markedDays.any((m) => _sameDay(m, day));
    final loc = MaterialLocalizations.of(context);

    return Semantics(
      button: widget.onSelected != null,
      selected: sel,
      label: marked
          ? '${loc.formatFullDate(day)}, ${widget.markedLabel}'
          : loc.formatFullDate(day),
      onTap: widget.onSelected == null ? null : () => widget.onSelected!(day),
      excludeSemantics: true,
      child: InkWell(
        onTap: widget.onSelected == null ? null : () => widget.onSelected!(day),
        customBorder: const CircleBorder(),
        child: SizedBox(
          height: t.minTapTarget,
          child: Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: disc,
                  height: disc,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: sel
                        ? accent
                        : today
                            ? accent.withValues(alpha: 0.12)
                            : null,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$n',
                    style: t.textStyles.numeric(t.textStyles.body).copyWith(
                          color: sel
                              ? onAccent
                              : today
                                  ? accent
                                  : portal.onSurface,
                          fontWeight: today || sel ? FontWeight.w600 : null,
                        ),
                  ),
                ),
                if (marked && !sel)
                  Positioned(
                    bottom: t.spacing.xs,
                    child: Container(
                      width: t.spacing.xs + 1,
                      height: t.spacing.xs + 1,
                      decoration:
                          BoxDecoration(color: marker, shape: BoxShape.circle),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
