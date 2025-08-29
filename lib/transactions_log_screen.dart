import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:payments_tracker_flutter/database_helper.dart';
import 'package:payments_tracker_flutter/transaction_info_card.dart';
import 'package:payments_tracker_flutter/add_edit_transaction_screen.dart'; // For TransactionType
import 'package:payments_tracker_flutter/transaction_model.dart';

class TransactionsLogScreen extends StatefulWidget {
  const TransactionsLogScreen({super.key});

  @override
  State<TransactionsLogScreen> createState() => _TransactionsLogScreenState();
}

class _TransactionsLogScreenState extends State<TransactionsLogScreen> {
  DateTime _currentDisplayedDate = DateTime.now();
  List<TransactionModel> _transactionsForDisplayedDate = [];
  List<DateTime> _sortedDaysWithTransactions = [];
  bool _isLoading = true;
  late DateTime _today;

  @override
  void initState() {
    super.initState();
    _today = _normalizeDate(DateTime.now());
    _initializeScreenData();
  }

  DateTime _normalizeDate(DateTime dateTime) {
    return DateTime(dateTime.year, dateTime.month, dateTime.day);
  }

  Future<void> _initializeScreenData() async {
    setState(() {
      _isLoading = true;
    });
    // Fetch all unique days that have transactions
    _sortedDaysWithTransactions = await DatabaseHelper.instance.getUniqueTransactionDates();
    // Initially load transactions for today
    await _fetchTransactionsForDate(_today);
  }

  Future<void> _fetchTransactionsForDate(DateTime dateToLoad) async {
    setState(() {
      _isLoading = true;
      _currentDisplayedDate = _normalizeDate(dateToLoad);
    });
    _transactionsForDisplayedDate = await DatabaseHelper.instance.getTransactionsForDate(_currentDisplayedDate);
    setState(() {
      _isLoading = false;
    });
  }

  void _goToOlderDay() {
    if (_sortedDaysWithTransactions.isEmpty) return;
    
    int currentIndex = _sortedDaysWithTransactions.indexWhere(
        (d) => d.isAtSameMomentAs(_currentDisplayedDate));

    if (currentIndex != -1 && currentIndex + 1 < _sortedDaysWithTransactions.length) {
      _fetchTransactionsForDate(_sortedDaysWithTransactions[currentIndex + 1]);
    } else if (currentIndex == -1) {
        // Current date not in the list (e.g. today has no transactions)
        // Find the first day in the sorted list that is before the current displayed date
        DateTime? olderDay;
        for (var day in _sortedDaysWithTransactions) {
            if (day.isBefore(_currentDisplayedDate)) {
                olderDay = day;
                break;
            }
        }
        if (olderDay != null) {
             _fetchTransactionsForDate(olderDay);
        }
    }
  }

  void _goToNewerDay() {
    if (_sortedDaysWithTransactions.isEmpty) return;

    int currentIndex = _sortedDaysWithTransactions.indexWhere(
        (d) => d.isAtSameMomentAs(_currentDisplayedDate));
    
    if (currentIndex > 0) { 
      _fetchTransactionsForDate(_sortedDaysWithTransactions[currentIndex - 1]);
    } else if (currentIndex == -1) {
        // Current date not in the list (e.g. displayed date was manually set or it's a future date with no transactions yet)
        // Find the most recent day in the sorted list that is after the current displayed date but not after today
        DateTime? newerDay;
        for (int i = _sortedDaysWithTransactions.length - 1; i >= 0; i--) {
            var dayInList = _sortedDaysWithTransactions[i];
            if (dayInList.isAfter(_currentDisplayedDate) && !dayInList.isAfter(_today)) {
                newerDay = dayInList;
                break; 
            }
        }
        if (newerDay != null) {
            _fetchTransactionsForDate(newerDay);
        } else if (_sortedDaysWithTransactions.isNotEmpty && 
                   !_sortedDaysWithTransactions.first.isAfter(_today) && 
                   _sortedDaysWithTransactions.first.isAfter(_currentDisplayedDate)){
            _fetchTransactionsForDate(_sortedDaysWithTransactions.first);
        }
    }
  }

  void _goToToday() {
    _fetchTransactionsForDate(_today);
  }

