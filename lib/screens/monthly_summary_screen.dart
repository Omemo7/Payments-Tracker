import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart'; // Added fl_chart import
import 'package:payments_tracker_flutter/database/tables/transaction_table.dart';
// Assuming TransactionType is in add_edit_transaction_screen.dart
// If you moved it to a common file, update the import path.
import 'package:payments_tracker_flutter/global_variables/chosen_account.dart';
import 'add_edit_transaction_screen.dart' show TransactionType;

class MonthlySummaryScreen extends StatefulWidget {
  const MonthlySummaryScreen({super.key});

  @override
  State<MonthlySummaryScreen> createState() => _MonthlySummaryScreenState();
}

class _MonthlySummaryScreenState extends State<MonthlySummaryScreen> {
  final List<Map<String, dynamic>> _allTransactions = [
    // October 2023
    {'dateTime': DateTime(2023, 10, 5, 10, 0), 'notes': 'Salary Oct', 'amount': 2000.0, 'transactionType': TransactionType.income},
    {'dateTime': DateTime(2023, 10, 5, 11, 0), 'notes': 'Groceries', 'amount': 75.0, 'transactionType': TransactionType.expense},
    {'dateTime': DateTime(2023, 10, 10, 14, 30), 'notes': 'Dinner Out', 'amount': 45.0, 'transactionType': TransactionType.expense},
    {'dateTime': DateTime(2023, 10, 15, 8, 0), 'notes': 'Freelance Gig', 'amount': 300.0, 'transactionType': TransactionType.income},
    {'dateTime': DateTime(2023, 10, 28, 17, 0), 'notes': 'Movie Tickets', 'amount': 30.0, 'transactionType': TransactionType.expense},

    // November 2023
    {'dateTime': DateTime(2023, 11, 1, 9, 0), 'notes': 'Rent Nov', 'amount': 800.0, 'transactionType': TransactionType.expense},
    {'dateTime': DateTime(2023, 11, 5, 10, 0), 'notes': 'Salary Nov', 'amount': 2000.0, 'transactionType': TransactionType.income},
    {'dateTime': DateTime(2023, 11, 10, 12, 0), 'notes': 'Utility Bill', 'amount': 120.0, 'transactionType': TransactionType.expense},
    {'dateTime': DateTime(2023, 11, 10, 13, 0), 'notes': 'Lunch', 'amount': 15.0, 'transactionType': TransactionType.expense},
    {'dateTime': DateTime(2023, 11, 20, 18, 0), 'notes': 'Online Course', 'amount': 100.0, 'transactionType': TransactionType.expense},
    {'dateTime': DateTime(2023, 11, 22, 11, 0), 'notes': 'Consulting', 'amount': 500.0, 'transactionType': TransactionType.income},

    // December 2023
    {'dateTime': DateTime(2023, 12, 3, 10, 0), 'notes': 'Salary Dec', 'amount': 2100.0, 'transactionType': TransactionType.income},
    {'dateTime': DateTime(2023, 12, 3, 11, 0), 'notes': 'Holiday Shopping', 'amount': 150.0, 'transactionType': TransactionType.expense},
    {'dateTime': DateTime(2023, 12, 10, 15, 0), 'notes': 'Gas', 'amount': 40.0, 'transactionType': TransactionType.expense},
    {'dateTime': DateTime(2023, 12, 10, 16, 0), 'notes': 'More Holiday Shopping', 'amount': 80.0, 'transactionType': TransactionType.expense},
    {'dateTime': DateTime(2023, 12, 15, 9, 0), 'notes': 'Bonus', 'amount': -750.0, 'transactionType': TransactionType.income},
    {'dateTime': DateTime(2023, 12, 20, 19, 0), 'notes': 'New Year Party Contribution', 'amount': 50.0, 'transactionType': TransactionType.expense},

    // January 2024
    {'dateTime': DateTime(2024, 1, 2, 10, 0), 'notes': 'Salary Jan', 'amount': 2100.0, 'transactionType': TransactionType.income},
    {'dateTime': DateTime(2024, 1, 2, 14, 0), 'notes': 'Gym Membership', 'amount': 60.0, 'transactionType': TransactionType.expense},
  ];

  List<DateTime> _availableMonths = [];
  int _currentMonthIndex = -1;
  List<Map<String, dynamic>> _selectedMonthChartData = [];

  double _selectedMonthIncome = 0.0;
  double _selectedMonthExpense = 0.0;
  double _selectedMonthNet = 0.0;
  double _overallBalanceAtEndOfSelectedMonth = 0.0;

  @override
  void initState() {
    super.initState();
    _initializeScreen();
  }

  Future<void> _initializeScreen() async {
    await _processAvailableMonths();
    if (_availableMonths.isNotEmpty) {
      setState(() {
        _currentMonthIndex = 0; // Default to the most recent month
      });
      await _loadDataForSelectedMonth();
    }
  }

