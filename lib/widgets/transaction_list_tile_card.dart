import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:payments_tracker_flutter/widgets/utility.dart';
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
            isIncome ?  Icons.arrow_upward_rounded:Icons.arrow_downward_rounded ,
            color: baseColor,
            size: 20,
          ),
        ),

        // Prevent long notes from stealing space
        title: Text(
          (transaction.note ?? '').isNotEmpty ? transaction.note! : 'No description',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Colors.black.withOpacity(0.8)),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          DateFormat.jm().format(transaction.createdAt),
          style: TextStyle(color: Colors.black.withOpacity(0.6), fontSize: 13),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),

        // ⬇️ Key part: constrain trailing width so it can ellipsize/shrink
        trailing: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 120), // tune this
          child: Align(
            alignment: Alignment.centerRight,
            child: Utility.handleNumberAppearanceForOverflow(
              number: transaction.amount,
              color: baseColor,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              textAlign: TextAlign.right, // keep tight to the right
            ),
          ),
        ),

        // Optional tweaks:
        // minLeadingWidth: 36,
        // visualDensity: VisualDensity.compact,
      ),
    );

  }
}
