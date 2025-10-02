import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:payments_tracker_flutter/database/tables/transaction_table.dart';
import 'package:payments_tracker_flutter/models/transaction_model.dart';

class DailyDetailsScreen extends StatefulWidget {
  final DateTime selectedDate;
  final int? accountId;
  final double? dailyNet;
  final double? cumulativeBalance;

  const DailyDetailsScreen({
    super.key,
    required this.selectedDate,
    required this.accountId,
    this.dailyNet,
    this.cumulativeBalance,
  });

  @override
  State<DailyDetailsScreen> createState() => _DailyDetailsScreenState();
}

class _DailyDetailsScreenState extends State<DailyDetailsScreen> {
  late Future<List<TransactionModel>> _transactionsFuture;

  @override
  void initState() {
    super.initState();
    _transactionsFuture = TransactionTable.getTransactionsForDateAndAccount(
      widget.selectedDate,
      widget.accountId,
    );
  }

  Widget _buildSummaryCard(List<TransactionModel> transactions) {
    final double computedNet = transactions.fold(0.0, (sum, txn) => sum + txn.amount);
    final double incomeTotal = transactions
        .where((txn) => txn.amount > 0)
        .fold(0.0, (sum, txn) => sum + txn.amount);
    final double expenseTotal = transactions
        .where((txn) => txn.amount < 0)
        .fold(0.0, (sum, txn) => sum + txn.amount);

    final double net = widget.dailyNet ?? computedNet;
    final double? cumulativeBalance = widget.cumulativeBalance;

    Color netColor;
    if (net > 0) {
      netColor = Colors.green.shade700;
    } else if (net < 0) {
      netColor = Colors.red.shade700;
    } else {
      netColor = Colors.blueGrey.shade700;
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Summary',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Income'),
                Text(
                  incomeTotal.toStringAsFixed(2),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Expense'),
                Text(
                  expenseTotal.toStringAsFixed(2),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Net',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  net.toStringAsFixed(2),
                  style: TextStyle(fontWeight: FontWeight.bold, color: netColor),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'End of Day Balance',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  cumulativeBalance != null ? cumulativeBalance.toStringAsFixed(2) : '—',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: cumulativeBalance != null
                        ? Colors.blueGrey.shade700
                        : Colors.blueGrey.shade400,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionList(List<TransactionModel> transactions) {
    if (transactions.isEmpty) {
      return Center(
        child: Text(
          'No transactions recorded for this day.',
          style: TextStyle(color: Colors.blueGrey.shade600),
        ),
      );
    }

    return ListView.separated(
      itemCount: transactions.length,
      separatorBuilder: (_, __) => const Divider(height: 0),
      itemBuilder: (context, index) {
        final transaction = transactions[index];
        final bool isIncome = transaction.amount >= 0;
        final Color amountColor = isIncome ? Colors.green.shade700 : Colors.red.shade700;
        final String amountPrefix = isIncome ? '+' : '';

        return ListTile(
          leading: CircleAvatar(
            backgroundColor: isIncome ? Colors.green.shade100 : Colors.red.shade100,
            child: Icon(
              isIncome ? Icons.arrow_downward : Icons.arrow_upward,
              color: amountColor,
            ),
          ),
          title: Text(
            transaction.note != null && transaction.note!.isNotEmpty
                ? transaction.note!
                : 'No description',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(DateFormat.jm().format(transaction.createdAt)),
          trailing: Text(
            '$amountPrefix${transaction.amount.toStringAsFixed(2)}',
            style: TextStyle(
              color: amountColor,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final String formattedDate = DateFormat('EEEE, MMMM d, yyyy').format(widget.selectedDate);

    return Scaffold(
      appBar: AppBar(
        title: Text(formattedDate),
        centerTitle: true,
      ),
      body: FutureBuilder<List<TransactionModel>>(
        future: _transactionsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error loading transactions: ${snapshot.error}'));
          }

          final transactions = snapshot.data ?? [];

          return Column(
            children: [
              _buildSummaryCard(transactions),
              Expanded(
                child: _buildTransactionList(transactions),
              ),
            ],
          );
        },
      ),
    );
  }
}
