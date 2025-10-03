import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../screens/add_edit_transaction_screen.dart'; // TransactionType
import '../models/transaction_model.dart';
import '../global_variables/app_colors.dart';
import 'basic/basic_card.dart';

class TransactionInfoCard extends StatelessWidget {
  final TransactionModel transaction;
  final double balance;

  final VoidCallback onEditPressed;
  final VoidCallback onDeletePressed;
  final DateTime todayDate;

  const TransactionInfoCard({
    super.key,
    required this.transaction,
    required this.balance,

    required this.onEditPressed,
    required this.onDeletePressed,
    required this.todayDate,
  });

  @override
  Widget build(BuildContext context) {
    final bool isIncome = transaction.amount >= 0;
    final Color amountColor =
    isIncome ? AppColors.incomeGreen : AppColors.expenseRed;
    final String amountPrefix = isIncome ? '+' : '';

    final String dateStr = DateFormat.yMMMd().format(transaction.createdAt);
    final String timeStr = DateFormat.jm().format(transaction.createdAt);

    return BasicCard(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _InfoChip(icon: Icons.event, label: dateStr),
                    _InfoChip(icon: Icons.schedule, label: timeStr),
                  ],
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.only(top: 5.0, right: 5),
                  child: Text(
                    isIncome ? 'Income' : 'Expense',
                    style: TextStyle(
                      fontSize: 12,
                      color: isIncome
                          ? AppColors.incomeGreen
                          : AppColors.expenseRed,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // BALANCE pill
            _BalancePill(balance: balance),

            // NOTES (if any)
            if (transaction.note != null &&
                transaction.note!.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              _NotesBox(note: transaction.note!.trim()),
            ],

            const SizedBox(height: 10),
            const Divider(height: 1),

            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(

                children: [
                  // Amount text
                  Text(
                    'Amount: $amountPrefix${transaction.amount.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: amountColor,
                    ),
                  ),

                  const Spacer(),
                  // Action buttons
                  Expanded(child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, size: 22),
                        color: AppColors.purple,
                        tooltip: 'Edit',
                        onPressed: onEditPressed,
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, size: 22),
                        color: AppColors.expenseRed,
                        tooltip: 'Delete',
                        onPressed: onDeletePressed,
                      ),
                    ],
                  )),
                ],
              ),
            )

          ],
        ),
      ),
    );
  }
}


/// purple chip for date/time
class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.purple.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.purple.withOpacity(0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.purple),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.purple,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// balance pill
class _BalancePill extends StatelessWidget {
  final double balance;
  const _BalancePill({required this.balance});

  @override
  Widget build(BuildContext context) {
    final bool positive = balance >= 0;
    final Color textColor = positive ? AppColors.greyishGreen : AppColors.greyishRed;
    final Color bg = positive
        ? AppColors.greyishGreen.withOpacity(0.10)
        : AppColors.greyishRed.withOpacity(0.10);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            positive ? Icons.trending_up : Icons.trending_down,
            color: textColor,
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(
            'Balance: ${balance.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}

/// notes box
class _NotesBox extends StatelessWidget {
  final String note;
  const _NotesBox({required this.note});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: AppColors.purple.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.purple.withOpacity(0.12)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.notes, color: AppColors.purple, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              note,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14.5,
                color: AppColors.purple,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
