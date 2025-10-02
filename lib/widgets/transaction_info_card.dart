import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For date formatting
// Assuming TransactionType is in add_edit_transaction_screen.dart
// If it's moved to a common file, this import will need to change.
import '../screens/add_edit_transaction_screen.dart'; // For TransactionType
import '../models/transaction_model.dart';
import '../global_variables/app_colors.dart';

class TransactionInfoCard extends StatelessWidget {
  final TransactionModel transaction;
  final double balance;
  final TransactionType transactionType;
  final VoidCallback onEditPressed; // Will be wrapped
  final VoidCallback onDeletePressed; // Will be wrapped
  final DateTime todayDate; // New required parameter

  const TransactionInfoCard({
    super.key,
    required this.transaction,
    required this.balance,
    required this.transactionType,
    required VoidCallback onEditPressed, // Original callbacks
    required VoidCallback onDeletePressed,
    required this.todayDate,
  })  :
        // Wrap the original callbacks with the date check
        this.onEditPressed = onEditPressed,
        this.onDeletePressed = onDeletePressed;

  DateTime _normalizeDate(DateTime dateTime) {
    return DateTime(dateTime.year, dateTime.month, dateTime.day);
  }

  @override
  Widget build(BuildContext context) {
    final bool isIncome = transactionType == TransactionType.income;
    final Color amountColor =
        isIncome ? AppColors.incomeGreen : AppColors.expenseRed;
    final String amountPrefix = isIncome ? '+' : '';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Date: ${DateFormat.yMd().format(transaction.createdAt)}',
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.purple,
                  ),
                ),
                Text(
                  'Time: ${DateFormat.jm().format(transaction.createdAt)}',
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.purple,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Amount: $amountPrefix${transaction.amount.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 20, // Updated size
                fontWeight: FontWeight.bold,
                color: amountColor,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Balance: ${balance.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 15, // Updated size
                fontWeight: FontWeight.bold,
                color:
                    balance >= 0 ? AppColors.incomeGreen : AppColors.expenseRed,
              ),
            ),

            const SizedBox(height: 12),
            if (transaction.note != null && transaction.note!.isNotEmpty) ...[
              Text(
                'Notes: ${transaction.note}',
                style: const TextStyle(
                  fontSize: 20,
                  color: AppColors.purple,
                ), // Updated style
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                TextButton.icon(
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit'),
                  onPressed: onEditPressed,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.purple,
                  ),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  icon: const Icon(Icons.delete),
                  label: const Text('Delete'),
                  onPressed: onDeletePressed,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.expenseRed,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
