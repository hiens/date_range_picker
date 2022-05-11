part of 'date_range_picker.dart';

/// A scrollable list of years to allow picking a year.
///
/// The year picker widget is rarely used directly. Instead, consider using
/// [showDatePicker], which creates a date picker dialog.
///
/// Requires one of its ancestors to be a [Material] widget.
///
/// See also:
///
///  * [showDatePicker]
///  * <https://material.google.com/components/pickers.html#pickers-date-pickers>
class YearPicker extends StatefulWidget {
  /// Creates a year picker.
  ///
  /// The [selectedDate] and [onChanged] arguments must not be null. The
  /// [lastDate] must be after the [firstDate].
  ///
  /// Rarely used directly. Instead, typically used as part of the dialog shown
  /// by [showDatePicker].
  YearPicker({
    Key? key,
    required this.selectedFirstDate,
    this.selectedLastDate,
    required this.onChanged,
    required this.firstDate,
    required this.lastDate,
  })  : assert(!firstDate.isAfter(lastDate)),
        super(key: key);

  /// The currently selected date.
  ///
  /// This date is highlighted in the picker.
  final DateTime selectedFirstDate;
  final DateTime? selectedLastDate;

  /// Called when the user picks a year.
  final ValueChanged<List<DateTime?>> onChanged;

  /// The earliest date the user is permitted to pick.
  final DateTime firstDate;

  /// The latest date the user is permitted to pick.
  final DateTime lastDate;

  @override
  _YearPickerState createState() => _YearPickerState();
}

class _YearPickerState extends State<YearPicker> {
  ScrollController? scrollController;

  @override
  void initState() {
    super.initState();
    final offset = widget.selectedFirstDate.year - widget.firstDate.year + 10;
    scrollController = ScrollController(
      // Move the initial scroll position to the currently selected date's year.
      initialScrollOffset: (offset / 3) * _kYearRowHeight,
    );
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMaterial(context));
    const style = TextStyle(fontSize: 16.0, fontWeight: FontWeight.w600);

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3, childAspectRatio: 4 / 3),
      controller: scrollController,
      itemCount: 21,
      itemBuilder: (BuildContext context, int index) {
        final year = widget.firstDate.year + index - 5;
        final isEnabled =
            widget.firstDate.year <= year && widget.lastDate.year >= year;
        final isSelected = year == widget.selectedFirstDate.year ||
            (widget.selectedLastDate != null &&
                year == widget.selectedLastDate!.year);
        final itemStyle = isSelected
            ? style.copyWith(color: Colors.blue)
            : isEnabled
                ? style
                : style.copyWith(color: Colors.blue);
        return InkWell(
          key: ValueKey<int>(year),
          onTap: isEnabled
              ? () {
                  List<DateTime?> changes;
                  if (widget.selectedLastDate == null) {
                    final newDate = DateTime(
                        year,
                        widget.selectedFirstDate.month,
                        widget.selectedFirstDate.day);
                    changes = [newDate, newDate];
                  } else {
                    changes = [
                      DateTime(year, widget.selectedFirstDate.month,
                          widget.selectedFirstDate.day),
                      null
                    ];
                  }
                  widget.onChanged(changes);
                }
              : null,
          child: Center(
            child: Semantics(
                selected: isSelected,
                child: Text(year.toString(), style: itemStyle)),
          ),
        );
      },
    );
  }
}
