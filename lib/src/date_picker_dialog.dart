part of 'date_range_picker.dart';

class DatePickerDialog extends StatefulWidget {
  const DatePickerDialog({
    Key? key,
    required this.initialFirstDate,
    required this.initialLastDate,
    required this.firstDate,
    required this.lastDate,
    this.selectableDayPredicate,
    required this.initialDatePickerMode,
    required this.selectionMode,
    required this.locale,
    required this.maxRange,
  }) : super(key: key);

  final DateTime initialFirstDate;
  final DateTime initialLastDate;
  final DateTime firstDate;
  final DateTime lastDate;
  final SelectableDayPredicate? selectableDayPredicate;
  final DatePickerMode initialDatePickerMode;
  final DatePickerSelectionMode selectionMode;
  final Locale locale;
  final int? maxRange;

  @override
  _DatePickerDialogState createState() => _DatePickerDialogState();
}

class _DatePickerDialogState extends State<DatePickerDialog> {
  bool _announcedInitialDate = false;

  late MaterialLocalizations _localizations;
  late TextDirection _textDirection;

  late DateTime _selectedFirstDate;
  DateTime? _selectedLastDate;
  late DatePickerMode _mode;
  final GlobalKey _pickerKey = GlobalKey();

  late DateTime _todayDate;
  late DateTime _currentDisplayedMonthDate;
  Timer? _timer;
  PageController? _dayPickerController;

