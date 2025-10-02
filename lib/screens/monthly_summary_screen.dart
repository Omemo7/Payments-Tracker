import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
// import 'package:fl_chart/fl_chart.dart'; // Removed fl_chart import
import 'package:payments_tracker_flutter/database/tables/transaction_table.dart';
import 'package:payments_tracker_flutter/widgets/navigation_buttons.dart';
import 'package:payments_tracker_flutter/global_variables/chosen_account.dart';
import 'package:payments_tracker_flutter/screens/daily_details_screen.dart';
import 'package:payments_tracker_flutter/global_variables/app_colors.dart';
// import 'add_edit_transaction_screen.dart' show TransactionType; // Assuming not needed for this change

// Placeholder for the daily details screen - you'll need to create this
// import 'package:payments_tracker_flutter/screens/daily_details_screen.dart';

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
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeScreenWithLoading();
  }

  Future<void> _initializeScreenWithLoading() async {
    setState(() { _isLoading = true; });
    await _initializeScreen();
    setState(() { _isLoading = false; });
  }

  Future<void> _initializeScreen() async {
    await _processAvailableMonths();
    if (_availableMonths.isNotEmpty) {
      setState(() {
        _currentMonthIndex = 0; // Default to the most recent month
      });
      await _loadDataForSelectedMonth(showLoading: false);
    }
  }

  Future<void> _processAvailableMonths() async {
    final Set<DateTime> uniqueMonthsSet = await TransactionTable.getUniqueTransactionMonthsForAccount(ChosenAccount().account?.id);
    _availableMonths = uniqueMonthsSet.toList();
    _availableMonths.sort((a, b) => b.compareTo(a));
  }

  Future<void> _loadDataForSelectedMonth({bool showLoading = true}) async {
    if (showLoading) setState(() { _isLoading = true; });

    if (_currentMonthIndex < 0 || _currentMonthIndex >= _availableMonths.length) {
      setState(() {
        _selectedMonthChartData = [];
        _selectedMonthIncome = 0.0;
        _selectedMonthExpense = 0.0;
        _selectedMonthNet = 0.0;
        _overallBalanceAtEndOfSelectedMonth = 0.0;
        if (showLoading) _isLoading = false;
      });
      return;
    }

    final DateTime selectedMonthDate = _availableMonths[_currentMonthIndex];

    final List<Map<String, dynamic>> chartDataForeachDayOfSelectedMonth = await TransactionTable.getDailyNetWithCumulativeBalanceForMonth(ChosenAccount().account?.id, selectedMonthDate);

    final Map<String, double> monthlySummary = await TransactionTable.getMonthlySummary(ChosenAccount().account?.id, selectedMonthDate);

    final double overallBalanceAtEndOfMonth = chartDataForeachDayOfSelectedMonth.isNotEmpty ? chartDataForeachDayOfSelectedMonth.last['cumulativeBalance'] : 0.0;

    setState(() {
      _selectedMonthChartData = chartDataForeachDayOfSelectedMonth;
      _selectedMonthIncome = monthlySummary['income'] ?? 0.0;
      _selectedMonthExpense = monthlySummary['expense'] ?? 0.0;
      _selectedMonthNet = _selectedMonthIncome-_selectedMonthExpense;
      _overallBalanceAtEndOfSelectedMonth = overallBalanceAtEndOfMonth;
      if (showLoading) _isLoading = false;
    });
  }

  Future<void> _goToPreviousMonth() async {
    if (_currentMonthIndex < _availableMonths.length - 1) {
      setState(() {
        _currentMonthIndex++; // 'Older' month means a higher index in the sorted list
      });
      await _loadDataForSelectedMonth();
    }
  }

  Future<void> _goToNextMonth() async {
    if (_currentMonthIndex > 0) { // 'Newer' month means a lower index
      setState(() { _currentMonthIndex--; });
      await _loadDataForSelectedMonth();
    }
  }

  Future<void> _goToCurrentMonth() async {
    // Find the index of the current system month (today's month) in _availableMonths
    final DateTime now = DateTime.now();
    final int currentSystemMonthIndex = _availableMonths.indexWhere((month) => month.year == now.year && month.month == now.month);
    setState(() { _currentMonthIndex = currentSystemMonthIndex != -1 ? currentSystemMonthIndex : 0; }); // Default to most recent if current not found
    await _loadDataForSelectedMonth();
  }

 Future<void> _openMonthPicker() async {
    if (_availableMonths.isEmpty) {
      return;
    }

    final int? selectedIndex = await showDialog<int>(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: const Text('Select Month'),
          children: [
            SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _availableMonths.length,
                itemBuilder: (context, index) {
                  final DateTime monthDate = _availableMonths[index];
                  final String formattedMonth = DateFormat.yMMMM().format(monthDate);
                  return ListTile(
                    title: Text(formattedMonth),
                    selected: index == _currentMonthIndex,
                    onTap: () => Navigator.of(context).pop(index),
                  );
                },
              ),
            ),
          ],
        );
      },
    );

    if (selectedIndex != null &&
        selectedIndex >= 0 &&
        selectedIndex < _availableMonths.length &&
        selectedIndex != _currentMonthIndex) {
      setState(() {
        _currentMonthIndex = selectedIndex;
      });
      await _loadDataForSelectedMonth(showLoading: true);
    }
  }

  String get _formattedCurrentMonth {
    if (_currentMonthIndex < 0 || _currentMonthIndex >= _availableMonths.length) {
      return "No data";
    }
    return DateFormat.yMMMM().format(_availableMonths[_currentMonthIndex]);
  }

  bool _isCurrentMonthDisplayed() {
    if (_availableMonths.isEmpty || _currentMonthIndex < 0) {
      // If there's no data or no selection, it can't be the current month.
      // Or, if there are no transactions at all, the "Current" button might point to the non-existent current month.
      // A check to see if any month in the list is the current month is also useful.
      final now = DateTime.now();
      return !_availableMonths.any((month) => month.year == now.year && month.month == now.month);
    }
    final DateTime now = DateTime.now();
    final DateTime displayedMonth = _availableMonths[_currentMonthIndex];
    return displayedMonth.year == now.year && displayedMonth.month == now.month;
  }

  bool _canGoToOlder() {
    if (_isLoading) return false;
    // Can go to an older month if the current index is not the last one
    return _currentMonthIndex < _availableMonths.length - 1;
  }

  bool _canGoToNewer() {
    if (_isLoading) return false;
    // Can go to a newer month if the current index is greater than 0
    return _currentMonthIndex > 0;
  }

  // _buildChart method is kept for now but not used.
  // You can remove it later if you are sure it's no longer needed.
  /*
  Widget _buildChart() {
    if (_selectedMonthChartData.isEmpty &&
        !(_currentMonthIndex >= 0 &&
            _currentMonthIndex < _availableMonths.length)) {
      return Center( 
        child: Column( 
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bar_chart_outlined, size: 50, color: Colors.blueGrey.shade300),
            const SizedBox(height: 10),
            Text(
              'No month selected or no data available.',
              textAlign: TextAlign.center, 
              style: TextStyle(color: Colors.blueGrey.shade700, fontSize: 16),
            ),
          ],
        ),
      );
    }

    final Map<int, double> dailyData = {
      for (var d in _selectedMonthChartData)
        d['dayNumber'] as int: d['dailyNet'] as double
    };

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
              color: value >= 0 ? Colors.green.shade400 : Colors.red.shade400,
              width: 12,
              borderRadius: const BorderRadius.all(Radius.circular(4)),
            ),
          ],
        ),
      );
    }

    if (minY == 0 && maxY == 0) {
      minY = -100; 
      maxY = 100;
    } else {
      double padding = (maxY - minY).abs() * 0.1; 
      if (padding < 10 && (maxY - minY).abs() > 0) padding = 10; 
      else if (padding == 0) padding = 10; 

      maxY = maxY + padding;
      minY = minY - padding;
    }
    if (maxY < 0 && minY < 0) maxY = 0;
    if (minY > 0 && maxY > 0) minY = 0;


    final axisLabelStyle = TextStyle(color: Colors.grey.shade700, fontSize: 10);
    final gridLineColor = Colors.grey.shade300;
    final double gridStrokeWidth = 0.5;
    double yAxisInterval = ((maxY - minY) / 5).abs();
    if (yAxisInterval < 1) yAxisInterval = 1; 
    else if (yAxisInterval > 20 && (maxY -minY) / yAxisInterval > 8) { 
        yAxisInterval = (yAxisInterval / 10).ceil() * 10.0;
    } else {
        yAxisInterval = yAxisInterval.roundToDouble();
    }
    if (yAxisInterval == 0) yAxisInterval = 20;


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
              reservedSize: 45, 
              interval: yAxisInterval,
              getTitlesWidget: (value, meta) {
                if (value == meta.min || value == meta.max || value == 0) {
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    space: 4.0,
                    child: Text(value.toStringAsFixed(0), style: axisLabelStyle),
                  );
                }
                if (value % meta.appliedInterval == 0) {
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
  */

  Widget _dailyTransactionCard(Map<String, dynamic> data, DateTime currentMonthDateTime) {
    final dayNumber = data['dayNumber'] as int;
    final dailyNet = data['dailyNet'] as double;
    final cumulativeBalance = data['cumulativeBalance'] as double;

    final DateTime specificDate = DateTime(currentMonthDateTime.year, currentMonthDateTime.month, dayNumber);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        title: Text(
          'Day $dayNumber - ${DateFormat.EEEE().format(specificDate)}', // e.g., Day 15 - Monday
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.deepPurple,
          ),
        ),
        // subtitle: Text(
        //   'Net: ${dailyNet.toStringAsFixed(2)}, Cumulative Balance: ${cumulativeBalance.toStringAsFixed(2)}',
        //   style: TextStyle(
        //     color: dailyNet >= 0 ? Colors.green.shade700 : Colors.red.shade700,
        //     fontWeight: FontWeight.w500,
        //   ),
        // ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4.0), // Added spacing
            Text(
              'Net: ${dailyNet.toStringAsFixed(2)}',
              style: TextStyle(
                color: dailyNet >= 0
                    ? AppColors.incomeGreen
                    : AppColors.expenseRed,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2.0), // Added spacing
            Text(
              'Balance: ${cumulativeBalance.toStringAsFixed(2)}',
              style: TextStyle(
                color: AppColors.deepPurple.withOpacity(0.7),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 4.0), // Added spacing at the end if needed for overall padding
          ],
        ),

        trailing: Icon(Icons.arrow_forward_ios,
            size: 16, color: AppColors.deepPurple.withOpacity(0.4)),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DailyDetailsScreen(
                selectedDate: specificDate,
                accountId: ChosenAccount().account?.id,
                dailyNet: dailyNet,
                cumulativeBalance: cumulativeBalance,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDailyTransactionCards() {
    if (_currentMonthIndex < 0 || _currentMonthIndex >= _availableMonths.length) {
      return const Center(child: Text("Select a month to see daily transactions."));
    }

    final List<Map<String, dynamic>> daysWithTransactions = _selectedMonthChartData
        .where((data) => data['dailyNet'] != null && data['dailyNet'] != 0.0)
        .toList();

    if (daysWithTransactions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.calendar_today_outlined,
                  size: 50, color: AppColors.deepPurple.withOpacity(0.2)),
              const SizedBox(height: 10),
              Text(
                'No transactions recorded for this month.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.deepPurple.withOpacity(0.6),
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final DateTime currentMonthDateTime = _availableMonths[_currentMonthIndex];

    return ListView.builder(
      itemCount: daysWithTransactions.length,
      itemBuilder: (context, index) {
        final data = daysWithTransactions[index];
        return _dailyTransactionCard(data, currentMonthDateTime);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Monthly Summary'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: _availableMonths.isEmpty ? null : () async => await _openMonthPicker(),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [

            const SizedBox(height: 10),
            Material(
              elevation: 4.0,
              shadowColor: AppColors.subtlePurple.withOpacity(0.15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15.0),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15.0),
                  color: AppColors.offWhite,
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
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.deepPurple,
                            ),
                          ),
                          const Icon(Icons.assessment,
                              color: AppColors.deepPurple, size: 28),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Divider(color: AppColors.subtlePurple.withOpacity(0.2), thickness: 1),
                      const SizedBox(height: 16),
                      _buildSummaryRow(
                        label: 'Income',
                        value: _selectedMonthIncome,
                        icon: Icons.arrow_upward,
                        color: AppColors.incomeGreen,
                      ),
                      const SizedBox(height: 10),
                      _buildSummaryRow(
                        label: 'Expense',
                        value: _selectedMonthExpense,
                        icon: Icons.arrow_downward,
                        color: AppColors.expenseRed,
                      ),
                      const SizedBox(height: 10),
                      _buildSummaryRow(
                        label: 'Net Balance',
                        value: _selectedMonthNet,
                        icon: _selectedMonthNet >= 0
                            ? Icons.trending_up
                            : Icons.trending_down,
                        color: _selectedMonthNet >= 0
                            ? AppColors.incomeGreen
                            : AppColors.expenseRed,
                        isBold: true,
                      ),
                      const SizedBox(height: 16),
                      Divider(color: AppColors.subtlePurple.withOpacity(0.2), thickness: 1),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Icon(Icons.account_balance_wallet,
                              color: AppColors.deepPurple, size: 22),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Overall Balance (End of Month):',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.deepPurple,
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
                                ? AppColors.incomeGreen
                                : AppColors.expenseRed,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Container(

                  child: _buildDailyTransactionCards(),
                ),
              ),
            ),
            NavigationButtons(
              canGoToOlder: _canGoToOlder(),
              canGoToNewer: _canGoToNewer(),
              isCurrent: _isCurrentMonthDisplayed(),
              onOlderPressed: _goToPreviousMonth,
              onNewerPressed: _goToNextMonth,
              onCurrentPressed: _goToCurrentMonth,
              isLoading: _isLoading,
            ),
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
              color: AppColors.deepPurple,
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
