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

    final Map<String, double> monthlySummary = await TransactionTable.getMonthlySummary(ChosenAccount().account?.id, selectedMonthDate);

    // Get the latest cumulative balance from the chart data, which represents the balance at the end of the month
    final double overallBalanceAtEndOfMonth = chartDataForeachDayOfSelectedMonth.isNotEmpty ? chartDataForeachDayOfSelectedMonth.last['cumulativeBalance'] : 0.0;

    setState(() {
      _selectedMonthChartData = chartDataForeachDayOfSelectedMonth;
      _selectedMonthIncome = monthlySummary['income'] ?? 0.0;
      _selectedMonthExpense = monthlySummary['expense'] ?? 0.0;
      _selectedMonthNet = _selectedMonthIncome-_selectedMonthExpense;
      _overallBalanceAtEndOfSelectedMonth = overallBalanceAtEndOfMonth;
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
    if (_selectedMonthChartData.isEmpty &&
        !(_currentMonthIndex >= 0 &&
            _currentMonthIndex < _availableMonths.length)) {
      return Center( // Keep this centered
        child: Column( // Added for potential icon + text
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bar_chart_outlined, size: 50, color: Colors.blueGrey.shade300),
            const SizedBox(height: 10),
            Text(
              'No month selected or no data available.',
              textAlign: TextAlign.center, // Ensure text is centered if it wraps
              style: TextStyle(color: Colors.blueGrey.shade700, fontSize: 16),
            ),
          ],
        ),
      );
    }

    // --- Build day → value lookup for fast access
    final Map<int, double> dailyData = {
      for (var d in _selectedMonthChartData)
        d['dayNumber'] as int: d['dailyNet'] as double
    };

    // --- Build bar groups based on actual days in the month
    List<BarChartGroupData> barGroups = [];
    double minY = 0;
    double maxY = 0;
    final DateTime currentMonthDateTime = _availableMonths[_currentMonthIndex];
    final int daysInMonth = DateUtils.getDaysInMonth(currentMonthDateTime.year, currentMonthDateTime.month);

    for (int day = 1; day <= daysInMonth; day++) {
      final value = dailyData[day] ?? 0;

      if (value < minY) minY = value;
      if (value > maxY) maxY = value;

      barGroups.add(
        BarChartGroupData(
          x: day,
          barRods: [
            BarChartRodData(
              toY: value,
              color: value >= 0 ? Colors.green.shade400 : Colors.red.shade400, // Slightly lighter shades
              width: 12,
              borderRadius: const BorderRadius.all(Radius.circular(4)), // Rounded corners
            ),
          ],
        ),
      );
    }

    // --- Adjust Y range for padding and to ensure 0 is visible
    if (minY == 0 && maxY == 0) {
      minY = -100; // Default range if no data or all data is zero
      maxY = 100;
    } else {
      double padding = (maxY - minY).abs() * 0.1; // 10% padding
      if (padding < 10 && (maxY - minY).abs() > 0) padding = 10; // Minimum padding if range is very small but not zero
      else if (padding == 0) padding = 10; // Minimum padding if range is zero (e.g. all values are the same)

      maxY = maxY + padding;
      minY = minY - padding;
    }
    // Ensure 0 is visible if data is all positive or all negative by extending range to include it
    if (maxY < 0 && minY < 0) maxY = 0;
    if (minY > 0 && maxY > 0) minY = 0;


    final axisLabelStyle = TextStyle(color: Colors.grey.shade700, fontSize: 10);
    final gridLineColor = Colors.grey.shade300;
    final double gridStrokeWidth = 0.5;
    // Calculate a dynamic interval for Y-axis aiming for ~5-6 labels
    double yAxisInterval = ((maxY - minY) / 5).abs();
    if (yAxisInterval < 1) yAxisInterval = 1; // Minimum interval of 1 if range is too small
    else if (yAxisInterval > 20 && (maxY -minY) / yAxisInterval > 8) { // If interval is large, try to make it a rounder number
        yAxisInterval = (yAxisInterval / 10).ceil() * 10.0;
    } else {
        yAxisInterval = yAxisInterval.roundToDouble();
    }
    if (yAxisInterval == 0) yAxisInterval = 20; // Default if calculation leads to 0


    return BarChart(
      BarChartData(
        baselineY: 0,
        minY: minY,
        maxY: maxY,
        barGroups: barGroups,
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final day = value.toInt();
                if (day == 1 || day % 5 == 0 || day == daysInMonth) {
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    space: 4.0,
                    child: Text(day.toString(), style: axisLabelStyle),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 45, // Increased reserved size
              interval: yAxisInterval,
              getTitlesWidget: (value, meta) {
                // Show 0, min, max, and interval-based ticks
                if (value == meta.min || value == meta.max || value == 0) {
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    space: 4.0,
                    child: Text(value.toStringAsFixed(0), style: axisLabelStyle),
                  );
                }
                if (value % meta.appliedInterval == 0) {
                     // Avoid cluttering if label is too close to min/max/0 already shown
                    bool isCloseToMin = (value - meta.min).abs() < meta.appliedInterval * 0.4;
                    bool isCloseToMax = (meta.max - value).abs() < meta.appliedInterval * 0.4;
                    bool isCloseToZero = (value - 0).abs() < meta.appliedInterval * 0.4 && (meta.min < 0 && meta.max > 0);

                    if (!isCloseToMin && !isCloseToMax && !isCloseToZero) {
                         return SideTitleWidget(
                           axisSide: meta.axisSide,
                           space: 4.0,
                           child: Text(value.toStringAsFixed(0), style: axisLabelStyle),
                         );
                    }
                }
                return const SizedBox.shrink();
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
          verticalInterval: 1.0,
          drawHorizontalLine: true,
          horizontalInterval: yAxisInterval,
          getDrawingHorizontalLine: (value) =>
            FlLine(color: gridLineColor, strokeWidth: gridStrokeWidth),
          getDrawingVerticalLine: (value) {
            final day = value.toInt();
            if (day == 1 || day % 5 == 0 || day == daysInMonth) {
              return FlLine(color: gridLineColor, strokeWidth: gridStrokeWidth);
            }
            return FlLine(color: gridLineColor.withOpacity(0.5), strokeWidth: gridStrokeWidth / 2);
          },
        ),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            tooltipBgColor: Colors.blueGrey.shade700.withOpacity(0.9),
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              String dayFormatted = 'Day ${group.x.toInt()}';
              return BarTooltipItem(
                '$dayFormatted\n',
                TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  shadows: [
                    Shadow(
                      blurRadius: 2.0,
                      color: Colors.black.withOpacity(0.5),
                      offset: Offset(1, 1),
                    ),
                  ]
                ),
                children: <TextSpan>[
                  TextSpan(
                    text: rod.toY.toStringAsFixed(2),
                    style: TextStyle(
                      color: rod.toY >= 0
                          ? Colors.lightGreenAccent.shade100
                          : Colors.redAccent.shade100,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                       shadows: [
                        Shadow(
                          blurRadius: 2.0,
                          color: Colors.black.withOpacity(0.5),
                          offset: Offset(1, 1),
                        ),
                      ]
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
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                // Optional: Add a subtle border or background to the chart container itself
                // border: Border.all(color: Colors.grey.shade300),
                // color: Colors.white,
                 boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 3,
                    offset: Offset(0, 1), // changes position of shadow
                  ),
                ],
              ),
              child: _buildChart(),
            ),
            const SizedBox(height: 20), 
            Material( 
              elevation: 6.0,
              shadowColor: Colors.blueGrey.withOpacity(0.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15.0),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15.0),
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade100, Colors.blue.shade50],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Summary: $_formattedCurrentMonth',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade800,
                            ),
                          ),
                          Icon(Icons.assessment, color: Colors.blue.shade700, size: 28),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Divider(color: Colors.blue.shade200, thickness: 1),
                      const SizedBox(height: 16),
                      _buildSummaryRow(
                        label: 'Income',
                        value: _selectedMonthIncome,
                        icon: Icons.arrow_upward,
                        color: Colors.green.shade600,
                      ),
                      const SizedBox(height: 10),
                      _buildSummaryRow(
                        label: 'Expense',
                        value: _selectedMonthExpense,
                        icon: Icons.arrow_downward,
                        color: Colors.red.shade600,
                      ),
                      const SizedBox(height: 10),
                      _buildSummaryRow(
                        label: 'Net Profit/Loss',
                        value: _selectedMonthNet,
                        icon: _selectedMonthNet >= 0 ? Icons.trending_up : Icons.trending_down,
                        color: _selectedMonthNet >= 0 ? Colors.teal.shade600 : Colors.orange.shade700,
                        isBold: true,
                      ),
                      const SizedBox(height: 16),
                      Divider(color: Colors.blue.shade200, thickness: 1),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Icon(Icons.account_balance_wallet, color: Colors.indigo.shade600, size: 22),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Overall Balance (End of Month):', // Clarified label
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.indigo.shade700,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Padding(
                        padding: const EdgeInsets.only(left: 32.0), 
                        child: Text(
                          _overallBalanceAtEndOfSelectedMonth.toStringAsFixed(2),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _overallBalanceAtEndOfSelectedMonth >= 0
                                ? Colors.indigo.shade900
                                : Colors.red.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            // The following ListView is for debugging/verification, consider removing or styling it for production
            // const Text('Processed Chart Data (for verification):', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            // Expanded(
            //   child: _selectedMonthChartData.isEmpty && !(_currentMonthIndex >= 0 && _currentMonthIndex < _availableMonths.length)
            //       ? const Center(child: Text('No transactions for this month.'))
            //       : ListView.builder(
            //           itemCount: _selectedMonthChartData.length,
            //           itemBuilder: (context, index) {
            //             final data = _selectedMonthChartData[index];
            //             return ListTile(
            //               title: Text('Day ${data['dayNumber']}'),
            //               subtitle: Text('Net: ${data['dailyNet'].toStringAsFixed(2)}, Cumul (Month): ${data['cumulativeBalance'].toStringAsFixed(2)}'),
            //             );
            //           },
            //         ),
            // ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow({
    required String label,
    required double value,
    required IconData icon,
    required Color color,
    bool isBold = false,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            '$label:',
            style: TextStyle(
              fontSize: 16,
              color: Colors.black87,
              fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
        Text(
          value.toStringAsFixed(2),
          style: TextStyle(
            fontSize: 16,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }
}
