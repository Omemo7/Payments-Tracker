import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../global_variables/app_colors.dart';
import '../models/transaction_model.dart';
import 'basic/basic_card.dart';


class TransactionListTileCard extends StatelessWidget {
  final TransactionModel transaction;

  const TransactionListTileCard({
    super.key,
    required this.transaction,
  });

  @override
  Widget build(BuildContext context) {
    final bool isIncome = transaction.amount >= 0;
    final Color baseColor = isIncome ? AppColors.incomeGreen : AppColors.expenseRed;
    final Color lightBackgroundColor = baseColor.withOpacity(0.12);
    final String amountPrefix = isIncome ? '+' : '';

    return BasicCard(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
        leading: CircleAvatar(
          backgroundColor: lightBackgroundColor,
          child: Icon(
            isIncome ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
            color: baseColor,
            size: 20,
          ),
        ),
        title: Text(
          transaction.note != null && transaction.note!.isNotEmpty
              ? transaction.note!
              : 'No description',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: Colors.black.withOpacity(0.8),
          ),
        ),
        subtitle: Text(
          DateFormat.jm().format(transaction.createdAt),
          style: TextStyle(
            color: Colors.black.withOpacity(0.6),
            fontSize: 13,
          ),
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
  }
}