  bool _canGoToOlder() {
    if (_isLoading || _sortedDaysWithTransactions.isEmpty) return false;
    int currentIndex = _sortedDaysWithTransactions.indexWhere(
        (d) => d.isAtSameMomentAs(_currentDisplayedDate));
    if (currentIndex != -1) {
      return currentIndex + 1 < _sortedDaysWithTransactions.length;
    }
    // If current day not in list, check if there's any day in list older than current
    return _sortedDaysWithTransactions.any((day) => day.isBefore(_currentDisplayedDate));
  }

  bool _canGoToNewer() {
    if (_isLoading || _sortedDaysWithTransactions.isEmpty) return false;
    if (_currentDisplayedDate.isAtSameMomentAs(_today) || _currentDisplayedDate.isAfter(_today)) return false;

    int currentIndex = _sortedDaysWithTransactions.indexWhere(
        (d) => d.isAtSameMomentAs(_currentDisplayedDate));
    if (currentIndex != -1) {
      return currentIndex > 0; // Can go newer if not the newest (first in sorted list)
    }
    // If current day not in list, check if there's any day in list newer than current but not after today
    return _sortedDaysWithTransactions.any((day) => day.isAfter(_currentDisplayedDate) && !day.isAfter(_today));
  }

  @override
  Widget build(BuildContext context) {
    String formattedDate = DateFormat('EEE, MMM d, yyyy').format(_currentDisplayedDate);

    return Scaffold(
      appBar: AppBar(
        title: Text('Log: $formattedDate'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Wrap( 
              spacing: 8.0,
              runSpacing: 4.0,
              alignment: WrapAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _canGoToOlder() ? _goToOlderDay : null,
                  child: const Text('Older Day'),
                ),
                ElevatedButton(
                  onPressed: (_normalizeDate(_currentDisplayedDate).isAtSameMomentAs(_today)) ? null : _goToToday,
                  child: const Text('Go to Today'),
                ),
                ElevatedButton(
                  onPressed: _canGoToNewer() ? _goToNewerDay : null,
                  child: const Text('Newer Day'),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _transactionsForDisplayedDate.isEmpty
                    ? Center(child: Text('No transactions for $formattedDate.'))
                    : ListView.builder(
                        itemCount: _transactionsForDisplayedDate.length,
                        itemBuilder: (context, index) {
                          final transaction = _transactionsForDisplayedDate[index];
                          return FutureBuilder<double>(
                            future: DatabaseHelper.instance.getBalanceUntilTransactionByTransactionId(transaction.id!),
                            builder: (context, snapshot) {
                              return TransactionInfoCard(
                                transaction: transaction,
                                balance: snapshot.data ?? 0.0, 
                                transactionType: transaction.amount > 0 ? TransactionType.income : TransactionType.expense,
                                todayDate: _today, 
                                onEditPressed: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => AddEditTransactionScreen(
                                        transactionToEdit: transaction, // Changed here
                                        transactionType: transaction.amount > 0 ? TransactionType.income : TransactionType.expense,
                                        mode: ScreenMode.edit,
                                        ),
                                    ),
                                  );
                                  if (result == true) {
                                    _fetchTransactionsForDate(_currentDisplayedDate);
                                  }
                                },
                                onDeletePressed: () async {
                                  final confirmDelete = await showDialog<bool>(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title: const Text('Confirm Delete'),
                                        content: const Text('Are you sure you want to delete this transaction?'),
                                        actions: <Widget>[
                                          TextButton(
                                            child: const Text('Cancel'),
                                            onPressed: () {
                                              Navigator.of(context).pop(false);
                                            },
                                          ),
                                          TextButton(
                                            child: const Text('Delete'),
                                            onPressed: () {
                                              Navigator.of(context).pop(true);
                                            },
                                          ),
                                        ],
                                      );
                                    },
                                  );

                                  if (confirmDelete == true && transaction.id != null) {
                                    await DatabaseHelper.instance.deleteTransaction(transaction.id!);
                                    // Re-initialize to update sortedDaysWithTransactions and current day's view
                                    await _initializeScreenData(); 
                                  }
                                },
                              );
                            });
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
