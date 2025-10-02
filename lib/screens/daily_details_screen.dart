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
      netColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.blueGrey.shade700;
    }

    return Card(
      elevation: 4, // Increased elevation
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0), // Adjusted margin
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), // Rounded corners
      child: Padding(
        padding: const EdgeInsets.all(20.0), // Increased padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Summary for ${DateFormat('MMMM d').format(widget.selectedDate)}', // More descriptive title
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround, // Distribute space
              children: [
                _buildStatChip('Income', incomeTotal.toStringAsFixed(2), Colors.green.shade100, Colors.green.shade800),
                _buildStatChip('Expense', expenseTotal.abs().toStringAsFixed(2), Colors.red.shade100, Colors.red.shade800),
              ],
            ),
            const Divider(height: 30, thickness: 0.5), // Adjusted divider
            _buildBalanceRow(
              label: 'Net Daily Flow',
              amount: net.toStringAsFixed(2),
              color: netColor,
              isBold: true,
              fontSize: 16,
            ),
            const SizedBox(height: 10),
            _buildBalanceRow(
              label: 'End of Day Balance',
              amount: cumulativeBalance != null ? cumulativeBalance.toStringAsFixed(2) : 'N/A',
              color: cumulativeBalance != null
                  ? (Theme.of(context).textTheme.bodyLarge?.color ?? Colors.blueGrey.shade700)
                  : Colors.blueGrey.shade400,
              isBold: true,
              fontSize: 16,
            ),
          ],
        ),
      ),
    );
  }

  // Helper widget for Income/Expense chips
  Widget _buildStatChip(String label, String value, Color backgroundColor, Color textColor) {
    return Column(
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.blueGrey.shade600)),
        const SizedBox(height: 4),
        Chip(
          backgroundColor: backgroundColor,
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
          label: Text(
            value,
            style: TextStyle(fontWeight: FontWeight.bold, color: textColor, fontSize: 16),
          ),
        ),
      ],
    );
  }

  // Helper widget for balance rows
  Widget _buildBalanceRow({required String label, required String amount, required Color color, bool isBold = false, double? fontSize}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            fontSize: fontSize ?? Theme.of(context).textTheme.bodyMedium?.fontSize,
            color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.8)
          ),
        ),
        Text(
          amount,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: color,
            fontSize: fontSize ?? Theme.of(context).textTheme.bodyMedium?.fontSize,
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionList(List<TransactionModel> transactions) {
    if (transactions.isEmpty) {
      return Center(
        child: Padding( // Added padding for better spacing
          padding: const EdgeInsets.all(24.0),
          child: Column( // Added Column for icon and text
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.receipt_long_outlined, size: 60, color: Colors.blueGrey.shade300),
              const SizedBox(height: 16),
              Text(
                'No transactions recorded for this day.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.blueGrey.shade600),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8.0), // Add padding to the list
      itemCount: transactions.length,
      separatorBuilder: (_, __) => const Divider(height: 1, indent: 16, endIndent: 16), // Subtle separator
      itemBuilder: (context, index) {
        final transaction = transactions[index];
        final bool isIncome = transaction.amount >= 0;
        final Color baseColor = isIncome ? Colors.green.shade700 : Colors.red.shade700;
        final Color lightBackgroundColor = isIncome ? Colors.green.shade50 : Colors.red.shade50;
        final String amountPrefix = isIncome ? '+' : '';

        return Card( // Wrap ListTile in a Card for better definition
          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: lightBackgroundColor,
              child: Icon(
                isIncome ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded, // Rounded icons
                color: baseColor,
                size: 20, // Slightly smaller icon
              ),
            ),
            title: Text(
              transaction.note != null && transaction.note!.isNotEmpty
                  ? transaction.note!
                  : 'No description',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            ),
            subtitle: Text(
              DateFormat.jm().format(transaction.createdAt),
              style: TextStyle(color: Colors.blueGrey.shade500, fontSize: 13),
            ),
            trailing: Text(
              '$amountPrefix${transaction.amount.toStringAsFixed(2)}',
              style: TextStyle(
                color: baseColor,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
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
      backgroundColor: Colors.blueGrey.shade50, // Added a subtle background color
      appBar: AppBar(
        title: Text(formattedDate),
        centerTitle: true,
        elevation: 1, // Subtle elevation for AppBar
        backgroundColor: Colors.white, // AppBar background
        foregroundColor: Colors.blueGrey.shade800, // AppBar text/icon color
      ),
      body: FutureBuilder<List<TransactionModel>>(
        future: _transactionsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Error loading transactions: ${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.red.shade700, fontSize: 16),
                ),
              ),
            );
          }

          final transactions = snapshot.data ?? [];

          return Column(
            children: [
              _buildSummaryCard(transactions),
              Padding( // Title for the transaction list
                padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 16.0, bottom: 8.0),
                child: Row(
                  children: [
                    Icon(Icons.list_alt_rounded, color: Colors.blueGrey.shade700),
                    const SizedBox(width: 8),
                    Text(
                      'Transactions',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.blueGrey.shade700
                      ),
                    ),
                  ],
                ),
              ),
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
