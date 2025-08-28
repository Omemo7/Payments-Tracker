import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Added for date formatting
import 'package:payments_tracker_flutter/database_helper.dart';
import './transaction_info_card.dart';
import './add_edit_transaction_screen.dart'; // For TransactionType
import 'transaction_model.dart';
import 'database_helper.dart';
class TransactionsLogScreen extends StatefulWidget {
  const TransactionsLogScreen({super.key});

  @override
  State<TransactionsLogScreen> createState() => _TransactionsLogScreenState();
}

class _TransactionsLogScreenState extends State<TransactionsLogScreen> {
  // Sample list of transactions - replace with your actual data source
  // Modified to ensure transactions span a few different days for better testing
  List<TransactionModel> _allTransactions = [];


  @override
  void initState() {
    super.initState();
    _loadTransactions();

  }
  Future<void> _loadTransactions() async {
    final transactions = await DatabaseHelper.instance.getAllTransactions();
    setState(() {
      _allTransactions = transactions;
    });
  }





  @override
  Widget build(BuildContext context) {
    final List<TransactionModel> transactionsToShow = _allTransactions;

    return Scaffold(
      appBar: AppBar(
        title: Text('Transactions Log'),
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
                      return FutureBuilder<double>(
                        future: DatabaseHelper.instance.getBalanceUntilTransactionByTransactionId(transaction.id!),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          } else if (snapshot.hasError) {
                            return Center(child: Text('Error: ${snapshot.error}'));
                          }
                          return TransactionInfoCard(
                            transaction: transaction,
                            balance: snapshot.data ?? 0.0,
                            transactionType: transaction.amount > 0 ? TransactionType.income : TransactionType.expense,
                            onEditPressed: () {
                              print('Edit pressed for transaction with notes: ${transaction.note}');
                            },
                            onDeletePressed: () {
                              print('Delete pressed for transaction with notes: ${transaction.note}');
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
