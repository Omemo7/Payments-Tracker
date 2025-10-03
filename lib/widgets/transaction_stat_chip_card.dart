import 'package:flutter/material.dart';
import '../global_variables/app_colors.dart';
import 'basic/basic_card.dart';


class TransactionStatChipCard extends StatelessWidget {
  final String label;
  final String value;
  final Color backgroundColor;
  final Color textColor;

  const TransactionStatChipCard({
    super.key,
    required this.label,
    required this.value,
    required this.backgroundColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return BasicCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppColors.subtlePurple,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Chip(
              backgroundColor: backgroundColor,
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
              label: Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: textColor,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
