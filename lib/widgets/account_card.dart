import 'package:flutter/material.dart';
import 'package:payments_tracker_flutter/models/account_model.dart'; // Assuming AccountModel has 'name' and 'balance'
import 'package:payments_tracker_flutter/global_variables/app_colors.dart';

class AccountCard extends StatelessWidget {
  final AccountModel account;
  final double balance;
  final VoidCallback onTap;
  final VoidCallback onEditPressed; // New callback for edit
  final VoidCallback onDeletePressed; // New callback for delete

  const AccountCard({
    Key? key,
    required this.balance,
    required this.account,
    required this.onTap,
    required this.onEditPressed, // Make it required
    required this.onDeletePressed, // Make it required
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isPositive = balance >= 0;

    return Card(
      color: Colors.white,
      elevation:5,
      shadowColor: AppColors.subtlePurple.withOpacity(0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24.0),
        side: BorderSide(color: AppColors.subtlePurple.withOpacity(0.1), width: 1),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24.0), // Match card's border radius
        child: SizedBox(
          height: 100, // Increased height for the card
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // Icon for the account
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.subtlePurple.withOpacity(0.12),
                  child: Icon(
                    Icons.person, // Example icon
                    color: AppColors.purple,
                  ),
                ),
                const SizedBox(width: 16),
                // Account name and balance
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center, // Center content vertically
                    children: [
                      Text(
                        account.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.purple,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        // Format the balance as currency, e.g., using 'intl' package
                        'Balance: ${balance.toStringAsFixed(2)}', // Using account.balance
                        style: TextStyle(
                          fontSize: 11,
                          color: isPositive
                              ? AppColors.greyishGreen
                              : AppColors.greyishRed,
                        ),
                      ),
                    ],
                  ),
                ),
                // Edit button
                IconButton(
                  icon: const Icon(Icons.edit, color: AppColors.purple),
                  onPressed: onEditPressed,
                  tooltip: 'Edit Account',
                ),
                // Delete button
                IconButton(
                  icon: const Icon(Icons.delete, color: AppColors.expenseRed),
                  onPressed: onDeletePressed,
                  tooltip: 'Delete Account',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
