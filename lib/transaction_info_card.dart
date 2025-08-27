import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For date formatting
// Assuming TransactionType is in add_edit_transaction_screen.dart
// If it's moved to a common file, this import will need to change.
import './add_edit_transaction_screen.dart'; // For TransactionType
import 'transaction_model.dart';
class TransactionInfoCard extends StatelessWidget {
  final TransactionModel transaction;
  final double balance;
  final TransactionType transactionType;
  final VoidCallback onEditPressed;
  final VoidCallback onDeletePressed;

  const TransactionInfoCard({
    super.key,
    required this.transaction,
    required this.balance,
    required this.transactionType,
    required this.onEditPressed,
    required this.onDeletePressed,
  });

  @override
  Widget build(BuildContext context) {

    final Color cardBackgroundColor = transactionType == TransactionType.income
        ? Colors.green.withOpacity(0.6)
        : Colors.red.withOpacity(0.6);
    final String amountPrefix =
        transactionType == TransactionType.income ? '+' : '';

    return Card(
      color: cardBackgroundColor,
      elevation: 4.0,
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
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
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                Text(
                  'Time: ${DateFormat.jm().format(transaction.createdAt)}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (transaction.note.isNotEmpty) ...[
              Text(
                'Notes: ${transaction.note}',
                style: const TextStyle(fontSize: 16,fontWeight: FontWeight.bold),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
            ],
            Text(
              'Amount: $amountPrefix${transaction.amount.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,

              ),
            ),
            Text(
              'Balance: ${balance.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,

              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                TextButton.icon(
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit'),
                  onPressed: onEditPressed,
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  icon: const Icon(Icons.delete),
                  label: const Text('Delete'),
                  onPressed: onDeletePressed,
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
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

// Example Usage (for demonstration, you'd use this in a list view usually):
/*
TransactionInfoCard(
  dateTime: DateTime.now(),
  notes: 'Bought groceries for the week. This is a longer note to see how it wraps and handles overflow.',
  amount: 50.75,
  transactionType: TransactionType.expense,
  onEditPressed: () {
    print('Edit pressed');
    // Navigate to AddEditTransactionScreen with mode: ScreenMode.edit and transaction data
  },
  onDeletePressed: () {
    print('Delete pressed');
    // Show confirmation dialog and then delete
  },
)
*/
