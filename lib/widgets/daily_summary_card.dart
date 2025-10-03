import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:payments_tracker_flutter/widgets/basic/basic_card.dart';
import '../global_variables/app_colors.dart';
import '../global_variables/chosen_account.dart';
import '../screens/daily_details_screen.dart';

class DailySummaryCard extends StatelessWidget {
  final DateTime specificDate;
  final double dailyNet;
  final double cumulativeBalance;

  DailySummaryCard({
    super.key,
    required this.specificDate,
    required this.dailyNet,
    required this.cumulativeBalance,
  });

  late final int dayNumber = specificDate.day;

  @override
  Widget build(BuildContext context) {
    return BasicCard(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DailyDetailsScreen(
              selectedDate: specificDate,
              accountId: ChosenAccount().account?.id,
              dailyNet: dailyNet,
              cumulativeBalance: cumulativeBalance,
            ),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: date badge + title + chevron
            Row(
              children: [
                // Date badge
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.purple.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.purple.withOpacity(0.18),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$dayNumber',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.purple,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Title: Day X - Weekday
                Expanded(
                  child: Text(
                    'Day $dayNumber - ${DateFormat.EEEE().format(specificDate)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.purple,
                      fontSize: 16,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: AppColors.purple.withOpacity(0.4),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Stat pills: Net + Balance
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                // Net pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: (dailyNet >= 0
                        ? AppColors.greyishGreen
                        : AppColors.greyishRed)
                        .withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        dailyNet >= 0 ? Icons.trending_up : Icons.trending_down,
                        size: 18,
                        color: dailyNet >= 0
                            ? AppColors.greyishGreen
                            : AppColors.greyishRed,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Net: ${dailyNet.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          color: dailyNet >= 0
                              ? AppColors.greyishGreen
                              : AppColors.greyishRed,
                        ),
                      ),
                    ],
                  ),
                ),

                // Balance pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: (cumulativeBalance >= 0
                        ? AppColors.greyishGreen
                        : AppColors.greyishRed)
                        .withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        cumulativeBalance >= 0
                            ? Icons.account_balance_wallet
                            : Icons.account_balance_wallet_outlined,
                        size: 18,
                        color: cumulativeBalance >= 0
                            ? AppColors.greyishGreen
                            : AppColors.greyishRed,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Balance: ${cumulativeBalance.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          color: cumulativeBalance >= 0
                              ? AppColors.greyishGreen
                              : AppColors.greyishRed,
                        ),
                      ),
                    ],
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
