import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';

class PriorityBadge extends StatelessWidget {
  final String priority;

  const PriorityBadge({
    super.key,
    required this.priority,
  });

  @override
  Widget build(BuildContext context) {
    Color color;
    Color bgColor;
    IconData icon;

    switch (priority.toUpperCase()) {
      case 'URGENT':
        color = AppColors.priorityUrgent;
        bgColor = AppColors.errorContainer;
        icon = Icons.error_rounded;
        break;
      case 'HIGH':
        color = AppColors.priorityHigh;
        bgColor = AppColors.warningContainer;
        icon = Icons.arrow_upward_rounded;
        break;
      case 'MEDIUM':
        color = AppColors.priorityMedium;
        bgColor = AppColors.primaryContainer;
        icon = Icons.remove_rounded;
        break;
      case 'LOW':
      default:
        color = AppColors.priorityLow;
        bgColor = AppColors.successContainer;
        icon = Icons.arrow_downward_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            priority.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