  Future<void> _processAvailableMonths() async {
    final Set<DateTime> uniqueMonthsSet = await TransactionTable.getUniqueTransactionMonthsForAccount(ChosenAccount().account?.id);
    _availableMonths = uniqueMonthsSet.toList();
    _availableMonths.sort((a, b) => b.compareTo(a));
  }

  Future<void> _loadDataForSelectedMonth() async {
    if (_currentMonthIndex < 0 || _currentMonthIndex >= _availableMonths.length) {
      setState(() {
        _selectedMonthChartData = [];
        _selectedMonthIncome = 0.0;
        _selectedMonthExpense = 0.0;
        _selectedMonthNet = 0.0;
        _overallBalanceAtEndOfSelectedMonth = 0.0;
      });
      return;
    }

    final DateTime selectedMonthDate = _availableMonths[_currentMonthIndex];

    final List<Map<String, dynamic>> chartDataForeachDayOfSelectedMonth = await TransactionTable.getDailyNetWithCumulativeBalanceForMonth(ChosenAccount().account?.id, selectedMonthDate);

    //Todo
    setState(() {
      _selectedMonthChartData = chartDataForeachDayOfSelectedMonth;
      _selectedMonthIncome = -1;
      _selectedMonthExpense = -1;
      _selectedMonthNet = -1;
      _overallBalanceAtEndOfSelectedMonth = -1;
    });
  }

  Future<void> _goToPreviousMonth() async {
    if (_currentMonthIndex < _availableMonths.length - 1) {
      setState(() {
        _currentMonthIndex++;
      });
      await _loadDataForSelectedMonth();
    }
  }

  Future<void> _goToNextMonth() async {
    if (_currentMonthIndex > 0) {
      setState(() { _currentMonthIndex--; });
      await _loadDataForSelectedMonth();
    }
  }

  String get _formattedCurrentMonth {
    if (_currentMonthIndex < 0 || _currentMonthIndex >= _availableMonths.length) {
      return "No data";
    }
    return DateFormat.yMMMM().format(_availableMonths[_currentMonthIndex]);
  }

