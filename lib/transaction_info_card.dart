import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For date formatting
// Assuming TransactionType is in add_edit_transaction_screen.dart
// If it's moved to a common file, this import will need to change.
import './add_edit_transaction_screen.dart'; // For TransactionType

class TransactionInfoCard extends StatelessWidget {
  final DateTime dateTime;
  final String notes;
  final double amount;
  final double balance;
  final TransactionType transactionType;
  final VoidCallback onEditPressed;
  final VoidCallback onDeletePressed;

  const TransactionInfoCard({
    super.key,
    required this.dateTime,
    required this.notes,
    required this.amount,
    required this.balance,
    required this.transactionType,
    required this.onEditPressed,
    required this.onDeletePressed,
  });

  @override
  Widget build(BuildContext context) {
    final Color amountColor =
        transactionType == TransactionType.income ? Colors.green : Colors.red;
    final String amountPrefix =
        transactionType == TransactionType.income ? '+' : '-';

    return Card(
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
                  'Date: ${DateFormat.yMd().format(dateTime)}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                Text(
                  'Time: ${DateFormat.jm().format(dateTime)}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (notes.isNotEmpty) ...[
              Text(
                'Notes: $notes',
                style: const TextStyle(fontSize: 16),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
            ],
            Text(
              'Amount: $amountPrefix${amount.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: amountColor,
              ),
            ),
            Text(
              'Balance: ${balance.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: amountColor,
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
