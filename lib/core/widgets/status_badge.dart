import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../motion/app_motion.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  final bool isCompact;

  const StatusBadge({
    super.key,
    required this.status,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppColors.getStatusColor(status);
    final bgColor = AppColors.getStatusBgColor(status);

    IconData icon;
    String label = status.replaceAll('_', ' ');

    switch (status.toUpperCase()) {
      case 'PENDING':
        icon = Icons.schedule_rounded;
        break;
      case 'ASSIGNED':
        icon = Icons.person_search_rounded;
        break;
      case 'IN_PROGRESS':
        icon = Icons.engineering_rounded;
        break;
      case 'RESOLVED':
        icon = Icons.check_circle_rounded;
        break;
      case 'REJECTED':
        icon = Icons.cancel_rounded;
        break;
      case 'CANCELLED':
        icon = Icons.block_rounded;
        break;
      default:
        icon = Icons.info_outline_rounded;
    }

    return AnimatedContainer(
      duration: AppMotion.durationNormal,
      curve: AppMotion.curveMicro,
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 8 : 10,
        vertical: isCompact ? 4 : 5,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedSwitcher(
            duration: AppMotion.durationNormal,
            transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
            child: Icon(
              icon,
              key: ValueKey(status),
              size: isCompact ? 12 : 14,
              color: color,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: isCompact ? 11 : 12,
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
