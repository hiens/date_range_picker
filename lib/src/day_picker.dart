part of 'date_range_picker.dart';

class _DayPickerGridDelegate extends SliverGridDelegate {
  const _DayPickerGridDelegate();

  @override
  SliverGridLayout getLayout(SliverConstraints constraints) {
    const columnCount = DateTime.daysPerWeek;
    final tileWidth = constraints.crossAxisExtent / columnCount;
    final tileHeight = math.min(_kDayPickerRowHeight,
        constraints.viewportMainAxisExtent / (_kMaxDayPickerRowCount + 1));
    return SliverGridRegularTileLayout(
      crossAxisCount: columnCount,
      mainAxisStride: tileHeight,
      crossAxisStride: tileWidth,
      childMainAxisExtent: tileHeight - 10,
      childCrossAxisExtent: tileWidth,
      reverseCrossAxis: axisDirectionIsReversed(constraints.crossAxisDirection),
    );
  }

  @override
  bool shouldRelayout(_DayPickerGridDelegate oldDelegate) => false;
}

const _DayPickerGridDelegate _kDayPickerGridDelegate = _DayPickerGridDelegate();

/// Displays the days of a given month and allows choosing a day.
///
/// The days are arranged in a rectangular grid with one column for each day of
/// the week.
///
/// The day picker widget is rarely used directly. Instead, consider using
/// [showDatePicker], which creates a date picker dialog.
///
/// See also:
///
///  * [showDatePicker].
///  * <https://material.google.com/components/pickers.html#pickers-date-pickers>
class DayPicker extends StatelessWidget {
  /// Creates a day picker
  DayPicker({
    Key? key,
    required this.selectedFirstDate,
    this.selectedLastDate,
    required this.currentDate,
    required this.onChanged,
    required this.firstDate,
    required this.lastDate,
    required this.displayedMonth,
    required this.selectionMode,
    this.selectableDayPredicate,
  })  : assert(!firstDate.isAfter(lastDate)),
        // assert(!selectedFirstDate.isBefore(firstDate) &&
        //     (selectedLastDate == null || !selectedLastDate.isAfter(lastDate))),
        assert(selectedLastDate == null ||
            !selectedLastDate.isBefore(selectedFirstDate)),
        super(key: key);

  /// The currently selected date.
  ///
  /// This date is highlighted in the picker.
  final DateTime selectedFirstDate;
  final DateTime? selectedLastDate;

  /// The current date at the time the picker is displayed.
  final DateTime currentDate;

  /// Called when the user picks a day.
  final ValueChanged<List<DateTime?>> onChanged;

  /// The earliest date the user is permitted to pick.
  final DateTime firstDate;

  /// The latest date the user is permitted to pick.
  final DateTime lastDate;

  /// The month whose days are displayed by this picker.
  final DateTime displayedMonth;

  /// Optional user supplied predicate function to customize selectable days.
  final SelectableDayPredicate? selectableDayPredicate;

  /// Optional user to auto select full month / month to date / custom
  final DatePickerSelectionMode selectionMode;

  /// Builds widgets showing abbreviated days of week. The first widget in the
  /// returned list corresponds to the first day of week for the current locale.
  ///
  /// Examples:
  ///
  /// ```
  /// ┌ Sunday is the first day of week in the US (en_US)
  /// |
  /// S M T W T F S  <-- the returned list contains these widgets
  /// _ _ _ _ _ 1 2
  /// 3 4 5 6 7 8 9
  ///
  /// ┌ But it's Monday in the UK (en_GB)
  /// |
  /// M T W T F S S  <-- the returned list contains these widgets
  /// _ _ _ _ 1 2 3
  /// 4 5 6 7 8 9 10
  /// ```
  List<Widget> _getDayHeaders(
      TextStyle? headerStyle, MaterialLocalizations localizations) {
    final result = <Widget>[];
    for (var i = localizations.firstDayOfWeekIndex; true; i = (i + 1) % 7) {
      final weekday = localizations.narrowWeekdays[i];
      result.add(ExcludeSemantics(
        child: Center(child: Text(weekday, style: headerStyle)),
      ));
      if (i == (localizations.firstDayOfWeekIndex - 1) % 7) break;
    }
    return result;
  }

  // Do not use this directly - call getDaysInMonth instead.
  static const List<int> _daysInMonth = <int>[
    31,
    -1,
    31,
    30,
    31,
    30,
    31,
    31,
    30,
    31,
    30,
    31
  ];

