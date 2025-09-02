import 'package:flutter/material.dart';
import 'package:payments_tracker_flutter/models/account_model.dart'; // Assuming AccountModel has 'name' and 'balance'

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
    return Card(
      elevation: 4.0, // Add some shadow
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)), // Rounded corners
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.0), // Match card's border radius
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Icon for the account
              CircleAvatar(
                backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                child: Icon(
                  Icons.person, // Example icon
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(width: 16),
              // Account name and balance
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      account.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      // Format the balance as currency, e.g., using 'intl' package
                      'Balance: ${balance.toStringAsFixed(2)}', // Using account.balance
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
              // Edit button
              IconButton(
                icon: Icon(Icons.edit, color: Colors.blue[600]),
                onPressed: onEditPressed,
                tooltip: 'Edit Account',
              ),
              // Delete button
              IconButton(
                icon: Icon(Icons.delete, color: Colors.red[600]),
                onPressed: onDeletePressed,
                tooltip: 'Delete Account',
              ),
              // Trailing arrow or chevron (optional if edit/delete are primary actions)
              // Icon(
              //   Icons.arrow_forward_ios,
              //   color: Colors.grey[400],
              //   size: 16,
              // ),
            ],
          ),
        ),
      ),
    );
  }
}
