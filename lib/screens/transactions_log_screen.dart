import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:payments_tracker_flutter/global_variables/chosen_account.dart';

import 'package:payments_tracker_flutter/widgets/transaction_info_card.dart';
import 'package:payments_tracker_flutter/screens/add_edit_transaction_screen.dart'; // For TransactionType
import 'package:payments_tracker_flutter/models/transaction_model.dart';
import 'package:payments_tracker_flutter/database/tables/transaction_table.dart';
import 'package:payments_tracker_flutter/models/account_model.dart'; // Import AccountModel
import 'package:payments_tracker_flutter/database/tables/account_table.dart'; // Import AccountTable
class TransactionsLogScreen extends StatefulWidget {
  const TransactionsLogScreen({super.key});

  @override
  State<TransactionsLogScreen> createState() => _TransactionsLogScreenState();
}
class _TransactionsLogScreenState extends State<TransactionsLogScreen> {
  DateTime _currentDisplayedDate = DateTime.now();
  List<DateTime> _sortedDaysWithTransactions = [];
  late DateTime _today;
  late Future<List<TransactionModel>> _dataLoadingFuture;

  @override
  void initState() {
    super.initState();
    _today = _normalizeDate(DateTime.now());
    _currentDisplayedDate = _today; // Initialize currentDisplayedDate
    // Placeholder: You'll need to decide how to select the initial account.
    // For now, let's assume you have a way to get the first account or a default one.
    // This part will need adjustment based on your account selection logic.
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    // The `!` (bang operator) here is a null assertion operator.
    // It tells the Dart compiler that you are certain that `ChosenAccount().account`
    // will not be null at this point, and therefore it's safe to access its `id` property.
    // If `ChosenAccount().account` were null, this would throw a runtime error.
    // This is often used when you have external guarantees or checks that ensure
    // the value won't be null, but the compiler can't infer it.

    _dataLoadingFuture = _loadDataForDateAndChosenAccount(_currentDisplayedDate, isInitialLoad: true);
    if (mounted) {
      setState(() {}); // Trigger a rebuild if needed, e.g., for AppBar title
    }
  }

  DateTime _normalizeDate(DateTime dateTime) {
    return DateTime(dateTime.year, dateTime.month, dateTime.day);
  }

  Future<List<TransactionModel>> _loadDataForDateAndChosenAccount(DateTime dateToLoad,  {bool isInitialLoad = false}) async {
    // No longer directly setting state for loading here, FutureBuilder handles it
    _currentDisplayedDate = _normalizeDate(dateToLoad);

    if (isInitialLoad || _sortedDaysWithTransactions.isEmpty) {
      // Refresh sorted days on initial load or if it becomes empty (e.g., after deleting all transactions for a day)
      _sortedDaysWithTransactions = await TransactionTable.getUniqueTransactionDatesForAccount(ChosenAccount().account?.id);
    }

    // Update AppBar title dynamically if needed, though FutureBuilder rebuilds UI
    // If the widget is still mounted, trigger a rebuild to update AppBar title
    if (mounted) {
      setState(() {}); 
    }
    return TransactionTable.getTransactionsForDateAndAccount(_currentDisplayedDate, ChosenAccount().account?.id);
  }

  void _triggerDataLoad(DateTime dateToLoad, {bool refreshSortedDays = false}) {
    setState(() {
      _dataLoadingFuture = _loadDataForDateAndChosenAccount(dateToLoad,  isInitialLoad: refreshSortedDays);
    });
  }

  void _goToOlderDay() {
    if (_sortedDaysWithTransactions.isEmpty) return;

    int currentIndex = _sortedDaysWithTransactions.indexWhere(
        (d) => d.isAtSameMomentAs(_currentDisplayedDate));

    if (currentIndex != -1 && currentIndex + 1 < _sortedDaysWithTransactions.length) {
      _triggerDataLoad(_sortedDaysWithTransactions[currentIndex + 1]);
    } else if (currentIndex == -1) {
      DateTime? olderDay;
      for (var day in _sortedDaysWithTransactions) {
        if (day.isBefore(_currentDisplayedDate)) {
          olderDay = day;
          break;
        }
      }
      if (olderDay != null) {
        _triggerDataLoad(olderDay);
      }
    }
  }

