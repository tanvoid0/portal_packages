import 'package:flutter/material.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

/// Month grid with optional selection (shadcn Calendar — single month, no deps).
class PortalCalendar extends StatefulWidget {
  const PortalCalendar({
    super.key,
    this.selected,
    this.onSelected,
    this.initialMonth,
  });

  final DateTime? selected;
  final ValueChanged<DateTime>? onSelected;
  final DateTime? initialMonth;

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

  void _prev() {
    setState(() {
      _month = DateTime(_month.year, _month.month - 1);
    });
  }

  void _next() {
    setState(() {
      _month = DateTime(_month.year, _month.month + 1);
    });
  }

  static int _daysInMonth(DateTime m) => DateTime(m.year, m.month + 1, 0).day;

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final portal = PortalUiTheme.of(context);
    final t = portal.tokens;
    final loc = MaterialLocalizations.of(context);
    // Align with ISO week; use [DateTime.monday] if you need locale-specific start.
    const firstWeekday = DateTime.monday;

    final firstOfMonth = DateTime(_month.year, _month.month);
    final days = _daysInMonth(firstOfMonth);
    final leading = (firstOfMonth.weekday - firstWeekday + 7) % 7;
    final cells = leading + days;
    final rows = (cells + 6) ~/ 7;

    return PortalThemedSurface(
      borderRadius: BorderRadius.circular(t.radii.md),
      borderSide: portal.borderSide(),
      padding: EdgeInsets.all(t.spacing.md),
      child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: _prev,
                  icon: const Icon(Icons.chevron_left),
                ),
                Expanded(
                  child: Text(
                    loc.formatMonthYear(_month),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: _next,
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
            SizedBox(height: t.spacing.sm),
            Row(
              children: List.generate(7, (i) {
                final w = ((firstWeekday - 1 + i) % 7) + 1;
                final index = w % 7;
                return Expanded(
                  child: Center(
                    child: Text(
                      loc.narrowWeekdays[index],
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: portal.onSurfaceVariant,
                          ),
                    ),
                  ),
                );
              }),
            ),
            SizedBox(height: t.spacing.xs),
            for (var r = 0; r < rows; r++)
              Padding(
                padding: EdgeInsets.only(bottom: t.spacing.xs),
                child: Row(
                  children: List.generate(7, (c) {
                    final int idx = r * 7 + c - leading + 1;
                    if (idx < 1 || idx > days) {
                      return Expanded(
                        child: SizedBox(height: t.minTapTarget * 0.72),
                      );
                    }
                    final day = DateTime(_month.year, _month.month, idx);
                    final sel = widget.selected != null && _sameDay(day, widget.selected!);
                    final today = _sameDay(day, DateTime.now());
                    final cell = t.minTapTarget * 0.72;

                    return Expanded(
                      child: Center(
                        child: InkWell(
                          onTap: widget.onSelected == null ? null : () => widget.onSelected!(day),
                          customBorder: const CircleBorder(),
                          child: Container(
                            width: cell,
                            height: cell,
                            decoration: BoxDecoration(
                              color: sel
                                  ? portal.primary
                                  : today
                                      ? portal.primary.withValues(alpha: 0.12)
                                      : Colors.transparent,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '$idx',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: sel
                                        ? portal.onPrimary
                                        : today
                                            ? portal.primary
                                            : portal.onSurface,
                                    fontWeight: today || sel ? FontWeight.w600 : null,
                                  ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
          ],
        ),
    );
  }
}
