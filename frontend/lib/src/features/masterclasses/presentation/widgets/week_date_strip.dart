import 'package:flutter/material.dart';

import '../../../../core/strings.dart';

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// Понедельник ISO-недели, содержащей [date].
DateTime mondayOfWeekContaining(DateTime date) {
  final d = dateOnly(date);
  return d.subtract(Duration(days: d.weekday - DateTime.monday));
}

List<DateTime> daysOfWeekFromMonday(DateTime monday) {
  return List.generate(7, (i) => monday.add(Duration(days: i)));
}

/// Полоса: стрелка - 7 дней - стрелка.
class WeekDateStrip extends StatelessWidget {
  const WeekDateStrip({
    super.key,
    required this.visibleWeekMonday,
    required this.selectedDate,
    required this.onSelectDay,
    required this.onPrevWeek,
    required this.onNextWeek,
  });

  final DateTime visibleWeekMonday;

  /// null - ни один день не подсвечен (лента без фильтра по дате).
  final DateTime? selectedDate;
  final ValueChanged<DateTime> onSelectDay;
  final VoidCallback onPrevWeek;
  final VoidCallback onNextWeek;

  @override
  Widget build(BuildContext context) {
    final days = daysOfWeekFromMonday(visibleWeekMonday);
    final sel = selectedDate != null ? dateOnly(selectedDate!) : null;

    const arrowColWidth = 32.0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 4, 2, 10),
      child: Row(
        children: [
          SizedBox(
            width: arrowColWidth,
            child: IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(width: 32, height: 44),
              style: IconButton.styleFrom(
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              icon: const Icon(Icons.chevron_left, size: 26),
              onPressed: onPrevWeek,
              tooltip: AppStrings.prevWeekTooltip,
            ),
          ),
          Expanded(
            child: Row(
              children: List.generate(7, (i) {
                final day = days[i];
                final isSelected = sel != null && dateOnly(day) == sel;
                const gap = 2.0;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: i > 0 ? gap / 2 : 0,
                      right: i < 6 ? gap / 2 : 0,
                    ),
                    child: LayoutBuilder(
                      builder: (context, c) {
                        final w = c.maxWidth;
                        // Выше и крупнее "плашка"; больше места под число и месяц.
                        final h = w * 94 / 82 * 1.38;
                        return _DayCell(
                          width: w,
                          height: h,
                          day: day,
                          selected: isSelected,
                          onTap: () => onSelectDay(day),
                        );
                      },
                    ),
                  ),
                );
              }),
            ),
          ),
          SizedBox(
            width: arrowColWidth,
            child: IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(width: 32, height: 44),
              style: IconButton.styleFrom(
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              icon: const Icon(Icons.chevron_right, size: 26),
              onPressed: onNextWeek,
              tooltip: AppStrings.nextWeekTooltip,
            ),
          ),
        ],
      ),
    );
  }
}

const _kCalendarOrange = Color(0xFFFA7624);

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.width,
    required this.height,
    required this.day,
    required this.selected,
    required this.onTap,
  });

  final double width;
  final double height;
  final DateTime day;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final numberStyle = TextStyle(
      fontSize: width * 0.44,
      fontWeight: FontWeight.w700,
      color: selected ? Colors.white : Colors.black,
      height: 1.05,
    );
    final monthStyle = TextStyle(
      fontSize: width * 0.27,
      fontWeight: FontWeight.w600,
      color: selected ? Colors.white : Colors.black,
      height: 1.05,
    );
    final month = AppStrings.monthsShort[day.month - 1];

    const cardRadius = 8.0;

    // Цвет и скругление на самом Material - плашка ровно по размеру ячейки; тень через elevation (не обрезается clip как у BoxShadow внутри).
    return Material(
      color: selected ? _kCalendarOrange : Colors.white,
      elevation: 3,
      shadowColor: const Color(0x400A3667),
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(cardRadius),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(cardRadius),
        splashColor: selected
            ? Colors.white.withOpacity(0.25)
            : Colors.black.withOpacity(0.06),
        highlightColor: Colors.transparent,
        child: SizedBox(
          width: width,
          height: height,
          child: Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: width * 0.06),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${day.day}',
                    style: numberStyle,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: height * 0.04),
                  Text(
                    month,
                    style: monthStyle,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textHeightBehavior: const TextHeightBehavior(
                      applyHeightToFirstAscent: false,
                      applyHeightToLastDescent: false,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
