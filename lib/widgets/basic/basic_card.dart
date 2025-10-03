import 'package:flutter/material.dart';
import '../../global_variables/app_colors.dart';

class BasicCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry margin;
  final double borderRadius;
  final VoidCallback? onTap;

  const BasicCard({
    super.key,
    required this.child,
    this.margin = const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
    this.borderRadius = 16,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      color: Colors.white,
      margin: margin,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        side: BorderSide(
          color: AppColors.purple.withOpacity(.4),
          width: 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(borderRadius),
        onTap: onTap,
        child: child,
      ),
    );
  }
}