  Widget _buildChart() {
    if (_selectedMonthChartData.isEmpty) {
      return const Center(
        child: Text(
          'No transaction data for this month to display chart.',
          style: TextStyle(color: Colors.blueGrey, fontSize: 16),
        ),
      );
    }

    List<BarChartGroupData> barGroups = [];
    double minY = 0;
    double maxY = 0;

    // `_selectedMonthChartData` is a List of Maps.
    // Each Map represents data for a single day in the selected month.
    // Example structure of each map (element in the list):
    // {
    //   'dayNumber': 1,                              // int: The day of the month (e.g., 1 for 1st, 2 for 2nd)
    //   'dailyNet': 50.0,                      // double: The net financial change for this specific day (income - expenses for this day)
    //   'cumulativeBalance': 150.0             // double: The cumulative balance for the month up to and including this day.
    // }
    //
    // So, when the loop `for (var data in _selectedMonthChartData)` runs:
    // - `data` will be one of these maps in each iteration.
    // - `data['day']` will access the day number.
    // - `data['dailyNet']` will access the net amount for that day.
    // - `data['cumulativeBalance']` will access the cumulative balance up to that day.
    //
    // This loop iterates through each day's processed data to:
    // 1. Determine the minimum and maximum `dailyNet` values to set the Y-axis scale of the chart (minY, maxY).
    // 2. Create a `BarChartGroupData` object for each day, which defines how the bar for that day will look on the chart.
    for (var data in _selectedMonthChartData) {
      final int day = data['dayNumber'] as int;
      final double dailyNet = data['dailyNet'] as double;
      
      if (dailyNet < minY) minY = dailyNet;
      if (dailyNet > maxY) maxY = dailyNet;

      barGroups.add(
        BarChartGroupData(
          x: day,
          barRods: [
            BarChartRodData(
              toY: dailyNet,
              color: dailyNet >= 0 ? Colors.green : Colors.red,
              width: 12, // Adjust bar width as needed
              borderRadius: BorderRadius.zero,
            ),
          ],
        ),
      );
    }
    // Add a small buffer to min/max Y for better chart readability
    if (minY == 0 && maxY == 0 && _selectedMonthChartData.isNotEmpty) { // All values are zero
        maxY = 100; // Default max Y if all values are zero
        minY = -100; // Default min Y
    } else {
        maxY = maxY + (maxY.abs() * 0.1); 
        minY = minY - (minY.abs() * 0.1);
         if (minY == 0 && maxY == 0) { // Still zero after buffer means no data
             maxY = 100;
             minY = 0; // if only positive or zero values, min can be 0
         } else if (minY == maxY) { // if all values are same (e.g. all 50)
            minY = minY > 0 ? minY - (minY.abs() * 0.5) : minY + (minY.abs() * 0.5);
            maxY = maxY > 0 ? maxY + (maxY.abs() * 0.5) : maxY - (maxY.abs() * 0.5);
            if (minY == 0 && maxY == 0) { // if min and max were both 0
                 minY = -10; maxY = 10;
            }
         }
    }


    return BarChart(
      BarChartData(
        barGroups: barGroups,
        minY: minY,
        maxY: maxY,
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (double value, TitleMeta meta) {
                // Show day numbers for every 1 or 5 days depending on chart data length
                final day = value.toInt();
                bool showTitle = _selectedMonthChartData.length <= 15 || day % 5 == 0 || day == 1 || day == _selectedMonthChartData.length;

                // Ensure day is within the valid range of _selectedMonthChartData
                // and that the day exists in the chart data (especially for months with less than 31 days)
                bool dayExistsInChart = _selectedMonthChartData.any((d) => d['dayNumber'] == day);

                if (!dayExistsInChart && day != 1 && (_availableMonths.isEmpty || _currentMonthIndex < 0 || day != DateTime(_availableMonths[_currentMonthIndex].year, _availableMonths[_currentMonthIndex].month + 1, 0).day) ) {
                  // Don't show title if the day is not in the data and not the first or last day of the month
                  // This can happen if the bar chart tries to render a label for a day that doesn't have data.
                  return Container();
                }

                if (showTitle) {
                   return SideTitleWidget(

                    axisSide: meta.axisSide,
                    space: 4.0, // Adjust as needed
                    child: Text(day.toString(), style: const TextStyle(fontSize: 10)), // Added child Text
                  );
                }
                return Container();
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (double value, TitleMeta meta) {
                // Show Y-axis titles with a reasonable interval
                if (value == meta.max || value == meta.min || value == 0) {
                     return SideTitleWidget(axisSide: meta.axisSide, space: 4.0, child: Text(value.toStringAsFixed(0), style: const TextStyle(fontSize: 10)));
                }
                if (meta.appliedInterval >= 20 && value % meta.appliedInterval == 0 && value !=0){
                     return SideTitleWidget(axisSide: meta.axisSide, space: 4.0, child: Text(value.toStringAsFixed(0), style: const TextStyle(fontSize: 10)));
                }
                 // Default, show fewer labels if interval is small
                if (meta.appliedInterval < 20 && (value % (meta.appliedInterval * 2) == 0) && value !=0 ) {
                     return SideTitleWidget(axisSide: meta.axisSide, space: 4.0, child: Text(value.toStringAsFixed(0), style: const TextStyle(fontSize: 10)));
                }
                return Container();
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.grey.shade300, width: 1),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          verticalInterval: _selectedMonthChartData.length > 15 ? 5.0 : 1.0,
          drawHorizontalLine: true,
          horizontalInterval: (maxY - minY).abs() / 5 > 0 ? (maxY - minY).abs() / 5 : 20, // Aim for ~5 horizontal lines
          getDrawingHorizontalLine: (value) {
            return const FlLine(color: Colors.grey, strokeWidth: 0.4);
          },
          getDrawingVerticalLine: (value) {
            return const FlLine(color: Colors.grey, strokeWidth: 0.4);
          },
        ),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              String day = 'Day ${group.x.toInt()}';
              return BarTooltipItem(
                '$day\n',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                children: <TextSpan>[
                  TextSpan(
                    text: rod.toY.toStringAsFixed(2),
                    style: TextStyle(
                      color: rod.toY >= 0 ? Colors.lightGreenAccent : Colors.redAccent,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Monthly Summary'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: _currentMonthIndex < _availableMonths.length - 1 ? () async => await _goToPreviousMonth() : null,
                  child: const Text('Older'),
                ),
                Text(
                  _formattedCurrentMonth,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                ElevatedButton(
                  onPressed: _currentMonthIndex > 0 ? () async => await _goToNextMonth() : null,
                  child: const Text('Newer'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              height: 300,
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0), // Added padding for the chart
              decoration: BoxDecoration(
                // border: Border.all(color: Colors.blueGrey), // Optional: keep border or remove
                borderRadius: BorderRadius.circular(8),
              ),
              child: _buildChart(), // Using the new chart widget
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Selected Month Income: ${_selectedMonthIncome.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16)),
                  Text('Selected Month Expense: ${_selectedMonthExpense.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16)),
                  Text('Selected Month Net: ${_selectedMonthNet.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('Overall Balance up to end of $_formattedCurrentMonth: ${_overallBalanceAtEndOfSelectedMonth.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 10),
            const Text('Processed Chart Data (for verification):', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Expanded(
              child: _selectedMonthChartData.isEmpty
                  ? const Center(child: Text('No transactions for this month.'))
                  : ListView.builder(
                      itemCount: _selectedMonthChartData.length,
                      itemBuilder: (context, index) {
                        final data = _selectedMonthChartData[index];
                        return ListTile(
                          title: Text('Day ${data['dayNumber']}'),
                          subtitle: Text('Net: ${data['dailyNet'].toStringAsFixed(2)}, Cumul (Month): ${data['cumulativeBalance'].toStringAsFixed(2)}'),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
