import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Added for date formatting
import './transaction_info_card.dart';
import './add_edit_transaction_screen.dart'; // For TransactionType

class TransactionDetailsScreen extends StatefulWidget {
  const TransactionDetailsScreen({super.key});

  @override
  State<TransactionDetailsScreen> createState() => _TransactionDetailsScreenState();
}

class _TransactionDetailsScreenState extends State<TransactionDetailsScreen> {
  // Sample list of transactions - replace with your actual data source
  // Modified to ensure transactions span a few different days for better testing
  final List<Map<String, dynamic>> _allTransactions = List.generate(
    15, // Create 15 sample transactions
    (index) {
      int dayOffset = index ~/ 3; // Groups of 3 transactions per day for variety
      return {
        'dateTime': DateTime.now().subtract(Duration(days: dayOffset, hours: index % 3)),
        'notes': 'Transaction notes for item ${index + 1}. Day offset: $dayOffset',
        'amount': (index + 1) * 15.50,
        'balance': 1000.0 - ((index + 1) * 15.50),
        'transactionType': index.isEven ? TransactionType.income : TransactionType.expense,
      };
    },
  );

  Map<DateTime, List<Map<String, dynamic>>> _groupedTransactionsByDay = {};
  List<DateTime> _sortedDays = [];
  int _currentDayIndex = 0;

  @override
  void initState() {
    super.initState();
    _groupTransactions();
  }

  void _groupTransactions() {
    final Map<DateTime, List<Map<String, dynamic>>> tempGrouped = {};
    for (var transaction in _allTransactions) {
      final DateTime dateKey = DateTime(
        (transaction['dateTime'] as DateTime).year,
        (transaction['dateTime'] as DateTime).month,
        (transaction['dateTime'] as DateTime).day,
      );
      if (tempGrouped[dateKey] == null) {
        tempGrouped[dateKey] = [];
      }
      tempGrouped[dateKey]!.add(transaction);
    }
    _groupedTransactionsByDay = tempGrouped;
    _sortedDays = _groupedTransactionsByDay.keys.toList();
    // Sort days in descending order (most recent first)
    _sortedDays.sort((a, b) => b.compareTo(a));

    if (_sortedDays.isNotEmpty) {
        _currentDayIndex = 0; // Start with the most recent day
    } else {
        _currentDayIndex = -1; // No transactions
    }
  }

  List<Map<String, dynamic>> get _currentTransactionsOnPage {
    if (_sortedDays.isEmpty || _currentDayIndex < 0 || _currentDayIndex >= _sortedDays.length) {
      return [];
    }
    final DateTime currentDayKey = _sortedDays[_currentDayIndex];
    return _groupedTransactionsByDay[currentDayKey] ?? [];
  }

  int get _totalPages => _sortedDays.length;

  String get _formattedCurrentDay {
      if (_sortedDays.isEmpty || _currentDayIndex < 0 || _currentDayIndex >= _sortedDays.length) {
          return "No transactions";
      }
      return DateFormat('MMM d, yyyy').format(_sortedDays[_currentDayIndex]);
  }

  void _goToPreviousDay() { // Shows an older day
    if (_currentDayIndex < _sortedDays.length - 1) {
      setState(() {
        _currentDayIndex++;
      });
    }
  }

  void _goToNextDay() { // Shows a newer day
    if (_currentDayIndex > 0) {
      setState(() {
        _currentDayIndex--;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> transactionsToShow = _currentTransactionsOnPage;

    return Scaffold(
      appBar: AppBar(
        title: Text('Details - $_formattedCurrentDay'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: transactionsToShow.isEmpty
                ? const Center(child: Text('No transactions for this day.'))
                : ListView.builder(
                    itemCount: transactionsToShow.length,
                    itemBuilder: (context, index) {
                      final transaction = transactionsToShow[index];
                      return TransactionInfoCard(
                        balance: transaction['balance'] as double,
                        dateTime: transaction['dateTime'] as DateTime,
                        notes: transaction['notes'] as String,
                        amount: transaction['amount'] as double,
                        transactionType: transaction['transactionType'] as TransactionType,
                        onEditPressed: () {
                          print('Edit pressed for transaction with notes: ${transaction['notes']}');
                        },
                        onDeletePressed: () {
                          print('Delete pressed for transaction with notes: ${transaction['notes']}');
                        },
                      );
                    },
                  ),
          ),
          if (_totalPages > 1)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(
                    // "Older Day" button should be enabled if there are older days to show
                    onPressed: _currentDayIndex < _totalPages - 1 ? _goToPreviousDay : null,
                    child: const Text('Older Day'),
                  ),
                  Text('Day ${_totalPages - _currentDayIndex} of $_totalPages'), // Correctly reflect page order
                  ElevatedButton(
                    // "Newer Day" button should be enabled if there are newer days to show
                    onPressed: _currentDayIndex > 0 ? _goToNextDay : null,
                    child: const Text('Newer Day'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
