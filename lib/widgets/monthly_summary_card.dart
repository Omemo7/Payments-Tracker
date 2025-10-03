import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../global_variables/app_colors.dart';
import 'basic/basic_card.dart';

class MonthlySummaryCard extends StatelessWidget {
  final DateTime currentMonth;
  final double income;
  final double expense;
  final double overallBalanceEndOfMonth;

  const MonthlySummaryCard({
    super.key,
    required this.currentMonth,
    required this.income,
    required this.expense,
    required this.overallBalanceEndOfMonth,
  });

  String get _formattedMonth => DateFormat.yMMMM().format(currentMonth);
  double get _net => income - expense;

  @override
  Widget build(BuildContext context) {
    return BasicCard(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Summary: $_formattedMonth',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.purple,
                  ),
                ),
                const Icon(Icons.assessment, color: AppColors.purple, size: 28),
              ],
            ),

            const SizedBox(height: 16),
            Divider(color: AppColors.subtlePurple.withOpacity(0.2), thickness: 1),
            const SizedBox(height: 16),

            // Income
            _buildSummaryRow(
              label: 'Income',
              value: income,
              icon: Icons.arrow_upward,
              color: AppColors.incomeGreen,
            ),
            const SizedBox(height: 10),

            // Expense
            _buildSummaryRow(
              label: 'Expense',
              value: expense,
              icon: Icons.arrow_downward,
              color: AppColors.expenseRed,
            ),
            const SizedBox(height: 10),

            // Net
            _buildSummaryRow(
              label: 'Net',
              value: _net,
              icon: _net >= 0 ? Icons.trending_up : Icons.trending_down,
              color: _net >= 0 ? AppColors.incomeGreen : AppColors.expenseRed,
              isBold: true,
            ),

            const SizedBox(height: 16),
            Divider(color: AppColors.subtlePurple.withOpacity(0.2), thickness: 1),
            const SizedBox(height: 16),

            // Overall Balance
            Row(
              children: [
                const Icon(Icons.account_balance_wallet, color: AppColors.purple, size: 22),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Overall Balance (End of Month):',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.purple,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 32.0),
              child: Text(
                overallBalanceEndOfMonth.toStringAsFixed(2),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: overallBalanceEndOfMonth >= 0
                      ? AppColors.incomeGreen
                      : AppColors.expenseRed,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow({
    required String label,
    required double value,
    required IconData icon,
    required Color color,
    bool isBold = false,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
              color: AppColors.purple,
            ),
          ),
        ),
        Text(
          value.toStringAsFixed(2),
          style: TextStyle(
            fontSize: 16,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}
