import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/motion/animated_complaint_timeline.dart';
import '../../../core/motion/interactive_card.dart';
import '../../../core/motion/motion_reveal.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/loading_view.dart';
import '../../../core/widgets/priority_badge.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../models/complaint_history_model.dart';
import '../../../models/complaint_model.dart';
import '../../../services/providers.dart';

class ComplaintDetailScreen extends ConsumerWidget {
  final ComplaintModel complaint;

  const ComplaintDetailScreen({
    super.key,
    required this.complaint,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final firestore = ref.watch(firestoreServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(complaint.complaintId),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: StatusBadge(status: complaint.status),
          ),
        ],
      ),
      body: StreamBuilder<ComplaintModel?>(
        stream: firestore.complaintStream(complaint.complaintId),
        initialData: complaint,
        builder: (context, snapshot) {
          final liveComplaint = snapshot.data ?? complaint;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header card with Category, Priority and Title
                    MotionReveal.staggered(
                      index: 0,
                      child: _buildHeaderCard(context, liveComplaint, isDark),
                    ),
                    const SizedBox(height: 20),

                    // Animated Lifecycle Timeline
                    MotionReveal.staggered(
                      index: 1,
                      child: AnimatedComplaintTimeline(complaint: liveComplaint),
                    ),
                    const SizedBox(height: 20),

                    // Problem Evidence Image (if attached)
                    if (liveComplaint.imageUrl != null && liveComplaint.imageUrl!.isNotEmpty) ...[
                      MotionReveal.staggered(
                        index: 2,
                        child: _buildImagePreview(context, 'Evidence Photo', liveComplaint.imageUrl!, isDark),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Assigned Worker Card
                    MotionReveal.staggered(
                      index: 3,
                      child: _buildWorkerInfoCard(liveComplaint, isDark),
                    ),
                    const SizedBox(height: 20),

                    // Resolution Info (if resolved)
                    if (liveComplaint.status == AppConstants.statusResolved) ...[
                      MotionReveal.staggered(
                        index: 4,
                        child: _buildResolutionCard(context, liveComplaint, isDark),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Timeline & History
                    MotionReveal.staggered(
                      index: 5,
                      child: _buildTimelineSection(ref, liveComplaint.complaintId, isDark),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeaderCard(BuildContext context, ComplaintModel item, bool isDark) {
    return InteractiveCard(
      borderRadius: BorderRadius.circular(20),
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  item.category,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
              PriorityBadge(priority: item.priority),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            item.title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 16, color: AppColors.lightTextSecondary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  item.location,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined, size: 15, color: AppColors.lightTextSecondary),
              const SizedBox(width: 6),
              Text(
                'Reported: ${DateFormatter.formatDateTime(item.createdAt)}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.lightTextMuted,
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          Text(
            'Description',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            item.description,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkerInfoCard(ComplaintModel item, bool isDark) {
    return InteractiveCard(
      borderRadius: BorderRadius.circular(16),
      padding: const EdgeInsets.all(18.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: item.assignedWorkerId != null
                  ? AppColors.primaryContainer
                  : (isDark ? AppColors.darkBorder : const Color(0xFFF1F5F9)),
              shape: BoxShape.circle,
            ),
            child: Icon(
              item.assignedWorkerId != null ? Icons.engineering_rounded : Icons.person_search_rounded,
              color: item.assignedWorkerId != null ? AppColors.primary : AppColors.lightTextMuted,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Assigned Technician',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.assignedWorkerName ?? 'Awaiting technician assignment',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: item.assignedWorkerId != null
                        ? (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)
                        : AppColors.lightTextMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResolutionCard(BuildContext context, ComplaintModel item, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(18.0),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF064E3B).withValues(alpha: 0.3) : AppColors.successContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.success.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.verified_rounded, color: AppColors.successDark, size: 20),
              SizedBox(width: 8),
              Text(
                'Resolution Details',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.successDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (item.resolvedAt != null)
            Text(
              'Resolved on ${DateFormatter.formatDateTime(item.resolvedAt)}',
              style: const TextStyle(fontSize: 12, color: AppColors.successDark),
            ),
          if (item.resolutionNote != null && item.resolutionNote!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Note: ${item.resolutionNote}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white : AppColors.lightTextPrimary,
              ),
            ),
          ],
          if (item.resolutionImageUrl != null && item.resolutionImageUrl!.isNotEmpty) ...[
            const SizedBox(height: 14),
            _buildImagePreview(context, 'Completion Evidence', item.resolutionImageUrl!, isDark),
          ],
        ],
      ),
    );
  }

  Widget _buildImagePreview(BuildContext context, String title, String imageUrl, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          ),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Container(
            height: 220,
            width: double.infinity,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : const Color(0xFFF1F5F9),
            ),
            child: imageUrl.startsWith('data:image')
                ? Image.memory(
                    base64Decode(imageUrl.split(',')[1]),
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const Center(
                      child: Icon(Icons.broken_image_rounded, size: 40, color: AppColors.lightTextMuted),
                    ),
                  )
                : Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const Center(
                      child: Icon(Icons.broken_image_rounded, size: 40, color: AppColors.lightTextMuted),
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineSection(WidgetRef ref, String complaintId, bool isDark) {
    final firestore = ref.watch(firestoreServiceProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Activity History Log',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          ),
        ),
        const SizedBox(height: 14),
        StreamBuilder<List<ComplaintHistoryModel>>(
          stream: firestore.getComplaintHistory(complaintId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const LoadingView(size: 24);
            }
            final list = snapshot.data ?? [];
            if (list.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text('No timeline updates yet.', style: TextStyle(fontSize: 13, color: AppColors.lightTextMuted)),
              );
            }

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              child: Column(
                children: List.generate(list.length, (index) {
                  final item = list[index];
                  final isLast = index == list.length - 1;

                  return IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          children: [
                            Container(
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(
                                color: isLast ? AppColors.primary : AppColors.success,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                            ),
                            if (!isLast)
                              Expanded(
                                child: Container(
                                  width: 2,
                                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 20.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      item.action.replaceAll('_', ' '),
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                      ),
                                    ),
                                    Text(
                                      DateFormatter.formatRelative(item.createdAt),
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.lightTextMuted,
                                      ),
                                    ),
                                  ],
                                ),
                                if (item.note != null && item.note!.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    item.note!,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 2),
                                Text(
                                  'By: ${item.changedByName}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.lightTextMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            );
          },
        ),
      ],
    );
  }
}