  /// Returns the number of days in a month, according to the proleptic
  /// Gregorian calendar.
  ///
  /// This applies the leap year logic introduced by the Gregorian reforms of
  /// 1582. It will not give valid results for dates prior to that time.
  static int getDaysInMonth(int year, int month) {
    if (month == DateTime.february) {
      final isLeapYear =
          (year % 4 == 0) && (year % 100 != 0) || (year % 400 == 0);
      if (isLeapYear) return 29;
      return 28;
    }
    return _daysInMonth[month - 1];
  }

  /// Computes the offset from the first day of week that the first day of the
  /// [month] falls on.
  ///
  /// For example, September 1, 2017 falls on a Friday, which in the calendar
  /// localized for United States English appears as:
  ///
  /// ```
  /// S M T W T F S
  /// _ _ _ _ _ 1 2
  /// ```
  ///
  /// The offset for the first day of the months is the number of leading blanks
  /// in the calendar, i.e. 5.
  ///
  /// The same date localized for the Russian calendar has a different offset,
  /// because the first day of week is Monday rather than Sunday:
  ///
  /// ```
  /// M T W T F S S
  /// _ _ _ _ 1 2 3
  /// ```
  ///
  /// So the offset is 4, rather than 5.
  ///
  /// This code consolidates the following:
  ///
  /// - [DateTime.weekday] provides a 1-based index into days of week, with 1
  ///   falling on Monday.
  /// - [MaterialLocalizations.firstDayOfWeekIndex] provides a 0-based index
  ///   into the [MaterialLocalizations.narrowWeekdays] list.
  /// - [MaterialLocalizations.narrowWeekdays] list provides localized names of
  ///   days of week, always starting with Sunday and ending with Saturday.
  int _computeFirstDayOffset(
      int year, int month, MaterialLocalizations localizations) {
    // 0-based day of week, with 0 representing Monday.
    final weekdayFromMonday = DateTime(year, month).weekday - 1;
    // 0-based day of week, with 0 representing Sunday.
    final firstDayOfWeekFromSunday = localizations.firstDayOfWeekIndex;
    // firstDayOfWeekFromSunday recomputed to be Monday-based
    final firstDayOfWeekFromMonday = (firstDayOfWeekFromSunday - 1) % 7;
    // Number of days between the first day of week appearing on the calendar,
    // and the day corresponding to the 1-st of the month.
    return (weekdayFromMonday - firstDayOfWeekFromMonday) % 7;
  }