  void _goToNewerDay() {
    if (_sortedDaysWithTransactions.isEmpty) return;

    int currentIndex = _sortedDaysWithTransactions.indexWhere(
        (d) => d.isAtSameMomentAs(_currentDisplayedDate));

    if (currentIndex > 0) {
      _triggerDataLoad(_sortedDaysWithTransactions[currentIndex - 1]);
    } else if (currentIndex == -1) {
      DateTime? newerDay;
      for (int i = _sortedDaysWithTransactions.length - 1; i >= 0; i--) {
        var dayInList = _sortedDaysWithTransactions[i];
        if (dayInList.isAfter(_currentDisplayedDate) && !dayInList.isAfter(_today)) {
          newerDay = dayInList;
          break;
        }
      }
      if (newerDay != null) {
        _triggerDataLoad(newerDay);
      } else if (_sortedDaysWithTransactions.isNotEmpty &&
          !_sortedDaysWithTransactions.first.isAfter(_today) &&
          _sortedDaysWithTransactions.first.isAfter(_currentDisplayedDate)) {
        _triggerDataLoad(_sortedDaysWithTransactions.first);
      }
    }
  }

  void _goToToday() {
    _triggerDataLoad(_today);
  }

  bool _canGoToOlder(bool isLoading) {
    if (isLoading || _sortedDaysWithTransactions.isEmpty) return false;
    int currentIndex = _sortedDaysWithTransactions.indexWhere(
        (d) => d.isAtSameMomentAs(_currentDisplayedDate));
    if (currentIndex != -1) {
      return currentIndex + 1 < _sortedDaysWithTransactions.length;
    }
    return _sortedDaysWithTransactions.any((day) => day.isBefore(_currentDisplayedDate));
  }

  bool _canGoToNewer(bool isLoading) {
    if (isLoading || _sortedDaysWithTransactions.isEmpty) return false;
    if (_currentDisplayedDate.isAtSameMomentAs(_today) || _currentDisplayedDate.isAfter(_today)) return false;

    int currentIndex = _sortedDaysWithTransactions.indexWhere(
        (d) => d.isAtSameMomentAs(_currentDisplayedDate));
    if (currentIndex != -1) {
      return currentIndex > 0;
    }
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
          FutureBuilder<List<TransactionModel>>(
            future: _dataLoadingFuture,
            builder: (context, snapshot) {
              bool isLoadingSnapshot = snapshot.connectionState == ConnectionState.waiting;
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: Wrap(
                  spacing: 8.0,
                  runSpacing: 4.0,
                  alignment: WrapAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: isLoadingSnapshot || !_canGoToOlder(false) ? null : _goToOlderDay,
                      child: const Text('Older Day'),
                    ),
                    ElevatedButton(
                      onPressed: isLoadingSnapshot || (_normalizeDate(_currentDisplayedDate).isAtSameMomentAs(_today)) ? null : _goToToday,
                      child: const Text('Go to Today'),
                    ),
                    ElevatedButton(
                      onPressed: isLoadingSnapshot || !_canGoToNewer(false) ? null : _goToNewerDay,
                      child: const Text('Newer Day'),
                    ),
                  ],
                ),
              );
            },
          ),
          Expanded(
            child: FutureBuilder<List<TransactionModel>>(
              future: _dataLoadingFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error loading transactions: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text('No transactions for $formattedDate.'));
                } else {
                  final transactionsForDisplayedDate = snapshot.data!;
                  return ListView.builder(
                    itemCount: transactionsForDisplayedDate.length,
                    itemBuilder: (context, index) {
                      final transaction = transactionsForDisplayedDate[index];

                      return FutureBuilder<double>(
                        future: TransactionTable.getBalanceUntilTransactionByTransactionIdForAccount(transaction.id!,ChosenAccount().account!.id),
                        builder: (context, balanceSnapshot) {

                          return TransactionInfoCard(
                            transaction: transaction,
                            balance: balanceSnapshot.data ?? 0.0,

                            transactionType: transaction.amount > 0 ? TransactionType.income : TransactionType.expense,
                            todayDate: _today,
                            onEditPressed: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AddEditTransactionScreen(
                                    transactionToEdit: transaction,
                                    transactionType: transaction.amount > 0 ? TransactionType.income : TransactionType.expense,
                                    mode: ScreenMode.edit,
                                  ),
                                ),
                              );
                              if (result == true) {
                                _triggerDataLoad(_currentDisplayedDate); // Refresh current day's data
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
                                await TransactionTable.deleteTransaction(transaction.id!);

                                _triggerDataLoad(_currentDisplayedDate, refreshSortedDays: true); 
                              }
                            },
                          );
                        });
                    },
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
