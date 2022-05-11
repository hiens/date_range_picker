import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart' as intl;

part 'date_picker_dialog.dart';
part 'day_picker.dart';
part 'year_picker.dart';

enum DatePickerMode {
  /// Show a date picker UI for choosing a month and day.
  day,

  /// Show a date picker UI for choosing a year.
  year,
}

enum DatePickerSelectionMode {
  /// Select full year
  fullYear,

  /// Select from start of the year to date
  yearToDate,

  /// Select from start of the year to date
  yearToMonth,

  /// Select full month
  fullMonth,

  /// Select from month to date
  monthToDate,

  /// Custom
  custom
}

const Duration _kMonthScrollDuration = Duration(milliseconds: 200);
const double _kDayPickerRowHeight = 40.0;
const double _kYearRowHeight = 32.0;
const int _kMaxDayPickerRowCount = 6; // A 31 day month that starts on Saturday.
// Two extra rows: one for the day-of-week header and one for the month header.
const double _kMaxDayPickerHeight =
    _kDayPickerRowHeight * (_kMaxDayPickerRowCount + 1);

/// Signature for predicating dates for enabled date selections.
///
/// See [showDatePicker].
typedef SelectableDayPredicate = bool Function(DateTime day);

/// Shows a dialog containing a material design date picker.
///
/// The returned [Future] resolves to the date selected by the user when the
/// user closes the dialog. If the user cancels the dialog, null is returned.
///
/// An optional [selectableDayPredicate] function can be passed in to customize
/// the days to enable for selection. If provided, only the days that
/// [selectableDayPredicate] returned true for will be selectable.
///
/// An optional [initialDatePickerMode] argument can be used to display the
/// date picker initially in the year or month+day picker mode. It defaults
/// to month+day, and must not be null.
///
/// An optional [locale] argument can be used to set the locale for the date
/// picker. It defaults to the ambient locale provided by [Localizations].
///
/// An optional [textDirection] argument can be used to set the text direction
/// (RTL or LTR) for the date picker. It defaults to the ambient text direction
/// provided by [Directionality]. If both [locale] and [textDirection] are not
/// null, [textDirection] overrides the direction chosen for the [locale].
///
/// The `context` argument is passed to [showDialog], the documentation for
/// which discusses how it is used.
///
/// See also:
///
///  * [showTimePicker]
///  * <https://material.google.com/components/pickers.html#pickers-date-pickers>
Future<List<DateTime>?> showDateRangePicker({
  required BuildContext context,
  required DateTime initialFirstDate,
  required DateTime initialLastDate,
  required DateTime firstDate,
  required DateTime lastDate,
  SelectableDayPredicate? selectableDayPredicate,
  DatePickerMode initialDatePickerMode = DatePickerMode.day,
  DatePickerSelectionMode selectionMode = DatePickerSelectionMode.custom,
  Locale? locale,
  TextDirection? textDirection,
  int? maxRange,
}) async {
  assert(!initialFirstDate.isBefore(firstDate),
      'initialDate must be on or after firstDate');
  // assert(!initialLastDate.isAfter(lastDate),
  //     'initialDate must be on or before lastDate');
  assert(!initialFirstDate.isAfter(initialLastDate),
      'initialFirstDate must be on or before initialLastDate');
  assert(
      !firstDate.isAfter(lastDate), 'lastDate must be on or after firstDate');
  assert(
      selectableDayPredicate == null ||
          selectableDayPredicate(initialFirstDate) ||
          selectableDayPredicate(initialLastDate),
      'Provided initialDate must satisfy provided selectableDayPredicate');

  // Initialize date formatting
  initializeDateFormatting();

  // Create child widget
  Widget child = DatePickerDialog(
    initialFirstDate: initialFirstDate,
    initialLastDate: initialLastDate,
    firstDate: firstDate,
    lastDate: lastDate,
    selectableDayPredicate: selectableDayPredicate,
    initialDatePickerMode: initialDatePickerMode,
    selectionMode: selectionMode,
    maxRange: maxRange,
    locale: locale ?? Localizations.localeOf(context),
  );

  if (textDirection != null) {
    child = Directionality(textDirection: textDirection, child: child);
  }

  if (locale != null) {
    child =
        Localizations.override(context: context, locale: locale, child: child);
  }

  return await showDialog<List<DateTime>>(
      context: context, builder: (BuildContext context) => child);
}
