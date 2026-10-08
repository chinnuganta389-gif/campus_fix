import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/date_formatter.dart';
import '../../models/complaint_model.dart';
import 'app_motion.dart';

/// An animated complaint lifecycle progress indicator:
/// PENDING  ->  ASSIGNED  ->  IN_PROGRESS  ->  RESOLVED
/// Features:
/// - Smooth progress bar fill animation
/// - Ambient pulsing glow on the active stage
/// - Checkmark pop on completed steps
/// - Detailed timestamps for each stage
class AnimatedComplaintTimeline extends StatefulWidget {
  final ComplaintModel complaint;

  const AnimatedComplaintTimeline({
    super.key,
    required this.complaint,
  });

  @override
  State<AnimatedComplaintTimeline> createState() => _AnimatedComplaintTimelineState();
}

class _AnimatedComplaintTimelineState extends State<AnimatedComplaintTimeline>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    final isReduced = AppMotion.isReducedMotion();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    if (!isReduced) {
      _pulseController.repeat(reverse: true);
    }

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.25).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  int _getStatusStepIndex(String status) {
    switch (status.toUpperCase()) {
      case AppConstants.statusPending:
        return 0;
      case AppConstants.statusAssigned:
        return 1;
      case AppConstants.statusInProgress:
        return 2;
      case AppConstants.statusResolved:
        return 3;
      case AppConstants.statusRejected:
      case AppConstants.statusCancelled:
        return -1;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentStep = _getStatusStepIndex(widget.complaint.status);
    final isSpecialStatus = currentStep == -1;

    if (isSpecialStatus) {
      return _buildSpecialStatusCard(isDark);
    }

    final steps = [
      _TimelineStep(
        title: 'Reported',
        subtitle: 'Submitted by student',
        timestamp: widget.complaint.createdAt,
        icon: Icons.edit_note_rounded,
      ),
      _TimelineStep(
        title: 'Assigned',
        subtitle: widget.complaint.assignedWorkerName != null
            ? 'To ${widget.complaint.assignedWorkerName}'
            : 'Technician dispatch',
        timestamp: widget.complaint.assignedAt,
        icon: Icons.person_pin_circle_rounded,
      ),
      _TimelineStep(
        title: 'In Progress',
        subtitle: 'Maintenance ongoing',
        timestamp: widget.complaint.startedAt,
        icon: Icons.engineering_rounded,
      ),
      _TimelineStep(
        title: 'Resolved',
        subtitle: 'Inspection verified',
        timestamp: widget.complaint.resolvedAt,
        icon: Icons.task_alt_rounded,
      ),
    ];

    final progressRatio = currentStep / (steps.length - 1);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'LIFECYCLE TIMELINE',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(widget.complaint.status).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Stage ${currentStep + 1} of 4',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _getStatusColor(widget.complaint.status),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Horizontal Progress Track with nodes
          LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                alignment: Alignment.centerLeft,
                children: [
                  // Inactive background bar
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    height: 4,
                    width: constraints.maxWidth - 32,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  // Animated active progress bar
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0.0, end: progressRatio),
                    duration: AppMotion.durationCinematic,
                    curve: AppMotion.curveCinematic,
                    builder: (context, val, child) {
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        height: 4,
                        width: (constraints.maxWidth - 32) * val,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.primary, AppColors.success],
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      );
                    },
                  ),

                  // Nodes Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(steps.length, (index) {
                      final isCompleted = index < currentStep;
                      final isActive = index == currentStep;

                      return _buildStepNode(
                        index: index,
                        isCompleted: isCompleted,
                        isActive: isActive,
                        isDark: isDark,
                      );
                    }),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 24),
          const Divider(height: 1),
          const SizedBox(height: 18),

          // Detailed vertical steps breakdown
          Column(
            children: List.generate(steps.length, (index) {
              final step = steps[index];
              final isCompleted = index <= currentStep;
              final isActive = index == currentStep;

              return Padding(
                padding: const EdgeInsets.only(bottom: 14.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? (isActive
                                ? AppColors.primary
                                : AppColors.success.withValues(alpha: 0.15))
                            : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isCompleted ? (isActive ? step.icon : Icons.check_rounded) : step.icon,
                        size: 16,
                        color: isCompleted
                            ? (isActive ? Colors.white : AppColors.success)
                            : (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                step.title,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                                  color: isCompleted
                                      ? (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)
                                      : (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                                ),
                              ),
                              if (step.timestamp != null)
                                Text(
                                  DateFormatter.formatDateTime(step.timestamp!),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextMuted,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            step.subtitle,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildStepNode({
    required int index,
    required bool isCompleted,
    required bool isActive,
    required bool isDark,
  }) {
    if (isActive) {
      return AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              // Pulsing glow aura
              Container(
                width: 32 * _pulseAnimation.value,
                height: 32 * _pulseAnimation.value,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(
                    alpha: 0.35 * (1.35 - _pulseAnimation.value),
                  ),
                ),
              ),
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary,
                  border: Border.all(color: Colors.white, width: 2.5),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(Icons.circle, color: Colors.white, size: 8),
                ),
              ),
            ],
          );
        },
      );
    }

    if (isCompleted) {
      return Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.success,
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: const Icon(Icons.check_rounded, color: Colors.white, size: 13),
      );
    }

    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
        border: Border.all(
          color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
          width: 2,
        ),
      ),
    );
  }

  Widget _buildSpecialStatusCard(bool isDark) {
    final isRejected = widget.complaint.status == AppConstants.statusRejected;
    final color = isRejected ? AppColors.error : AppColors.darkTextMuted;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(isRejected ? Icons.cancel_outlined : Icons.remove_circle_outline, color: color, size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isRejected ? 'Complaint Rejected' : 'Complaint Cancelled',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: color),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.complaint.resolutionNote ?? 'No further action required on this request.',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case AppConstants.statusPending:
        return AppColors.warning;
      case AppConstants.statusAssigned:
        return AppColors.secondary;
      case AppConstants.statusInProgress:
        return AppColors.info;
      case AppConstants.statusResolved:
        return AppColors.success;
      default:
        return AppColors.primary;
    }
  }
}

class _TimelineStep {
  final String title;
  final String subtitle;
  final DateTime? timestamp;
  final IconData icon;

  const _TimelineStep({
    required this.title,
    required this.subtitle,
    this.timestamp,
    required this.icon,
  });
}
