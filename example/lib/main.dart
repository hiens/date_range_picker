import 'package:flutter/material.dart';
import 'package:date_range_picker/date_range_picker.dart' as date_range_picker;
import 'package:flutter_localizations/flutter_localizations.dart';

void main() {
  runApp(const MaterialApp(
    title: 'Flutter Demo',
    localizationsDelegates: [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: [Locale('vi', 'VN')],
    home: MyHomePage(),
  ));
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Future<void> _getDateRange() async {
    final dateRange = await date_range_picker.showDateRangePicker(
        context: context,
        firstDate: DateTime(2010),
        lastDate: DateTime(2030),
        initialFirstDate: DateTime(2022, 1, 1),
        initialLastDate: DateTime(2022, 1, 10),
        selectionMode: date_range_picker.DatePickerSelectionMode.custom,
        initialDatePickerMode: date_range_picker.DatePickerMode.day,
        locale: const Locale('vi'),
        maxRange: 10);
    print(dateRange);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Date range picker example'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          ElevatedButton.icon(
            onPressed: _getDateRange,
            icon: const Icon(Icons.event),
            label: const Text('Get date range'),
          )
        ],
      ),
    );
  }
}