  ///
  void _selectDay(DateTime dayToBuild, {required int daysInMonth}) {
    DateTime? first, last;

    switch (selectionMode) {
      case DatePickerSelectionMode.fullYear:
        first = DateTime(dayToBuild.year, 1, 1);
        last = DateTime(dayToBuild.year, 12, 31);
        break;
      case DatePickerSelectionMode.yearToDate:
        first = DateTime(dayToBuild.year, 1, 1);
        last = (dayToBuild.day == 1 && dayToBuild.month == 1)
            ? null
            : DateTime(dayToBuild.year, dayToBuild.month, dayToBuild.day);
        break;
      case DatePickerSelectionMode.yearToMonth:
        first = DateTime(dayToBuild.year, 1, 1);
        last = (dayToBuild.day == 1 && dayToBuild.month == 1)
            ? null
            : DateTime(dayToBuild.year, dayToBuild.month, daysInMonth);
        break;
      case DatePickerSelectionMode.fullMonth:
        first = DateTime(dayToBuild.year, dayToBuild.month, 1);
        last = DateTime(dayToBuild.year, dayToBuild.month, daysInMonth);
        break;
      case DatePickerSelectionMode.monthToDate:
        first = DateTime(dayToBuild.year, dayToBuild.month, 1);
        last = dayToBuild.day != 1
            ? DateTime(dayToBuild.year, dayToBuild.month, dayToBuild.day)
            : null;
        break;
      case DatePickerSelectionMode.custom:
        if (selectedLastDate != null) {
          first = dayToBuild;
          last = null;
        } else {
          if (dayToBuild.compareTo(selectedFirstDate) <= 0) {
            first = dayToBuild;
            last = selectedFirstDate;
          } else {
            first = selectedFirstDate;
            last = dayToBuild;
          }
        }
        break;
    }

    onChanged([first, last]);
  }

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    final localizations = MaterialLocalizations.of(context);
    final year = displayedMonth.year;
    final month = displayedMonth.month;
    final daysInMonth = getDaysInMonth(year, month);
    final firstDayOffset = _computeFirstDayOffset(year, month, localizations);
    final labels = <Widget>[];
    labels.addAll(_getDayHeaders(themeData.textTheme.caption, localizations));
    for (var i = 0; true; i += 1) {
      // 1-based day of month, e.g. 1-31 for January, and 1-29 for February on
      // a leap year.
      final day = i - firstDayOffset + 1;
      if (day > daysInMonth) break;
      if (day < 1) {
        labels.add(Container());
      } else {
        final dayToBuild = DateTime(year, month, day);
        final disabled = dayToBuild.isAfter(lastDate) ||
            dayToBuild.isBefore(firstDate) ||
            (selectableDayPredicate != null &&
                !selectableDayPredicate!(dayToBuild));
        BoxDecoration? decoration;
        BoxDecoration? leftDecoration;
        BoxDecoration? rightDecoration;
        BoxDecoration? childDecoration;
        var itemStyle =
            const TextStyle(fontSize: 16.0, fontWeight: FontWeight.w600);
        final isSelectedFirstDay = selectedFirstDate.year == year &&
            selectedFirstDate.month == month &&
            selectedFirstDate.day == day;
        final isSelectedLastDay = selectedLastDate != null
            ? (selectedLastDate!.year == year &&
                selectedLastDate!.month == month &&
                selectedLastDate!.day == day)
            : null;
        final isInRange = selectedLastDate != null
            ? (dayToBuild.isBefore(selectedLastDate!) &&
                dayToBuild.isAfter(selectedFirstDate))
            : null;
        if (isSelectedFirstDay &&
            (isSelectedLastDay == null || isSelectedLastDay)) {
          itemStyle = itemStyle.copyWith(color: Colors.white);

          decoration =
              const BoxDecoration(color: Colors.blue, shape: BoxShape.circle);
        } else if (isSelectedFirstDay) {
          // The selected day gets a circle background highlight, and a contrasting text color.
          itemStyle = itemStyle.copyWith(color: Colors.white);
          childDecoration =
              const BoxDecoration(shape: BoxShape.circle, color: Colors.blue);
          if (dayToBuild.weekday == 7) {
            rightDecoration = BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius:
                    const BorderRadius.horizontal(right: Radius.circular(99)));
          } else {
            rightDecoration =
                BoxDecoration(color: Colors.blue.withOpacity(0.1));
          }
        } else if (isSelectedLastDay != null && isSelectedLastDay) {
          itemStyle = itemStyle.copyWith(color: Colors.white);
          childDecoration =
              const BoxDecoration(shape: BoxShape.circle, color: Colors.blue);
          if (dayToBuild.weekday == 1) {
            leftDecoration = BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius:
                    const BorderRadius.horizontal(left: Radius.circular(99)));
          } else {
            leftDecoration = BoxDecoration(color: Colors.blue.withOpacity(0.1));
          }
        } else if (isInRange != null && isInRange) {
          if (dayToBuild.weekday == 7) {
            decoration = BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                shape: BoxShape.rectangle,
                borderRadius:
                    const BorderRadius.horizontal(right: Radius.circular(99)));
          } else if (dayToBuild.weekday == 1) {
            decoration = BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                shape: BoxShape.rectangle,
                borderRadius:
                    const BorderRadius.horizontal(left: Radius.circular(99)));
          } else {
            decoration = BoxDecoration(
                color: Colors.blue.withOpacity(0.1), shape: BoxShape.rectangle);
          }
        } else if (disabled) {
          itemStyle = itemStyle.copyWith(color: Colors.grey);
        } else if (currentDate.year == year &&
            currentDate.month == month &&
            currentDate.day == day) {
          // The current day gets a different text color.
          childDecoration = BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(width: 1, color: Colors.blue));
        }

        Widget dayWidget = Container(
          decoration: decoration,
          child: Stack(
            children: [
              Row(
                children: [
                  Expanded(child: Container(decoration: leftDecoration)),
                  Expanded(child: Container(decoration: rightDecoration)),
                ],
              ),
              Container(
                decoration: childDecoration,
                child: Center(
                  child: Semantics(
                    label:
                        '${localizations.formatDecimal(day)}, ${localizations.formatFullDate(dayToBuild)}',
                    selected: isSelectedFirstDay ||
                        isSelectedLastDay != null && isSelectedLastDay,
                    child: ExcludeSemantics(
                      child: Text(localizations.formatDecimal(day),
                          style: itemStyle),
                    ),
                  ),
                ),
              )
            ],
          ),
        );

        if (!disabled) {
          dayWidget = GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _selectDay(dayToBuild, daysInMonth: daysInMonth),
            child: dayWidget,
          );
        }

        labels.add(dayWidget);
      }
    }

    return Column(
      children: <Widget>[
        Flexible(
          child: GridView.custom(
            gridDelegate: _kDayPickerGridDelegate,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childrenDelegate:
                SliverChildListDelegate(labels, addRepaintBoundaries: false),
          ),
        ),
      ],
    );
  }
}
