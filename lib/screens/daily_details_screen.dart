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

  final Color _pageBackgroundColor = Colors.white;
  final Color _primaryTextColor = Colors.deepPurple.shade700;
  final Color _secondaryTextColor = Colors.deepPurple.shade300;
  final Color _chipBackgroundColor = Colors.deepPurple.shade50;
  final Color _chipTextColor = Colors.deepPurple.shade600;
  final LinearGradient _summaryGradient = LinearGradient(
    colors: [
      Colors.deepPurple.shade50,
      Colors.white,
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

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
      netColor = _primaryTextColor;
    }

    return Card(
      elevation: 6,
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(gradient: _summaryGradient),
        padding: const EdgeInsets.all(22.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Summary for ${DateFormat('MMMM d').format(widget.selectedDate)}',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: _primaryTextColor,
                  ),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatChip('Income', incomeTotal.toStringAsFixed(2), Colors.green.shade100, Colors.green.shade800),
                _buildStatChip('Expense', expenseTotal.abs().toStringAsFixed(2), Colors.red.shade100, Colors.red.shade800),
              ],
            ),
            const SizedBox(height: 18),
            const Divider(height: 1, thickness: 0.4),
            const SizedBox(height: 18),
            _buildBalanceRow(
              label: 'Net Daily Flow',
              amount: net.toStringAsFixed(2),
              color: netColor,
              isBold: true,
              fontSize: 16,
            ),
            const SizedBox(height: 12),
            _buildBalanceRow(
              label: 'End of Day Balance',
              amount: cumulativeBalance != null ? cumulativeBalance.toStringAsFixed(2) : 'N/A',
              color: cumulativeBalance != null ? _primaryTextColor : _secondaryTextColor,
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
        Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: _primaryTextColor.withOpacity(0.75),
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 4),
        Chip(
          backgroundColor: label == 'Income' || label == 'Expense' ? backgroundColor : _chipBackgroundColor,
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
          label: Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: label == 'Income' || label == 'Expense' ? textColor : _chipTextColor,
              fontSize: 16,
            ),
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
            color: _primaryTextColor.withOpacity(isBold ? 0.95 : 0.8),
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
              Icon(Icons.receipt_long_outlined, size: 60, color: _secondaryTextColor),
              const SizedBox(height: 16),
              Text(
                'No transactions recorded for this day.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: _primaryTextColor.withOpacity(0.7)),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8.0), // Add padding to the list
      itemCount: transactions.length,
      separatorBuilder: (_, __) => Divider(
        height: 1,
        indent: 16,
        endIndent: 16,
        color: _secondaryTextColor.withOpacity(0.2),
      ), // Subtle separator
      itemBuilder: (context, index) {
        final transaction = transactions[index];
        final bool isIncome = transaction.amount >= 0;
        final Color baseColor = isIncome ? Colors.green.shade700 : Colors.red.shade700;
        final Color lightBackgroundColor = isIncome
            ? Colors.green.shade50.withOpacity(0.6)
            : Colors.red.shade50.withOpacity(0.6);
        final String amountPrefix = isIncome ? '+' : '';

        return Card( // Wrap ListTile in a Card for better definition
          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: _primaryTextColor,
              ),
            ),
            subtitle: Text(
              DateFormat.jm().format(transaction.createdAt),
              style: TextStyle(color: _primaryTextColor.withOpacity(0.6), fontSize: 13),
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
      backgroundColor: _pageBackgroundColor,
      appBar: AppBar(
        title: Text(
          formattedDate,
          style: TextStyle(
            color: _primaryTextColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        elevation: 1, // Subtle elevation for AppBar
        backgroundColor: Colors.white, // AppBar background
        foregroundColor: _primaryTextColor, // AppBar text/icon color
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
                  style: TextStyle(color: Colors.red.shade700, fontSize: 16, fontWeight: FontWeight.w600),
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
                    Icon(Icons.list_alt_rounded, color: _primaryTextColor),
                    const SizedBox(width: 8),
                    Text(
                      'Transactions',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: _primaryTextColor,
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
