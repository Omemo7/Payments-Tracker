import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
// Assuming TransactionType is in add_edit_transaction_screen.dart
// If you moved it to a common file, update the import path.
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
    {'dateTime': DateTime(2023, 12, 15, 9, 0), 'notes': 'Bonus', 'amount': 750.0, 'transactionType': TransactionType.income},
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
    _processAvailableMonths();
    if (_availableMonths.isNotEmpty) {
      _currentMonthIndex = 0; // Default to the most recent month
      _prepareChartDataForSelectedMonth();
    }
  }

  void _processAvailableMonths() {
    if (_allTransactions.isEmpty) return;

    final Set<DateTime> uniqueMonthsSet = {};
    for (var transaction in _allTransactions) {
      final DateTime dt = transaction['dateTime'] as DateTime;
      uniqueMonthsSet.add(DateTime(dt.year, dt.month, 1));
    }
    _availableMonths = uniqueMonthsSet.toList();
    _availableMonths.sort((a, b) => b.compareTo(a));
  }

  void _prepareChartDataForSelectedMonth() {
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
    final List<Map<String, dynamic>> transactionsForMonth = _allTransactions.where((t) {
      final DateTime dt = t['dateTime'] as DateTime;
      return dt.year == selectedMonthDate.year && dt.month == selectedMonthDate.month;
    }).toList();

    double monthIncome = 0.0;
    double monthExpense = 0.0;

    for (var transaction in transactionsForMonth) {
      final double amount = transaction['amount'] as double;
      final TransactionType type = transaction['transactionType'] as TransactionType;
      if (type == TransactionType.income) {
        monthIncome += amount;
      } else {
        monthExpense += amount;
      }
    }
    final double monthNet = monthIncome - monthExpense;

    final int daysInMonth = DateTime(selectedMonthDate.year, selectedMonthDate.month + 1, 0).day;
    final List<Map<String, dynamic>> chartData = [];
    double cumulativeBalanceForMonth = 0;

    for (int day = 1; day <= daysInMonth; day++) {
      double dailyNet = 0;
      for (var transaction in transactionsForMonth) {
        final DateTime dt = transaction['dateTime'] as DateTime;
        if (dt.day == day) {
          final double amount = transaction['amount'] as double;
          final TransactionType type = transaction['transactionType'] as TransactionType;
          dailyNet += (type == TransactionType.income ? amount : -amount);
        }
      }
      cumulativeBalanceForMonth += dailyNet;
      chartData.add({
        'day': day,
        'dailyNet': dailyNet,
        'cumulativeBalance': cumulativeBalanceForMonth,
      });
    }

    double overallBalance = 0.0;
    final DateTime lastDayOfSelectedMonth = DateTime(selectedMonthDate.year, selectedMonthDate.month, daysInMonth, 23, 59, 59);
    for (var transaction in _allTransactions) {
      final DateTime dt = transaction['dateTime'] as DateTime;
      if (dt.isBefore(lastDayOfSelectedMonth) || dt.isAtSameMomentAs(lastDayOfSelectedMonth)) {
        final double amount = transaction['amount'] as double;
        final TransactionType type = transaction['transactionType'] as TransactionType;
        overallBalance += (type == TransactionType.income ? amount : -amount);
      }
    }
    
    setState(() {
      _selectedMonthChartData = chartData;
      _selectedMonthIncome = monthIncome;
      _selectedMonthExpense = monthExpense;
      _selectedMonthNet = monthNet;
      _overallBalanceAtEndOfSelectedMonth = overallBalance;
    });
  }

  void _goToPreviousMonth() {
    if (_currentMonthIndex < _availableMonths.length - 1) {
      setState(() {
        _currentMonthIndex++;
        _prepareChartDataForSelectedMonth();
      });
    }
  }

  void _goToNextMonth() {
    if (_currentMonthIndex > 0) {
      setState(() {
        _currentMonthIndex--;
        _prepareChartDataForSelectedMonth();
      });
    }
  }

  String get _formattedCurrentMonth {
    if (_currentMonthIndex < 0 || _currentMonthIndex >= _availableMonths.length) {
      return "No data";
    }
    return DateFormat.yMMMM().format(_availableMonths[_currentMonthIndex]);
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
                  onPressed: _currentMonthIndex < _availableMonths.length - 1 ? _goToPreviousMonth : null,
                  child: const Text('Older Month'),
                ),
                Text(
                  _formattedCurrentMonth,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                ElevatedButton(
                  onPressed: _currentMonthIndex > 0 ? _goToNextMonth : null,
                  child: const Text('Newer Month'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              height: 300,
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blueGrey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Text(
                  'Chart Placeholder\n(Integrate a charting library here)',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.blueGrey, fontSize: 16),
                ),
              ),
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
                          title: Text('Day ${data['day']}'),
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