  @override
  void initState() {
    super.initState();
    //
    _selectedFirstDate = widget.initialFirstDate;
    _selectedLastDate = widget.initialLastDate;
    _mode = widget.initialDatePickerMode;

    // Initially display the pre-selected date.
    int monthPage;
    if (_selectedLastDate == null) {
      monthPage = _monthDelta(widget.firstDate, _selectedFirstDate);
    } else {
      monthPage = _monthDelta(widget.firstDate, _selectedLastDate!);
    }
    _dayPickerController = PageController(initialPage: monthPage);
    _handleMonthPageChanged(monthPage);
    _updateCurrentDate();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _localizations = MaterialLocalizations.of(context);
    _textDirection = Directionality.of(context);
    if (!_announcedInitialDate) {
      _announcedInitialDate = true;
      SemanticsService.announce(
        _localizations.formatFullDate(_selectedFirstDate),
        _textDirection,
      );
      if (_selectedLastDate != null) {
        SemanticsService.announce(
          _localizations.formatFullDate(_selectedLastDate!),
          _textDirection,
        );
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _dayPickerController?.dispose();
    super.dispose();
  }

  void _updateCurrentDate() {
    _todayDate = DateTime.now();
    final tomorrow =
        DateTime(_todayDate.year, _todayDate.month, _todayDate.day + 1);
    var timeUntilTomorrow = tomorrow.difference(_todayDate);
    timeUntilTomorrow +=
        const Duration(seconds: 1); // so we don't miss it by rounding
    _timer?.cancel();
    _timer = Timer(timeUntilTomorrow, () {
      setState(() => _updateCurrentDate());
    });
  }

  static int _monthDelta(DateTime startDate, DateTime endDate) {
    return (endDate.year - startDate.year) * 12 +
        endDate.month -
        startDate.month;
  }

  /// Add months to a month truncated date.
  DateTime _addMonthsToMonthDate(DateTime monthDate, int monthsToAdd) {
    return DateTime(
        monthDate.year + monthsToAdd ~/ 12, monthDate.month + monthsToAdd % 12);
  }

  Widget _buildItems(BuildContext context, int index) {
    final month = _addMonthsToMonthDate(widget.firstDate, index);
    return DayPicker(
      key: ValueKey<DateTime>(month),
      selectedFirstDate: _selectedFirstDate,
      selectedLastDate: _selectedLastDate,
      currentDate: _todayDate,
      onChanged: _handleDayChanged,
      firstDate: widget.firstDate,
      lastDate: widget.lastDate,
      displayedMonth: month,
      selectableDayPredicate: widget.selectableDayPredicate,
      selectionMode: widget.selectionMode,
    );
  }

  void _handleNextMonth() {
    if (!_isDisplayingLastMonth) {
      SemanticsService.announce(
          _localizations.formatMonthYear(_nextMonthDate), _textDirection);
      _dayPickerController!
          .nextPage(duration: _kMonthScrollDuration, curve: Curves.ease);
    }
  }

  void _handlePreviousMonth() {
    if (!_isDisplayingFirstMonth) {
      SemanticsService.announce(
          _localizations.formatMonthYear(_previousMonthDate), _textDirection);
      _dayPickerController!
          .previousPage(duration: _kMonthScrollDuration, curve: Curves.ease);
    }
  }

  /// True if the earliest allowable month is displayed.
  bool get _isDisplayingFirstMonth {
    return !_currentDisplayedMonthDate
        .isAfter(DateTime(widget.firstDate.year, widget.firstDate.month));
  }

  /// True if the latest allowable month is displayed.
  bool get _isDisplayingLastMonth {
    return !_currentDisplayedMonthDate
        .isBefore(DateTime(widget.lastDate.year, widget.lastDate.month));
  }

  late DateTime _previousMonthDate;
  late DateTime _nextMonthDate;

  void _handleMonthPageChanged(int monthPage) {
    setState(() {
      _previousMonthDate =
          _addMonthsToMonthDate(widget.firstDate, monthPage - 1);
      _currentDisplayedMonthDate =
          _addMonthsToMonthDate(widget.firstDate, monthPage);
      _nextMonthDate = _addMonthsToMonthDate(widget.firstDate, monthPage + 1);
    });
  }

  void _handleModeChanged() {
    setState(() {
      _mode = _mode == DatePickerMode.day
          ? DatePickerMode.year
          : DatePickerMode.day;
      if (_mode == DatePickerMode.day) {
        SemanticsService.announce(
            _localizations.formatMonthYear(_selectedFirstDate), _textDirection);
        if (_selectedLastDate != null) {
          SemanticsService.announce(
              _localizations.formatMonthYear(_selectedLastDate!),
              _textDirection);
        }
      } else {
        SemanticsService.announce(
            _localizations.formatYear(_selectedFirstDate), _textDirection);
        if (_selectedLastDate != null) {
          SemanticsService.announce(
              _localizations.formatYear(_selectedLastDate!), _textDirection);
        }
      }
    });
  }

  void _checkMonthPage() {
    int monthPage;
    if (_selectedLastDate == null) {
      monthPage = _monthDelta(widget.firstDate, _selectedFirstDate);
    } else {
      monthPage = _monthDelta(widget.firstDate, _selectedLastDate!);
    }
    _dayPickerController = PageController(initialPage: monthPage);
  }

  void _handleYearChanged(List<DateTime?> changes) {
    assert(changes.length == 2);

    if (widget.selectionMode == DatePickerSelectionMode.fullYear) {
      setState(() {
        _mode = DatePickerMode.day;
        _selectedFirstDate = DateTime(changes[0]!.year, 1, 1);
        _selectedLastDate = DateTime(_selectedFirstDate.year, 12, 31);
      });
    } else {
      setState(() {
        _mode = DatePickerMode.day;
        _selectedFirstDate = changes[0]!;
        _selectedLastDate = changes[1];
      });
    }
    _checkMonthPage();
    setState(() {
      _currentDisplayedMonthDate = changes[0]!;
    });
  }

  void _handleDayChanged(List<DateTime?> changes) {
    assert(changes.length == 2);
    setState(() {
      _selectedFirstDate = changes[0]!;
      _selectedLastDate = changes[1];
    });
    _checkMonthPage();
  }

  void _handleCancel() {
    Navigator.pop(context);
  }

  void _handleOk() {
    // Date range is exceeded maxRange
    if (widget.maxRange != null &&
        _selectedLastDate != null &&
        _selectedLastDate!.difference(_selectedFirstDate).inDays >
            widget.maxRange!) {
      // Show info dialog
      showDialog(
        context: context,
        builder: (_) {
          return Dialog(
            backgroundColor: Colors.white,
            insetPadding:
                const EdgeInsets.symmetric(horizontal: 18.0, vertical: 24.0),
            child: Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 18.0, vertical: 24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Bạn chỉ có thể chọn tối đa ${widget.maxRange} ngày'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text('Đóng'))
                ],
              ),
            ),
          );
        },
      );
    } else {
      final result = <DateTime>[];
      result.add(_selectedFirstDate);
      if (_selectedLastDate != null) {
        result.add(_selectedLastDate!);
      }
      Navigator.pop(context, result);
    }
  }

  Widget _buildPicker() {
    switch (_mode) {
      case DatePickerMode.day:
        return SizedBox(
          height: _kMaxDayPickerHeight,
          child: PageView.builder(
            key: ValueKey<DateTime?>(_selectedFirstDate),
            controller: _dayPickerController,
            scrollDirection: Axis.horizontal,
            itemCount: _monthDelta(widget.firstDate, widget.lastDate) + 1,
            itemBuilder: _buildItems,
            onPageChanged: _handleMonthPageChanged,
          ),
        );
      case DatePickerMode.year:
        return SizedBox(
          height: _kMaxDayPickerHeight,
          child: Container(
            margin: const EdgeInsets.only(top: 8.0, bottom: 16.0),
            child: YearPicker(
              key: _pickerKey,
              selectedFirstDate: _selectedFirstDate,
              selectedLastDate: _selectedLastDate,
              onChanged: _handleYearChanged,
              firstDate: widget.firstDate,
              lastDate: widget.lastDate,
            ),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding:
          const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8.0),
        child: SizedBox(
          width: MediaQuery.of(context).size.width - 10,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Container(
                color: Colors.blue,
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Select date',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontStyle: FontStyle.normal,
                          fontSize: 14.0,
                          height: 1.0,
                          letterSpacing: 0.0),
                    ),
                    const SizedBox(height: 22),
                    Text(
                      intl.DateFormat(
                        'EEEE, dd/MM/yyyy',
                        widget.locale.languageCode,
                      ).format(_selectedFirstDate),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28.0,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 0.0,
                          height: 1.285),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    SizedBox(
                      height: _kDayPickerRowHeight,
                      child: Row(
                        children: [
                          Directionality(
                              textDirection: TextDirection.rtl,
                              child: TextButton.icon(
                                onPressed: _handleModeChanged,
                                label: Text(intl.DateFormat(
                                  'MMMM/yyyy',
                                  widget.locale.languageCode,
                                ).format(_selectedFirstDate)),
                                icon: _mode == DatePickerMode.day
                                    ? const Icon(Icons.arrow_drop_down)
                                    : const Icon(Icons.arrow_drop_up),
                                style: ButtonStyle(
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  textStyle: MaterialStateProperty.all(
                                    const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontStyle: FontStyle.normal,
                                      fontSize: 14.0,
                                      height: 1.0,
                                      letterSpacing: 0.0,
                                    ),
                                  ),
                                  foregroundColor: MaterialStateProperty.all(
                                      const Color(0xff696e73)),
                                ),
                              )),
                          const Spacer(),
                          IconButton(
                            onPressed: _isDisplayingFirstMonth ||
                                    _mode == DatePickerMode.year
                                ? null
                                : _handlePreviousMonth,
                            icon: const Icon(Icons.chevron_left),
                          ),
                          IconButton(
                            onPressed: _isDisplayingLastMonth ||
                                    _mode == DatePickerMode.year
                                ? null
                                : _handleNextMonth,
                            icon: const Icon(Icons.chevron_right),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Flexible(child: SizedBox(child: _buildPicker())),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 40,
                            width: double.infinity,
                            child: OutlinedButton(
                              style: ButtonStyle(
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                textStyle: MaterialStateProperty.all(
                                    const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontStyle: FontStyle.normal,
                                        fontSize: 14.0,
                                        height: 1.0,
                                        letterSpacing: 0.0)),
                                overlayColor: MaterialStateProperty.all(
                                    Colors.red.withOpacity(0.1)),
                                side: MaterialStateProperty.all(
                                    const BorderSide(color: Colors.blue)),
                              ),
                              onPressed: _handleCancel,
                              child: Text('Huỷ'),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: SizedBox(
                            height: 40,
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ButtonStyle(
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                textStyle: MaterialStateProperty.all(
                                    const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontStyle: FontStyle.normal,
                                        fontSize: 14.0,
                                        height: 1.0,
                                        color: Colors.white,
                                        letterSpacing: 0.0)),
                                backgroundColor:
                                    MaterialStateProperty.all(Colors.blue),
                              ),
                              onPressed: _handleOk,
                              child: Text('Chọn'),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
